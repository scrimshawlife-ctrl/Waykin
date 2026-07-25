# Design / Validation Receipts

Evidence files only. Do not invent OBSERVED results.

**Evidence vocabulary:** `OBSERVED` · `INFERRED` · `NOT_COMPUTABLE` (see `AGENTS.md`).  
Do not invent values like `OBSERVED_INDOOR_DEVICE` — use `OBSERVED` and note indoor in device fields.

## Current tip (2026-07-25)

| Field | Value |
| ----- | ----- |
| Prefer install tip | `main` @ `7089b5d` (or ≥ `3cc8ac2` with 0.9.0 / 2) |
| Marketing / build | **0.9.0 (2)** |
| Phase A (laptop) | `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md` — **PASS** |
| Indoor human | `INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md` — **PENDING** |
| Outdoor human | `OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md` — **PENDING** |

Older `*_PENDING.md` scaffolds for prior SHAs are **superseded** for new walks; keep for history only.

## Outdoor / physical

| File | Status |
| ---- | ------ |
| `OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md` | **PARTIAL** historical operator notes (pre-mitigation). Not full COH PASS. |
| `OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md` | **Current** outdoor scaffold — fill on daylight walk |
| Template | `../OUTDOOR_QA_RECEIPT_TEMPLATE.md` |

Outdoor filled copies should use:

```text
OUTDOOR_QA_RECEIPT_YYYYMMDD_<device-model>.md
```

## Indoor AR hybrid smoke

| File | Status |
| ---- | ------ |
| `INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md` | **Current** indoor scaffold — fill on device |
| Protocol | `../INDOOR_AR_HYBRID_SMOKE.md` |

## Phase A (laptop / sim)

| File | Status |
| ---- | ------ |
| `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md` | **PASS** validate on `3cc8ac2` (130 tests) |
| Older `PHASE_A_PREDEVICE_*` | Historical |

## Simulator preflight / engineering

Multiple `SIM_PREFLIGHT_*` and sim checklist receipts live in this directory. They are **SIMULATOR** evidence only.

## Field-test JSON samples (agent format)

See [`samples/`](samples/) — real sim export (schema 4) + synthetic schema **5** example. **Not** device or outdoor evidence.

## Rules

- `OBSERVED` only from named device/build sessions.
- PARTIAL outdoor AR receipt does **not** close Issue #41.
- After mitigations (continuity, audio, Hallmark UI, DCC), re-walk on **current main tip** for COH PASS claims.
- Do not treat `samples/*.json` as outdoor AR or device PASS.
- Prefer newest tip-bound PENDING receipt when starting a new human session.
