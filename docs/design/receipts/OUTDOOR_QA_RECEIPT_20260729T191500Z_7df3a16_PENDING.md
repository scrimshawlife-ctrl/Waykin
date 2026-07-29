# Outdoor QA receipt (PENDING — daylight #41)

```yaml
document_id: WAYKIN-OUTDOOR-QA-RECEIPT
date_utc: 2026-07-29T19:15:00Z
git_sha: 7df3a169ede507ce54469330318f66c4603f8c3d
git_short: 7df3a16
freeze_docs_pr: 249
device_model:
ios:
operator:
evidence_class: NOT_COMPUTABLE
status: PENDING_HUMAN_DEVICE
companion_runtime: MESHY_EMBER_FOX_WALK_V1
visual_reference: docs/design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md
protocol: docs/design/OUTDOOR_SESSION_PACKET.md
depends_on: indoor_smoke_preferred_first
note: Fill only on daylight physical walk of freeze tip / 7df3a16 lineage. Never invent PASS from sim or indoor alone.
```

## Pre-walk gates

| Gate | Required |
| ---- | -------- |
| Freeze docs #249 merged (preferred) | yes |
| Install exact tip SHA | recorded below |
| Indoor Ember Fox smoke | preferred PASS/PARTIAL first |
| Laptop baseline | `POST_EMBER_FOX_BASELINE_*` PASS |

## Identity at walk

| Field | Value |
| ----- | ----- |
| Full SHA | |
| Marketing / build | |
| Weather / light | daylight |
| Duration | |

## Mesh / runtime (report separately from world events)

| Check | Result | Notes |
| ----- | ------ | ----- |
| Authored fox visible (vs spheres) | | match Prabu ref? |
| Ground stability / plant | | |
| Replant / tracking loss | | |
| Continuity while walking | | |
| Follow distance | | |
| Animation start/stop | | |
| Sunlight readability | | |
| Occlusion / depth artifacts | | |

## World events / pressure (#248)

| Check | Result | Notes |
| ----- | ------ | ----- |
| Event vocabulary variety | | |
| Event frequency (intentionally sparse OK) | | do not retune cadence from sparse alone |
| Pursuit-related reachability | | |

## Session / system

| Check | Result | Notes |
| ----- | ------ | ----- |
| Audio audibility | | |
| Interruption recovery | | |
| Battery / thermal | | |
| Overall COH | PASS / PARTIAL / FAIL / NOT_COMPUTABLE | |

## Explicit non-claims until filled OBSERVED

- Outdoor quality from indoor smoke or simulator
- TF archive readiness without #247 tip-bound mesh confirm

## Operator

1. Install freeze tip on physical iPhone.
2. Follow outdoor packet + issue #41.
3. Use only OBSERVED rows; open narrow defects for FAIL.
