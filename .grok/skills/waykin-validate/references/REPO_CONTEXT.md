# Waykin repository context (skill pack shared)

Read this once at skill start. Prefer absolute repo paths from `git rev-parse --show-toplevel`.

## Product

- Audio-first **walking** companion app (Lira). Solo MVP.
- Binding scope: `docs/SOLO_MVP_SCOPE.md`, `WAYKIN_SPEC.md`, `ARCHITECTURE.md`, `AGENTS.md`, `docs/governance/DOCUMENT_AUTHORITY.md`.
- One activity: walking. Not run/cycle expansion without scope promotion.

## Layout

| Path | Role |
|------|------|
| `Sources/WaykinCore/` | Domain truth (movement, events, companion, path, persistence, field receipts) |
| `App/` | SwiftUI, MapKit, ARKit/RealityKit adapters, audio player, HealthKit adapter |
| `App/AR/` | Product AR (CanonicalARSessionView, entity registry, continuity) |
| `ARLab/` | Engineering AR lab target (not product claims) |
| `AppTests/`, `WaykinUITests/`, `Tests/WaykinCoreTests/` | Tests |
| `scripts/` | Canonical tooling (do not reinvent) |
| `docs/` | Design, outdoor, field protocols, governance |
| `project.yml` | xcodegen source of truth for Xcode project |
| `Package.swift` | SwiftPM WaykinCore + WaykinDemo |
| `Makefile` | `generate` `build` `test` `validate` `validate-simulator` `check-core-isolation` `check-lira-usdz` |

## Architecture law

- **WaykinCore** must stay free of ARKit, RealityKit, SwiftUI, MapKit, audio filenames. Isolation: `scripts/check_core_framework_isolation.sh` + `scripts/core_isolation_baseline.txt`.
- Presentation consumes semantic state; never invents Bond/path/event truth.
- Field receipts: privacy-safe (no coordinates, no raw health IDs). Schema 5: AR + map + persistence operator snapshots.

## Build targets

| Scheme / target | Purpose |
|-----------------|---------|
| `Waykin` | App + unit + UI tests (xcodegen) |
| `WaykinApp` | Product iOS app (`com.waykin.WaykinApp`) |
| `WaykinARLab` | AR engineering lab |
| `WaykinCore` | SPM library |
| `WaykinDemo` | Terminal demo |

Simulator default: `iPhone 17` (`WAYKIN_SIMULATOR_NAME`).

## Canonical commands (use these)

```bash
cd "$(git rev-parse --show-toplevel)"
make generate          # xcodegen
make build             # swift build
make test              # swift test
make validate          # scripts/validate.sh (isolation + usdz + collab + package + native)
make validate-simulator
make check-core-isolation
make check-lira-usdz
./scripts/capture_sim_screenshots.sh
WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh
./scripts/sim_walk_preflight.sh
./scripts/outdoor_qa_prep.sh
```

Native app tests:

```bash
xcodegen generate
xcodebuild test -scheme Waykin \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/waykin-dd
```

## Evidence language (mandatory)

- `OBSERVED` — directly verified
- `INFERRED` — derived, labeled
- `NOT_COMPUTABLE` — missing environment/evidence

Never claim outdoor GPS, outdoor AR quality, battery, thermal, physical audio, or device interruption as PASS from sim/CI alone. Outdoor: issue **#41** + `docs/design/OUTDOOR_QA_*`.

## UI authority

| Need | Doc |
|------|-----|
| Product surfaces | `docs/design/WAYKIN_UIUX_SPEC.md` |
| Tokens / candidate | `docs/design/UI_CANDIDATE_V02_POINTER.md` |
| Practice / DoD | `docs/design/UI_ENGINEERING_PRACTICE.md` |
| PR UI receipt | `docs/design/UI_CHANGE_VALIDATION_RECEIPT.md` |

## Debug operator stack

- D1–D4: AR receipt schema 4, Settings share, operator strip, `WaykinLog`
- D5–D7: map snapshot, persistence operator, font soft log (schema 5)
- Docs: `docs/design/DEBUG_OPERATOR_CONTINUATION.md`
- Console: subsystem `life.scrimshaw.waykin`
- Flag: `-WAYKIN_OPERATOR_DEBUG` (Release); DEBUG builds enable strip

## Git / PR conventions

- Issue-based work preferred
- Smallest coherent patch
- Solo merge pattern uses ruleset review_count temporarily only when authorized
- `git diff --check` before claiming done

## Frozen / parked

- AR MVP freeze: maintenance-only unless issue (`docs/design/AR_MVP_FREEZE.md`)
- Outdoor #41 parked until daylight device walk
