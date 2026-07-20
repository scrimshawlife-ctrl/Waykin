---
name: waykin-ar-debug
description: >
  Debug Waykin product AR (RealityKit/ARKit adapters): placement, continuity,
  entity lifecycle, LOD, freeze rules. Use when /waykin-ar-debug, AR tracking
  loss, duplicate Lira, plant fail, or CanonicalAR issues.
metadata:
  short-description: "Waykin AR / RealityKit debug"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-ar-debug

Repository-specific AR debug. **Product path** ≠ AR Lab.

## 0. Freeze & law

- Read `docs/design/AR_MVP_FREEZE.md` — maintenance-only unless issue authorizes expansion.
- Core never imports ARKit/RealityKit.
- Gameplay truth stays in Core; AR is presentation of `ARWorldCommand` stream.
- Outdoor quality: #41 only.

## 1. Map the product AR stack

Primary files:

| File | Role |
|------|------|
| `App/AR/CanonicalARSessionView.swift` | Session UI + diagnostics publish |
| `App/AR/ARSessionCoordinator.swift` | Session lifecycle |
| `App/AR/ARWorldCommandRenderer.swift` | Command → entities |
| `App/AR/AREntityRegistry.swift` | One-entity discipline |
| `App/AR/ARPlacementResolver.swift` | Placement |
| `App/AR/ARContinuityHint.swift` | Tracking-loss chrome |
| `App/AR/CanonicalARWorldCommandMapper.swift` | Core → AR commands |
| `App/AR/Companion/*` | Lira mesh / skeletal / stills |
| `App/Diagnostics/WaykinLog.swift` | category `ar` |

Lab target: `ARLab/` + scheme `WaykinARLab` — engineering only.

## 2. Debug workflow

```bash
cd "$(git rev-parse --show-toplevel)"
make check-lira-usdz
rg -n 'ARWorldCommand|clearSession|replant|entity' App/AR Sources/WaykinCore --glob '*.swift' | head -60
```

### Live session

1. Active Session → open AR fullScreenCover (not dismissible swipe).
2. Operator strip: AR LOD + continuity when opened.
3. End walk → Settings share receipt → inspect `summary.arPresentation` (schema 5):

   - `arSessionOpened`, `finalLODDescription`, `meshEvidenceClass`
   - `finalContinuityNote`, `finalCapabilityState`
   - `placementDeferredCount`, `continuityReplantCount`, `entityReplacementCount`
   - `companionPlaced`

4. Console: `subsystem:life.scrimshaw.waykin category:ar`

### Code paths for common bugs

| Symptom | Investigate |
|---------|-------------|
| Duplicate Lira | `AREntityRegistry` — one entity; clearSession |
| Stuck after tracking loss | `ARContinuityHint`, replant counts, capability state |
| Blank AR | USDZ load `Lira_AR_Base.usdz`, integrity script, asset catalog |
| Pause/End missing | AR chrome must mirror session controls |
| Reduce Motion still animating | skeletal player / still path |
| Lab ≠ product | do not use Lab results as product PASS |

## 3. Memory / perf (AR)

- Ensure clearSession on end/fail (also map clear is separate App concern).
- Watch entity replacement counts in receipt — high rates = thrash.
- Prefer existing diagnostics over new os_signpost unless issue asks.

## 4. Tests

```bash
# Package
swift test --filter CompanionPresentationMatrix
# App (examples)
xcodebuild test -scheme Waykin -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WaykinTests/CanonicalARRuntimeIntegrationTests
```

Sim AR ≠ outdoor tracking.

## 5. Report

```markdown
## Waykin AR debug
- SHA:
- Path: product | lab
- Hypothesis:
- OBSERVED (code/logs/receipt):
- INFERRED:
- NOT_COMPUTABLE (needs device/outdoor):
- Fix plan (smallest patch):
- Freeze compliance: OK | needs issue
```