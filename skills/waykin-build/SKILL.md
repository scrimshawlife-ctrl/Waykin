---
name: waykin-build
description: >
  Build Waykin (SwiftPM Core + xcodegen iOS app) for simulator or device,
  diagnose failures, capture warnings. Use when the user says /waykin-build,
  build Waykin, xcodebuild fail, sim install, or regenerate project.
metadata:
  short-description: "Build Waykin Core + App"
  pack: waykin-skill-pack
  version: "1.0.0"
compatibility: Requires git, swift, xcodegen, xcodebuild; run from Waykin repo
---

# waykin-build

You are executing the **Waykin build** skill. Work only inside the Waykin monorepo.

## 0. Context

1. `REPO="$(git rev-parse --show-toplevel)"` and `cd "$REPO"`.
2. Read `skills/_shared/references/REPO_CONTEXT.md` or this skill's `references/REPO_CONTEXT.md`.
3. Record: `git rev-parse --short HEAD`, branch, `swift --version`, `xcodegen --version`, `xcodebuild -version`.

## 1. Inspect

```bash
git status --short
ls Package.swift project.yml Makefile
xcodebuild -list 2>/dev/null || true
```

Targets that matter: **WaykinCore** (SPM), **WaykinApp** / scheme **Waykin**, **WaykinARLab**, **WaykinDemo**.

Default SIM: `WAYKIN_SIMULATOR_NAME="${WAYKIN_SIMULATOR_NAME:-iPhone 17}"`.

## 2. Generate project when needed

If `project.yml` or sources changed, or `Waykin.xcodeproj` missing/stale:

```bash
make generate
```

Do **not** hand-edit `Waykin.xcodeproj` — edit `project.yml` then regenerate.

## 3. Build matrix (run what the user asked; default = package + app sim)

### A. Package (always first for Core changes)

```bash
make build
make test
```

### B. App simulator (Debug)

```bash
make generate
xcodebuild -scheme Waykin \
  -destination "platform=iOS Simulator,name=${WAYKIN_SIMULATOR_NAME}" \
  -derivedDataPath /tmp/waykin-dd-build \
  -configuration Debug \
  build 2>&1 | tee /tmp/waykin-build-sim.log
```

### C. Device (only if user has a connected iPhone / explicit request)

```bash
xcrun xctrace list devices 2>/dev/null | head -40
# Pick a physical device id, then:
xcodebuild -scheme Waykin \
  -destination 'platform=iOS,id=<DEVICE_ID>' \
  -derivedDataPath /tmp/waykin-dd-device \
  -configuration Debug \
  build 2>&1 | tee /tmp/waykin-build-device.log
```

If signing fails: report as `NOT_COMPUTABLE` without inventing profiles. Do not force-sign.

### D. AR Lab (only if AR Lab work)

```bash
xcodebuild -scheme WaykinARLab \
  -destination "platform=iOS Simulator,name=${WAYKIN_SIMULATOR_NAME}" \
  -derivedDataPath /tmp/waykin-dd-arlab \
  build
```

## 4. Capture warnings / failures

From log, extract:

- `error:` and first 20 lines of context
- `warning:` counts (Swift 6 concurrency, deprecations)
- Isolation failures → re-run `make check-core-isolation`

Common Waykin failures and fixes:

| Symptom | Fix direction |
|---------|----------------|
| WaykinCore imports SwiftUI/ARKit | Move to App; respect baseline |
| Missing Waykin.xcodeproj | `make generate` |
| Font missing | `App/Resources/Fonts/WaykinDisplay-Regular.ttf` + UIAppFonts |
| USDZ integrity | `make check-lira-usdz` |
| SwiftData migration | Persistence factory + WP-DB docs |

## 5. Output format (deterministic)

```markdown
## Waykin build report
- SHA:
- Branch:
- Targets attempted:
- Package build: PASS|FAIL
- Package tests: PASS|FAIL (N tests)
- App sim build: PASS|FAIL|SKIPPED
- Device build: PASS|FAIL|SKIPPED|NOT_COMPUTABLE
- Warnings (top):
- Errors (with file:line if available):
- Suggested next command:
```

Never claim device install success without OBSERVED xcodebuild success.