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

## Simulator preflight / engineering

Multiple `SIM_PREFLIGHT_*` and sim checklist receipts live in this directory. They are **SIMULATOR** evidence only.

## Rules

- `OBSERVED` only from named device/build sessions.
- PARTIAL outdoor AR receipt does **not** close Issue #41.
- After continuity/audio/UI mitigations, re-walk on **current main tip** for COH PASS claims.
