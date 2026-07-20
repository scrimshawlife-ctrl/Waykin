# Outdoor / Physical AR Receipt (PARTIAL)

```yaml
document_id: WAYKIN-OUTDOOR-AR-RECEIPT
version: 0.1
status: PARTIAL
evidence_class: PARTIAL
date_utc: 2026-07-20
protocol: OUTDOOR_SESSION_PACKET + Issue_41
git_sha_at_prep: 8295da2dbaf7728c9617fabb3789126be6103e7f
git_sha_main_tip_when_recorded: fc5d6fca6df2eb9765ce69bdfd510e911d11c1db
modes: AR presentation during physical session (operator-reported)
gps_failure: NOT_CLAIMED
```

## Meta

| Field | Value |
| ----- | ----- |
| Date | 2026-07-20 |
| Operator | Product / device operator (reported) |
| Companion | Lira |
| Build | Exact install SHA not re-stated by operator; receipt binds to contemporaneous `main` tip above + prep SHA |
| Device model | (not provided) |
| iOS | (not provided) |
| Context | Outdoor physical AR |

## Evidence classes used

| Class | Meaning in this receipt |
| ----- | ----------------------- |
| **OBSERVED** | Directly reported from physical device session |
| **INFERRED** | Supported conclusion from OBSERVED only |
| **NOT_COMPUTABLE** | Root cause / unmeasured dimensions |

## Pass E — Physical AR (Issue #41)

| ID | Result | Evidence |
| -- | ------ | -------- |
| E1 Outdoor brightness readability | NOT_RUN | Not separately scored |
| E2 States distinguishable without color alone | NOT_RUN | Not separately scored |
| E3 Horizontal outdoor placement | PARTIAL | Companion did place; later disappeared |
| E4 Replace → single Lira | NOT_RUN | |
| E5 Clear removes entities | NOT_RUN | |
| E6 Background/reopen no resurrection | **PARTIAL / FAIL continuity** | Closing and reopening AR restored companion in front after short delay (**OBSERVED** recovery) |
| E7 Celebrate → Idle | NOT_RUN | |
| E8 Thermal / battery | NOT_RUN | |
| E9 Tracking / lighting / surface notes | **NOTED** | See OBSERVED list |

## OBSERVED (device)

1. Companion remained **world-anchored** rather than following the walker.
2. Companion **disappeared** after roughly **10–15 meters** of walk.
3. **Closing and reopening** the AR portion restored the companion in front of the walker after a short delay.
4. **Menu navigation felt awkward.**
5. **Session elapsed clock advanced about two seconds at a time** (not smooth 1s ticks).

## INFERRED

- AR session re-entry can **recover** presentation after loss.
- **Continuous companion presence** and any expectation of **follow-the-walker** behavior are **not established** on device.
- This is a **recoverable AR continuity** problem plus a **separate usability** finding.
- Elapsed HUD was coupled to sparse GPS sample intervals (`distanceFilter = 2` m + sample-driven `elapsedTime`), not wall-clock presentation — **presentation clock defect**, not GPS failure.

## NOT_COMPUTABLE

- Root cause of disappearance: tracking loss vs anchor lifecycle vs rendering vs intended placement semantics (no AR diagnostics attached).
- Whether GPS measurement failed — **not evidenced**; do not treat as GPS defect.
- Full outdoor UI checklist (D1–D8, N*, R*, H*) — not completed this session.
- Device model / iOS / exact binary identity for this walk — not supplied by operator report.

## Design note (architecture, not regression claim)

Current AR placement uses **ground-plane raycast anchors** (`ARPlacementResolver` → `AnchorEntity(raycastResult:)`). Presentation states include a semantic **follow** pose (root offset/yaw on the entity), which is **not** continuous re-anchoring to the walker. Therefore:

> “Did not follow the walker” may be an **expectation / product-design mismatch** relative to world-anchored placement, rather than a pure implementation regression.

Confirm product intent before coding “AR follow”: either document world-plant as intentional, or open a **scoped product issue** for camera-relative / re-plant follow (scope expansion).

## Related issues

| Issue | Scope |
| ----- | ----- |
| #41 | Parent validation — remains open, **PARTIAL** |
| #125 | AR continuity (disappear ~10–15 m; re-entry recovers) |
| #126 | Session menu UX audit |
| #128 | Session elapsed clock ~2s steps on real walk |

## Overall

```yaml
day_pass: not_run
night_pass: not_run
reduced_motion_pass: not_run
pressure_tone_pass: not_run
ar_physical_pass: partial
evidence_class: PARTIAL
gps_failure_claimed: false
blockers: |
  AR continuity defect; menu UX awkward — pause further outdoor AR claims until defects triaged.
follow_ups: |
  1. Bounded AR continuity investigation (diagnostics + anchor lifecycle) — #125
  2. Focused menu flow audit — #126
  3. Session presentation elapsed wall-clock — #128
  4. Product decision: world-plant vs follow semantics
  5. Resume outdoor packet after fixes or explicit design acceptance of world-plant
signed_by: operator-report + agent record
signed_at: 2026-07-20
```
