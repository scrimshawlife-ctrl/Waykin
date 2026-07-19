#!/usr/bin/env python3
"""Validate repository-native GitHub Project coordination artifacts."""

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys

ROOT = Path(os.environ.get("WAYKIN_COORDINATION_ROOT", Path(__file__).resolve().parents[1]))

REQUIRED_FILES = [
    "docs/collaboration/GITHUB_PROJECT_COORDINATION.md",
    "docs/collaboration/ACTIVE_WORK.md",
    "AGENTS.md",
    ".github/ISSUE_TEMPLATE/agent-task.yml",
    ".github/ISSUE_TEMPLATE/validation-task.yml",
    ".github/ISSUE_TEMPLATE/defect.yml",
    ".github/pull_request_template.md",
    "scripts/sync_github_project.sh",
]
FIELDS = [
    "Execution Status", "Workstream", "Agent", "Agent Lane", "Priority", "Risk",
    "Dependency", "Base SHA", "Head SHA", "Handoff State", "Evidence",
]
PROHIBITED_AUTHORIZATIONS = [
    "multiplayer is authorized", "a marketplace is authorized", "creator sdk is authorized",
    "backend platform is authorized", "account system is authorized",
    "narrative engine is authorized", "ai gameplay runtime is authorized",
    "additional companions are authorized",
]
PROJECT_URL = "https://github.com/users/scrimshawlife-ctrl/projects/1"
ISSUE_URL = "https://github.com/scrimshawlife-ctrl/Waykin/issues/47"


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def read(relative: str, errors: list[str]) -> str:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"missing file: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def parse_issue_form(relative: str, errors: list[str]) -> dict:
    path = ROOT / relative
    if not path.is_file():
        return {}
    ruby = shutil.which("ruby")
    if ruby is None:
        errors.append("missing command required for issue-form validation: ruby")
        return {}
    result = subprocess.run(
        [
            ruby, "-ryaml", "-rjson", "-e",
            "puts JSON.generate(YAML.safe_load(File.read(ARGV[0]), aliases: false))",
            str(path),
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        errors.append(f"invalid issue-form YAML: {relative}: {result.stderr.strip()}")
        return {}
    try:
        parsed = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        errors.append(f"invalid issue-form parser output: {relative}: {error}")
        return {}
    require(errors, isinstance(parsed, dict), f"issue form is not a mapping: {relative}")
    if not isinstance(parsed, dict):
        return {}
    for key in ("name", "description", "title", "body"):
        require(errors, key in parsed, f"issue form missing top-level key: {relative}: {key}")
    return parsed


def parse_yaml_text(text: str, label: str, errors: list[str]) -> dict:
    ruby = shutil.which("ruby")
    if ruby is None:
        errors.append(f"missing command required for YAML validation: ruby ({label})")
        return {}
    result = subprocess.run(
        [ruby, "-ryaml", "-rjson", "-e", "puts JSON.generate(YAML.safe_load(STDIN.read, aliases: false))"],
        input=text,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        errors.append(f"invalid YAML: {label}: {result.stderr.strip()}")
        return {}
    try:
        parsed = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        errors.append(f"invalid YAML parser output: {label}: {error}")
        return {}
    require(errors, isinstance(parsed, dict), f"YAML is not a mapping: {label}")
    return parsed if isinstance(parsed, dict) else {}


def validate_required_form_entries(
    relative: str, identifiers: list[str], errors: list[str]
) -> None:
    parsed = parse_issue_form(relative, errors)
    body = parsed.get("body", [])
    require(errors, isinstance(body, list), f"issue form body is not a list: {relative}")
    if not isinstance(body, list):
        return
    entry_ids = [entry.get("id") for entry in body if isinstance(entry, dict)]
    duplicate_ids = sorted({identifier for identifier in entry_ids if entry_ids.count(identifier) > 1})
    require(errors, not duplicate_ids, f"{relative} has duplicate ids: {duplicate_ids}")
    entries = {entry.get("id"): entry for entry in body if isinstance(entry, dict)}
    for identifier in identifiers:
        entry = entries.get(identifier)
        require(errors, entry is not None, f"{relative} missing key: {identifier}")
        if entry is None:
            continue
        if entry.get("type") == "checkboxes":
            options = entry.get("attributes", {}).get("options", [])
            required = bool(options) and all(option.get("required") is True for option in options)
        else:
            required = entry.get("validations", {}).get("required") is True
        require(errors, required, f"{relative} field is not required: {identifier}")


def validate_sync_script(errors: list[str]) -> None:
    script = ROOT / "scripts/sync_github_project.sh"
    result = subprocess.run(
        ["bash", "-n", str(script)], text=True, capture_output=True, check=False
    )
    require(errors, result.returncode == 0, f"sync script shell syntax invalid: {result.stderr.strip()}")
    text = script.read_text(encoding="utf-8") if script.is_file() else ""
    for token in (
        "set -Eeuo pipefail", "verify_auth", "resolve_project", "ensure_project_item",
        "set_text_value", "set_select_value", '"--check"', '"--apply"',
    ):
        require(errors, token in text, f"sync script missing required behavior: {token}")
    require(
        errors,
        'REPOSITORY="scrimshawlife-ctrl/Waykin"' in text,
        "sync script repository identity drifted",
    )


def run_sync_fixture(name: str, body: str, errors: list[str]) -> None:
    script = ROOT / "scripts/sync_github_project.sh"
    command = f"source {shlex.quote(str(script))}\nset +e\n{body}"
    result = subprocess.run(
        ["bash", "-c", command], text=True, capture_output=True, check=False
    )
    require(
        errors,
        result.returncode == 0,
        f"sync behavior fixture failed ({name}): {(result.stderr or result.stdout).strip()}",
    )


def validate_sync_behavior(errors: list[str]) -> None:
    run_sync_fixture(
        "repository identity and duplicates",
        r'''
ITEMS_JSON='{"items":[{"id":"foreign","content":{"url":"https://github.com/other/repo/issues/47"}},{"id":"waykin","content":{"url":"https://github.com/scrimshawlife-ctrl/Waykin/issues/47"}}]}'
DRIFT=0
find_project_item Issue 47
[[ "$ITEM_ID" == "waykin" && "$DRIFT" -eq 0 ]] || exit 1
ITEMS_JSON='{"items":[{"id":"one","content":{"url":"https://github.com/scrimshawlife-ctrl/Waykin/issues/47"}},{"id":"two","content":{"url":"https://github.com/scrimshawlife-ctrl/Waykin/issues/47"}}]}'
DRIFT=0
if find_project_item Issue 47; then exit 1; fi
[[ -z "$ITEM_ID" && "$DRIFT" -eq 1 ]] || exit 1
''',
        errors,
    )
    run_sync_fixture(
        "populated values are non-destructive",
        r'''
ITEMS_JSON='{"items":[{"id":"waykin","agent":"Human"}]}'
gh() { return 99; }
MODE=check
DRIFT=0
CHANGES=0
set_text_value waykin Agent Bootstrap
[[ "$DRIFT" -eq 0 && "$CHANGES" -eq 0 ]] || exit 1
MODE=apply
set_text_value waykin Agent Bootstrap
[[ "$DRIFT" -eq 0 && "$CHANGES" -eq 0 ]] || exit 1
''',
        errors,
    )
    run_sync_fixture(
        "post-add inventory drift stops further mutation",
        r'''
MODE=apply
DRIFT=0
CHANGES=0
ITEM_ADD_CALLS=0
PROJECT_MUTATION_CALLS=0
ITEMS_JSON='{"items":[],"totalCount":0}'
gh() {
  if [[ "$1" == "pr" && "$2" == "view" ]]; then
    echo 5a939d470aa2b35e52aa51527dfcc71a48f392a7
  elif [[ "$1" == "project" && "$2" == "item-add" ]]; then
    ITEM_ADD_CALLS=$((ITEM_ADD_CALLS + 1))
    PROJECT_MUTATION_CALLS=$((PROJECT_MUTATION_CALLS + 1))
  elif [[ "$1" == "project" && "$2" == "item-edit" ]]; then
    PROJECT_MUTATION_CALLS=$((PROJECT_MUTATION_CALLS + 1))
  elif [[ "$1" == "project" && "$2" == "item-list" ]]; then
    echo '{"items":[],"totalCount":1001}'
  else
    return 99
  fi
}
sync_initial_items
[[ "$ITEM_ADD_CALLS" -eq 1 && "$PROJECT_MUTATION_CALLS" -eq 1 && "$DRIFT" -gt 0 ]] || exit 1
''',
        errors,
    )


def authorization_is_negated(line: str, phrase: str) -> bool:
    prefix = line[:line.index(phrase)]
    clause = re.split(r"[.;:]", prefix)[-1]
    return re.search(r"\b(?:no|not|never|cannot|can't)\b(?:\W+\w+){0,4}\W*$", clause) is not None


def main() -> int:
    errors: list[str] = []
    texts = {relative: read(relative, errors) for relative in REQUIRED_FILES}
    doc = texts[REQUIRED_FILES[0]]

    for field in FIELDS:
        require(errors, field in doc, f"coordination doc missing field: {field}")
    for token in ("agent_claim:", "frozen_paths_acknowledged", "dependency_state"):
        require(errors, token in doc, f"claim schema missing: {token}")
    for token in ("agent_handoff:", "head_sha:", "test_totals:", "handoff_state:"):
        require(errors, token in doc, f"handoff schema missing: {token}")

    combined = "\n".join(texts.values())
    require(errors, PROJECT_URL in combined,
            "Project #1 URL is missing")
    require(errors, ISSUE_URL in combined,
            "Issue #47 URL is missing")
    require(errors, PROJECT_URL in texts["AGENTS.md"], "AGENTS.md missing Project #1 contract")
    require(errors, ISSUE_URL in texts["AGENTS.md"], "AGENTS.md missing Issue #47 contract")
    require(
        errors,
        "sole live workflow-state authority" in doc,
        "coordination doc no longer makes Project #1 the sole live-state authority",
    )

    required_template_ids = {
        ".github/ISSUE_TEMPLATE/agent-task.yml": [
            "outcome", "project_item", "owner", "workstream", "agent_lane", "branch",
            "base_sha", "dependencies", "intended_paths",
            "frozen_paths", "acceptance_criteria", "required_validation", "non_goals",
            "evidence_boundary", "handoff_state",
        ],
        ".github/ISSUE_TEMPLATE/validation-task.yml": [
            "project_item", "owner", "workstream", "agent_lane",
            "implementation_dependency", "exact_build_or_sha", "environment",
            "protocol_scope", "observed_evidence", "inferred_evidence",
            "not_computable_fields", "pass_fail_exit_criteria", "frozen_paths", "handoff_state",
        ],
        ".github/ISSUE_TEMPLATE/defect.yml": [
            "project_item", "owner", "workstream", "agent_lane",
            "reproducible_behavior", "expected_behavior", "exact_sha", "environment",
            "reproduction_steps", "bounded_affected_surface", "evidence",
            "prohibited_opportunistic_expansion", "frozen_paths", "handoff_state",
        ],
    }
    for path, ids in required_template_ids.items():
        validate_required_form_entries(path, ids, errors)

    pr = texts[".github/pull_request_template.md"]
    metadata_match = re.match(r"\A```yaml\n(.*?)\n```", pr, flags=re.DOTALL)
    require(errors, metadata_match is not None, "pull request template missing leading YAML metadata block")
    metadata = parse_yaml_text(metadata_match.group(1), "pull request metadata", errors) if metadata_match else {}
    required_metadata = [
        "issue", "project_item", "agent", "lane", "base_sha", "head_sha", "workstream",
        "dependency_state", "handoff_state", "evidence",
    ]
    for key in required_metadata:
        require(errors, key in metadata, f"pull request metadata missing key: {key}")
        occurrences = re.findall(
            rf"(?m)^[\"']?{re.escape(key)}[\"']?\s*:", metadata_match.group(1)
        ) if metadata_match else []
        require(errors, len(occurrences) == 1, f"pull request metadata key must occur once: {key}")
    for key in (
        "Exact test total", "OBSERVED", "INFERRED", "Physical-Device Evidence Declaration",
        "Agent assistance used:", "Parent or superseded PR:", "Automatic merge is disabled",
    ):
        require(errors, key in pr, f"pull request template missing: {key}")

    validate_sync_script(errors)
    validate_sync_behavior(errors)

    lowered = combined.lower()
    for phrase in PROHIBITED_AUTHORIZATIONS:
        offending_lines = [
            line for line in lowered.splitlines()
            if phrase in line and not authorization_is_negated(line, phrase)
        ]
        require(errors, not offending_lines, f"prohibited scope authorization: {phrase}")

    if errors:
        print("COLLABORATION_COORDINATION=FAIL")
        for error in errors:
            print(f"- {error}")
        return 1
    print("COLLABORATION_COORDINATION=PASS")
    print(f"FILES_CHECKED={len(REQUIRED_FILES)}")
    print(f"FIELDS_DOCUMENTED={len(FIELDS)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
