---
name: waykin-performance
description: >
  Profile and prioritize Waykin performance issues: startup, SwiftUI invalidation,
  AR entity thrash, concurrency, energy. Use when /waykin-performance, jank,
  memory, startup slow, or energy impact.
metadata:
  short-description: "Waykin performance prioritization"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-performance

Prioritize **product walk-loop** performance. No speculative rewrites.

## 0. Baseline commands

```bash
cd "$(git rev-parse --show-toplevel)"
# Read references/REPO_CONTEXT.md — evidence: OBSERVED vs NOT_COMPUTABLE for device energy
make build && make test
# App build
xcodebuild -scheme Waykin -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/waykin-dd-perf build
```

## 1. Hot paths (inspect first)

| Area | Files / signals |
|------|-----------------|
| Session UI 1 Hz | `ActiveSessionView` TimelineView for live walk |
| Presentation snapshots | `CompanionPresencePresentation`, path snapshots |
| Demo ticks | `DemoSessionController` |
| Audio | `AppAudioCuePlayer` |
| AR entities | replacement counts in `arPresentation` |
| Map | `WalkPathTrace` cap 400 pts, 4 m spacing |
| Persistence | async `WaykinPersistenceActor` — not on render path |

## 2. Analysis playbook

### Startup

- Cold launch: splash (`WaykinSplashBootstrap`) + font registration (`WaykinTypography.ensureRegistered`)
- Avoid heavy work before first frame; log soft failures only

### SwiftUI

- Prefer immutable equatable snapshots over multi-bool view state
- Ensure high-rate GPS does not redraw entire Home
- Check `@Query` scope on Memory screens

### Concurrency

- Swift 6 / MainActor boundaries on App model
- No blocking network (there should be none in MVP)
- Persistence enqueue off UI critical path

### AR

- High `entityReplacementCount` / replant thrash → placement bugs
- Clear session on end

### Memory

- Receipt timeline max 200 entries
- Receipt store max 20 files
- Trace hard cap

## 3. Instruments (optional, device)

If user has Xcode Instruments and a device:

- Time Profiler during Demo walk
- Allocations during AR open/close × 5
- Energy Log during 10 min real walk (human)

Without device: mark energy/thermal `NOT_COMPUTABLE`.

## 4. Output (prioritized)

```markdown
## Waykin performance report
- SHA:
### P0 (user-visible jank / leaks)
1. evidence → fix
### P1 (battery / sustained)
### P2 (polish)
### Explicit non-issues
### Measurement plan for device
```

Prefer smallest fix that reduces invalidation or entity thrash.