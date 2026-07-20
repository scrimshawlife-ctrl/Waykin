---
name: waykin-healthkit
description: >
  Review Waykin optional HealthKit enrichment: permissions, steps/distance bands,
  privacy, Demo independence. Use when /waykin-healthkit, HealthKit, steps, or
  walking distance enrichment.
metadata:
  short-description: "Waykin HealthKit review"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-healthkit

HealthKit is **optional enrichment only** — never authorizes events or Bond.

## 0. Authority

- `docs/design/HEALTHKIT.md`
- `KNOWN_LIMITATIONS.md` (HealthKit section)
- Usage string in `project.yml` / `App/Info.plist`
- Entitlements: `App/Waykin.entitlements`

## 1. Code map

| File | Role |
|------|------|
| `App/Health/HealthMetricsProviding.swift` | Protocol |
| `App/Health/HealthKitMetricsProvider.swift` | Live adapter |
| Core activity types | cadence bands only in receipts — no sample UUIDs |

```bash
cd "$(git rev-parse --show-toplevel)"
rg -n 'HealthKit|HKHealthStore|ActivityEnrichment|stepCadence' \
  App Sources/WaykinCore --glob '*.swift'
```

## 2. Product rules (must hold)

1. **Demo Mode never requires Health** and never blocks on HK failure.
2. Real walk only: start/resume + bounded periodic refresh while active.
3. Authorization request completion ≠ granted access.
4. Empty data / denied / query failure must be distinguishable.
5. Soft-fill energy presentation when steps unavailable — no event selection.
6. **No HealthKit writes** (no workouts out).
7. Receipts may store `activityStepCadenceBand` + `activityAuthorizationDenied` only.

## 3. Review checklist

- [ ] Info.plist / xcodegen usage description present and accurate
- [ ] Entitlement for share types matches code queries
- [ ] Background delivery: only if implemented; otherwise document as not present
- [ ] Watch-origin samples: not claimed as Waykin Watch app
- [ ] Battery impact of refresh: `NOT_COMPUTABLE` without device
- [ ] Privacy: no raw samples, no identifiers in logs/receipts

## 4. Device protocol (when testing)

Human on iPhone:

1. Deny HK → walk still works; enrichment denied flag  
2. Allow empty → empty availability path  
3. Allow with data → band updates during real walk  
4. Kill/reopen mid-walk per product pause rules  

## 5. Report

```markdown
## Waykin HealthKit review
- SHA:
- Demo independence: PASS/FAIL
- Authorization states handled:
- Receipt privacy: PASS/FAIL
- Scope creep (workouts/write/watch app): none|found
- Device evidence: OBSERVED|NOT_COMPUTABLE
- Recommendations:
```