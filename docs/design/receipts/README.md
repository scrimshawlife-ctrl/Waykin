# Design / Validation Receipts

Evidence files only. Do not invent OBSERVED results.

**Evidence vocabulary:** `OBSERVED` · `INFERRED` · `NOT_COMPUTABLE` (see `AGENTS.md`).  
Do not invent values like `OBSERVED_INDOOR_DEVICE` — use `OBSERVED` and note indoor in device fields.

## Current tip (2026-07-29)

| Field | Value |
| ----- | ----- |
| Prefer install tip | `main` @ `7df3a16` (`7df3a169ede507ce54469330318f66c4603f8c3d`) |
| Companion runtime | Packaged **Ember Fox** (`MESHY_EMBER_FOX_WALK_V1`) via PR #246 |
| Marketing / build (in tree) | **0.9.0 (2)** — revalidate; TF archive held by #247 |
| Phase A (laptop, post-mesh) | **Required** — create `POST_EMBER_FOX_BASELINE_*` or new `PHASE_A_PREDEVICE_*` on current tip |
| Phase A (pre-mesh, historical) | `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md` — **PASS on `3cc8ac2` only** |
| Indoor human | Re-scaffold on install tip; prior `*_3cc8ac2_PENDING` is **historical** |
| Outdoor human | Re-scaffold on install tip; prior `*_3cc8ac2_PENDING` is **historical** |

Older `*_PENDING.md` scaffolds for prior SHAs are **historical / superseded** for new walks; keep for history only. Do not rewrite their original SHAs.

## Outdoor / physical

| File | Status |
| ---- | ------ |
| `OUTDOOR_AR_RECEIPT_20260720_DEVICE_PARTIAL.md` | **PARTIAL** historical operator notes (pre-mitigation, pre-mesh). Not full COH PASS. |
| `OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md` | **Historical** outdoor scaffold for artist-blend tip era |
| Template | `../OUTDOOR_QA_RECEIPT_TEMPLATE.md` |

Outdoor filled copies should use:

```text
OUTDOOR_QA_RECEIPT_YYYYMMDD_<device-model>.md
```

or tip-bound:

```text
OUTDOOR_QA_RECEIPT_<DATE>_<SHORT_SHA>_PENDING.md
```

## Indoor AR hybrid smoke

| File | Status |
| ---- | ------ |
| `INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md` | **Historical** (artist-blend / pre-Ember Fox install target) |
| Protocol | `../INDOOR_AR_HYBRID_SMOKE.md` (Ember Fox checks) |

Create a new tip-bound indoor PENDING receipt when installing `7df3a16` or later.

## Phase A (laptop / sim)

| File | Status |
| ---- | ------ |
| `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md` | **Historical PASS** validate on `3cc8ac2` (pre-mesh) |
| Older `PHASE_A_PREDEVICE_*` | Historical |
| Post–Ember Fox baseline | Create on validate of tip ≥ `b17864e` / `7df3a16` |

## Simulator preflight / engineering

Multiple `SIM_PREFLIGHT_*` and sim checklist receipts live in this directory. They are **SIMULATOR** evidence only.

## Field-test JSON samples (agent format)

See [`samples/`](samples/) — real sim export (schema 4) + synthetic schema **5** example. **Not** device or outdoor evidence.

## Rules

- `OBSERVED` only from named device/build sessions.
- PARTIAL outdoor AR receipt does **not** close Issue #41.
- After mesh/runtime supersession (#246), re-walk on **current main tip** for COH PASS claims.
- Do not treat `samples/*.json` as outdoor AR or device PASS.
- Prefer newest tip-bound PENDING receipt when starting a new human session.
- Historical receipts retain original SHAs; label them historical rather than rewriting.
