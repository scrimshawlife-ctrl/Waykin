# Versioning and Release Procedure

Waykin follows [Semantic Versioning 2.0.0](https://semver.org/).

This is a **proprietary** iOS product owned by **Zero State / Zero State LLC**. Marketing version and build numbers must stay consistent across git, Info.plist, XcodeGen, and App Store Connect uploads.

## Single source of truth

| Artifact | Purpose |
|---|---|
| `VERSION` | `MAJOR.MINOR.PATCH` marketing version |
| `BUILD` | Monotonic integer (`CFBundleVersion`) |
| `App/Info.plist` | `CFBundleShortVersionString`, `CFBundleVersion` |
| `project.yml` | `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, Info.plist properties |
| `CHANGELOG.md` | Human-readable history |
| Git tag | `vMAJOR.MINOR.PATCH` on the release commit |

**Parity rule** (enforced by `python3 Tools/version.py check`):

```text
VERSION  ==  App/Info.plist CFBundleShortVersionString
         ==  project.yml MARKETING_VERSION / CFBundleShortVersionString
BUILD    ==  App/Info.plist CFBundleVersion
         ==  project.yml CURRENT_PROJECT_VERSION / CFBundleVersion
```

Prefer the helper over hand-editing version fields.

## What the numbers mean

| Bump | When |
|---|---|
| **MAJOR** | Breaking player/save contract, forced migration, or landmark product line change. **`1.0.0` = first public App Store / broad soft launch.** |
| **MINOR** | New feature or content set with backward-compatible saves |
| **PATCH** | Bug fix, polish, docs-only product notes, balance tuning without new systems |

### Current pre-1.0 track

| Series | Intent |
|---|---|
| `0.9.x` | Internal TestFlight / device evidence cuts |
| `1.0.0` | Soft launch / App Store candidate after [SHIP_CHECKLIST.md](SHIP_CHECKLIST.md) |

### Build number

- **Must increase** for every TestFlight / App Store upload, even if marketing version is unchanged.
- Never reuse a build number for a different binary on the same bundle id.

## Commands

```bash
python3 Tools/version.py show
python3 Tools/version.py check
python3 Tools/version.py bump patch   # or minor | major
python3 Tools/version.py set 1.0.0 --build 10
python3 Tools/version.py build        # +1
python3 Tools/version.py sync         # push VERSION/BUILD into plist + project.yml
```

After changing source/resource files, still run `make generate` / `xcodegen generate` as usual.

## Release checklist (summary)

1. Decide bump type.
2. Bump with `Tools/version.py`.
3. Move `[Unreleased]` notes in `CHANGELOG.md` into a dated `## [X.Y.Z]` section.
4. Run `make validate` (and simulator / device protocols as needed).
5. `python3 Tools/version.py check`
6. Complete [SHIP_CHECKLIST.md](SHIP_CHECKLIST.md) / [design/TESTFLIGHT_RC_CHECKLIST.md](design/TESTFLIGHT_RC_CHECKLIST.md).
7. Tag `vX.Y.Z`, upload archive to App Store Connect.
8. Update [ROADMAP.md](../ROADMAP.md) if a milestone gate moved.

## Related

- [CHANGELOG.md](../CHANGELOG.md)
- [SHIP_CHECKLIST.md](SHIP_CHECKLIST.md)
- [waykin-release skill](../skills/waykin-release/SKILL.md)
