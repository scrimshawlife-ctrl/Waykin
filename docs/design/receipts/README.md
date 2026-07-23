# Design / Validation Receipts

Evidence files only. Do not invent OBSERVED results.

## Outdoor / physical

| File | Status |
| ---- | ------ |
| `OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md` | **PARTIAL** operator AR notes (pre-mitigation continuity/audio). Not GPS FAIL. Not full COH PASS. |
| `OUTDOOR_QA_RECEIPT_20260720T021922Z_8295da2_PENDING.md` | Scaffold / pending human fill |
| Template | `../OUTDOOR_QA_RECEIPT_TEMPLATE.md` (includes Pass COH) |

Outdoor QA copies should use:

```text
OUTDOOR_QA_RECEIPT_YYYYMMDD_<device-model>.md
```

## Indoor AR hybrid smoke

| File | Status |
| ---- | ------ |
| `INDOOR_AR_HYBRID_SMOKE_20260723T011800Z_8beec34_PENDING.md` | **PENDING** human fill on main tip `8beec34` (or re-bind after #217) |
| Protocol | `../INDOOR_AR_HYBRID_SMOKE.md` |

## Simulator preflight / engineering

Multiple `SIM_PREFLIGHT_*` and sim checklist receipts live in this directory. They are **SIMULATOR** evidence only.

## Field-test JSON samples (agent format)

See [`samples/`](samples/) — real sim export (schema 4) + synthetic schema **5** example with `arPresentation` / `clips=N`. **Not** device or outdoor evidence.

## Rules

- `OBSERVED` only from named device/build sessions.
- PARTIAL outdoor AR receipt does **not** close Issue #41.
- After continuity/audio/UI mitigations, re-walk on **current main tip** for COH PASS claims.
- Do not treat `samples/*.json` as outdoor AR or #217 device PASS.
