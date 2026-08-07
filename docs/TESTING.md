# Testing

How Waykin is verified before merge and before ship.  
Product evidence language (`OBSERVED` / `INFERRED` / `NOT_COMPUTABLE`) lives in [WAYKIN_SPEC.md](../WAYKIN_SPEC.md).

## Test layers

| Layer | Location / command | Simulator | Purpose |
|---|---|---|---|
| WaykinCore unit | `make test` (`Tests/WaykinCoreTests`) | No | Rules, events, companion, persistence math |
| Framework isolation | `make check-core-isolation` | No | Core must not grow forbidden platform imports |
| Canonical harness | `make validate` | No* | Generation + package + native app build + guards |
| Simulator UI | `make validate-simulator` | Yes | App shell / UITests |
| Physical outdoor | [PHYSICAL_DEVICE_WALK_VALIDATION.md](PHYSICAL_DEVICE_WALK_VALIDATION.md) | Device | GPS, audio, AR outdoor, interruptions |
| Version parity | `python3 Tools/version.py check` | No | VERSION/BUILD ↔ plist ↔ project.yml |

\* `make validate` builds the native iOS app; it does not require a booted simulator for the default path.

## Local commands

```bash
make build
make test
make validate
python3 Tools/version.py check
git diff --check
```

Simulator:

```bash
make validate-simulator
# or
WAYKIN_SIMULATOR_NAME="iPhone 17 Pro" make validate-simulator
```

## What must stay true

1. **`WaykinCore` isolation** — no new ARKit/RealityKit/SwiftUI/MapKit/AVFoundation/CoreLocation/UIKit imports without explicit architecture review and baseline update.
2. **Determinism** — Demo Mode and seeded events remain reproducible in package tests.
3. **No false outdoor claims** — GPS, outdoor AR quality, battery, thermal, and interruption recovery require **device receipts**, not CI green alone.
4. **Version parity** — do not ship a binary whose Info.plist disagrees with `VERSION`/`BUILD`.

## CI map

Hosted workflows (see README badges):

| Workflow | Signal |
|---|---|
| Canonical validation (`validate.yml`) | `make validate` class gates |
| Waykin CI (`waykin-ci.yml`) | Swift package + native iOS jobs |

Treat **main** badge status as the public truth for the default branch.

## Smoke matrix (pre-ship)

| Check | Target | Pass |
|---|---|---|
| Demo walk end-to-end | Simulator | Completes; summary + memory write |
| Real walk permission deny | Device | Session remains safe / completable without AR or location as designed |
| AR unavailable / denied | Device | Supporting channels still complete a walk |
| Audio background / pocket | Device | Cues continue under background mode policy |
| HealthKit deny | Device | Demo and walk still work; enrichment soft-fails |
| Settings → Legal | Any | Notices open; no crash |

## Definition of done (PR)

- [ ] Issue-scoped; non-goals respected
- [ ] `make validate` (or documented equivalent CI green)
- [ ] Tests added/updated when Core behavior changes
- [ ] Docs updated when contracts change
- [ ] Device-evidence status stated when outdoor/AR/audio/HK claimed
- [ ] `python3 Tools/version.py check` if version files touched

## Related

- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [FIELD_TEST_PROTOCOL.md](FIELD_TEST_PROTOCOL.md)
- [SHIP_CHECKLIST.md](SHIP_CHECKLIST.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
