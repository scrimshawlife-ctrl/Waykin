---
name: waykin-release
description: >
  Prepare Waykin release candidate / TestFlight readiness: version, entitlements,
  privacy, assets, validation, release notes. Use when /waykin-release, TestFlight,
  App Store, or ship RC.
metadata:
  short-description: "Waykin release candidate checklist"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-release

Generate a **complete RC checklist** and run what can be automated. Do not claim App Store submission without human Apple Connect steps.

## 0. Preconditions

```bash
cd "$(git rev-parse --show-toplevel)"
git checkout main && git pull
git rev-parse HEAD
make validate
```

Main must be green. Open issues: only known park (#41 outdoor) is allowed as residual limitation, not as silent ship quality.

## 1. Version & identity

Inspect / report:

- `project.yml` / generated Info.plist marketing version & build
- Bundle id `com.waykin.WaykinApp`
- Display name Waykin
- App icon asset catalog
- `App/Waykin.entitlements` (HealthKit share if used)

If versions missing from yml, note xcodegen GENERATE_INFOPLIST defaults and recommend explicit version fields before store upload.

## 2. Automated verification

```bash
make validate
make validate-simulator   # if UI shipping
make check-lira-usdz
./scripts/capture_sim_screenshots.sh   # optional evidence
```

## 3. Legal / privacy

Read and confirm present:

- `docs/legal/PRIVACY.md`, `TERMS.md`, `SAFETY.md`, `NOTICES.md`
- `LICENSE` Apache-2.0
- Usage descriptions: Location When-In-Use, Camera, Health share
- No background location entitlement unless product explicitly adds it (MVP: foreground walk only)

## 4. Product readiness matrix

| Area | Gate |
|------|------|
| Demo walk | Completes, memory/receipt |
| Real walk | Permission honesty, pause on background |
| AR | Freeze compliance; outdoor still #41 residual |
| Persistence | WP-DB recovery; degraded visible |
| Audio | Assets present; silence fails soft |
| Accessibility | Smoke tests; device VO optional residual |
| Field receipts | Schema 5; share path works |

## 5. Release notes template

```markdown
## Waykin <version> (<build>)
### User-facing
-
### Engineering / known limitations
- Outdoor AR/GPS quality: see issue #41 (NOT_COMPUTABLE until daylight COH)
-
### SHA
<main tip>
```

## 6. Tagging / archive (commands only when user confirms)

```bash
git tag -a vX.Y.Z -m "Waykin vX.Y.Z"
# Archive via Xcode Organizer or:
xcodebuild -scheme Waykin -destination 'generic/platform=iOS' \
  -configuration Release archive -archivePath /tmp/Waykin.xcarchive
```

Signing/TestFlight upload: human Apple ID — mark `NOT_COMPUTABLE` for agent-only sessions.

## 7. Final report

```markdown
## Waykin RC report
- Version/Build:
- SHA:
- make validate:
- Residual known limitations:
- Legal docs:
- Entitlements:
- Store blockers:
- TestFlight readiness: READY | BLOCKED (reasons)
- Human actions remaining:
```