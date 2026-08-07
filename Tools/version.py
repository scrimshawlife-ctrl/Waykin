#!/usr/bin/env python3
"""Version helper for Waykin.

Single source of truth:
- VERSION (x.y.z marketing version)
- BUILD   (integer, CFBundleVersion)
Synced into:
- App/Info.plist (CFBundleShortVersionString, CFBundleVersion)
- project.yml (MARKETING_VERSION, CURRENT_PROJECT_VERSION, CFBundle* strings)

Commands:
  python3 Tools/version.py show
  python3 Tools/version.py check
  python3 Tools/version.py bump [major|minor|patch]
  python3 Tools/version.py build [<n>]
  python3 Tools/version.py set <x.y.z> [--build <n>]
  python3 Tools/version.py sync
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Tuple

ROOT = Path(__file__).resolve().parent.parent
VERSION_FILE = ROOT / "VERSION"
BUILD_FILE = ROOT / "BUILD"
INFOPLIST = ROOT / "App" / "Info.plist"
PROJECT_YML = ROOT / "project.yml"

SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
BUILD_RE = re.compile(r"^(0|[1-9]\d*)$")


def _usage() -> None:
    print(__doc__.strip())


def _read_text(file: Path) -> str:
    if not file.exists():
        raise SystemExit(f"Missing required file: {file}")
    return file.read_text(encoding="utf-8").strip()


def _write_text(file: Path, value: str) -> None:
    file.write_text(value.rstrip() + "\n", encoding="utf-8")


def _parse_version(raw: str) -> Tuple[int, int, int]:
    m = SEMVER_RE.fullmatch(raw.strip())
    if not m:
        raise ValueError(f"Invalid semantic version: {raw!r}")
    return int(m.group(1)), int(m.group(2)), int(m.group(3))


def _validate_version(v: Tuple[int, int, int]) -> str:
    return f"{v[0]}.{v[1]}.{v[2]}"


def _load_version() -> Tuple[int, int, int]:
    return _parse_version(_read_text(VERSION_FILE))


def _load_build() -> int:
    raw = _read_text(BUILD_FILE)
    if not BUILD_RE.fullmatch(raw):
        raise ValueError(f"Invalid build number in {BUILD_FILE}: {raw!r}")
    return int(raw)


def _write_version_metadata(version: Tuple[int, int, int], build: int) -> None:
    _write_text(VERSION_FILE, _validate_version(version))
    _write_text(BUILD_FILE, str(build))


def _replace_plist_value(plist: str, key: str, value: str) -> str:
    marker = f"<key>{key}</key>"
    key_pos = plist.find(marker)
    if key_pos == -1:
        raise RuntimeError(f"Could not find key {key} in Info.plist")
    string_open = plist.find("<string>", key_pos)
    if string_open == -1:
        raise RuntimeError(f"Could not find <string> for key {key} in Info.plist")
    value_start = string_open + len("<string>")
    value_end = plist.find("</string>", value_start)
    if value_end == -1:
        raise RuntimeError(f"Could not find </string> for key {key} in Info.plist")
    return plist[:value_start] + value + plist[value_end:]


def _sync_plist(version: str, build: int) -> bool:
    plist = INFOPLIST.read_text(encoding="utf-8")
    updated = _replace_plist_value(plist, "CFBundleShortVersionString", version)
    updated = _replace_plist_value(updated, "CFBundleVersion", str(build))
    changed = updated != plist
    if changed:
        INFOPLIST.write_text(updated, encoding="utf-8")
    return changed


def _sync_project_yml(version: str, build: int) -> bool:
    text = PROJECT_YML.read_text(encoding="utf-8")
    original = text
    text = re.sub(
        r'(MARKETING_VERSION:\s*")[^"]*(")',
        rf"\g<1>{version}\2",
        text,
        count=1,
    )
    text = re.sub(
        r'(CURRENT_PROJECT_VERSION:\s*")[^"]*(")',
        rf"\g<1>{build}\2",
        text,
        count=1,
    )
    text = re.sub(
        r'(CFBundleShortVersionString:\s*")[^"]*(")',
        rf"\g<1>{version}\2",
        text,
        count=1,
    )
    text = re.sub(
        r'(CFBundleVersion:\s*")[^"]*(")',
        rf"\g<1>{build}\2",
        text,
        count=1,
    )
    changed = text != original
    if changed:
        PROJECT_YML.write_text(text, encoding="utf-8")
    return changed


def _sync_all(version: str, build: int) -> list[str]:
    touched: list[str] = []
    if _sync_plist(version, build):
        touched.append("App/Info.plist")
    if _sync_project_yml(version, build):
        touched.append("project.yml")
    return touched


def _plist_values() -> tuple[str, str]:
    plist = INFOPLIST.read_text(encoding="utf-8")
    ver = re.search(
        r"<key>CFBundleShortVersionString</key>\s*\n\s*<string>([^<]+)</string>",
        plist,
    )
    bld = re.search(
        r"<key>CFBundleVersion</key>\s*\n\s*<string>([^<]+)</string>",
        plist,
    )
    if not ver or not bld:
        raise SystemExit("Could not parse App/Info.plist version fields")
    return ver.group(1), bld.group(1)


def _yml_values() -> tuple[str | None, str | None, str | None, str | None]:
    text = PROJECT_YML.read_text(encoding="utf-8")
    def g(pat: str) -> str | None:
        m = re.search(pat, text)
        return m.group(1) if m else None
    return (
        g(r'MARKETING_VERSION:\s*"([^"]+)"'),
        g(r'CURRENT_PROJECT_VERSION:\s*"([^"]+)"'),
        g(r'CFBundleShortVersionString:\s*"([^"]+)"'),
        g(r'CFBundleVersion:\s*"([^"]+)"'),
    )


def _check_parity(version: Tuple[int, int, int], build: int) -> None:
    expected_version = _validate_version(version)
    expected_build = str(build)
    pv, pb = _plist_values()
    if pv != expected_version:
        raise SystemExit(
            f"Version parity failed: VERSION {expected_version} but App/Info.plist has {pv}"
        )
    if pb != expected_build:
        raise SystemExit(
            f"Build parity failed: BUILD {expected_build} but App/Info.plist has {pb}"
        )
    mv, cpv, sv, bv = _yml_values()
    mismatches = []
    if mv and mv != expected_version:
        mismatches.append(f"project.yml MARKETING_VERSION={mv}")
    if cpv and cpv != expected_build:
        mismatches.append(f"project.yml CURRENT_PROJECT_VERSION={cpv}")
    if sv and sv != expected_version:
        mismatches.append(f"project.yml CFBundleShortVersionString={sv}")
    if bv and bv != expected_build:
        mismatches.append(f"project.yml CFBundleVersion={bv}")
    if mismatches:
        raise SystemExit(
            "project.yml parity failed vs VERSION/BUILD:\n  - " + "\n  - ".join(mismatches)
        )


def cmd_show() -> None:
    print(f"VERSION={_validate_version(_load_version())}")
    print(f"BUILD={_load_build()}")


def cmd_bump(part: str) -> None:
    if part not in {"major", "minor", "patch"}:
        raise SystemExit("bump requires major|minor|patch")
    version = _load_version()
    if part == "major":
        version = (version[0] + 1, 0, 0)
    elif part == "minor":
        version = (version[0], version[1] + 1, 0)
    else:
        version = (version[0], version[1], version[2] + 1)
    build = 1
    _write_version_metadata(version, build)
    touched = _sync_all(_validate_version(version), build)
    print(f"Bumped to {_validate_version(version)} build {build}")
    if touched:
        print("Synced: " + ", ".join(touched))


def cmd_build(value: str | None) -> None:
    build = _load_build()
    new_build = build + 1 if value is None else int(value)
    version = _validate_version(_load_version())
    _write_text(BUILD_FILE, str(new_build))
    touched = _sync_all(version, new_build)
    print(f"BUILD={new_build}")
    if touched:
        print("Synced: " + ", ".join(touched))


def cmd_set(version_raw: str, build_raw: str | None = None) -> None:
    new_version = _parse_version(version_raw)
    new_build = int(build_raw) if build_raw is not None else _load_build()
    _write_version_metadata(new_version, new_build)
    touched = _sync_all(_validate_version(new_version), new_build)
    print(f"Set {_validate_version(new_version)} build {new_build}")
    if touched:
        print("Synced: " + ", ".join(touched))


def cmd_check() -> None:
    _check_parity(_load_version(), _load_build())
    print("Version parity check passed")


def cmd_sync() -> None:
    version = _validate_version(_load_version())
    build = _load_build()
    touched = _sync_all(version, build)
    print("Synced: " + (", ".join(touched) if touched else "already in sync"))


def main(argv: list[str]) -> None:
    if len(argv) < 2:
        _usage()
        raise SystemExit(1)
    cmd = argv[1]
    args = argv[2:]
    if cmd == "show":
        cmd_show()
    elif cmd == "check":
        cmd_check()
    elif cmd == "bump":
        if len(args) != 1:
            raise SystemExit("bump requires exactly one argument: major|minor|patch")
        cmd_bump(args[0])
    elif cmd == "build":
        if len(args) > 1:
            raise SystemExit("build takes zero or one argument")
        cmd_build(args[0] if args else None)
    elif cmd == "set":
        if len(args) not in {1, 3}:
            raise SystemExit("set takes version and optional --build <n>")
        build = None
        if len(args) == 3:
            if args[1] != "--build":
                raise SystemExit("Expected: set <version> --build <n>")
            build = args[2]
            if not BUILD_RE.fullmatch(build):
                raise SystemExit("Build value must be a positive integer")
        cmd_set(args[0], build)
    elif cmd == "sync":
        cmd_sync()
    else:
        raise SystemExit(f"Unknown command: {cmd}")


if __name__ == "__main__":
    try:
        main(sys.argv)
    except ValueError as exc:
        raise SystemExit(str(exc))
