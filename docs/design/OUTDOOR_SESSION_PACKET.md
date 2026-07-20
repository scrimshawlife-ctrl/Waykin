# Outdoor Session Packet (operator runbook)

```yaml
document_id: WAYKIN-OUTDOOR-SESSION-PACKET
version: 0.1
status: ACTIVE
evidence_rule: OBSERVED_only_on_named_device
combines:
  - Issue_41_AR_physical_presentation
  - OUTDOOR_QA_CHECKLIST_UI
  - SIMULATOR_PREFLIGHT_gate
```

One walk packet for product/device operators. Completing this upgrades outdoor claims from `NOT_COMPUTABLE` to `OBSERVED` / `PARTIAL`. Agents cannot invent device evidence.

## 0. Pre-device gate (CI / laptop)

```bash
git checkout main && git pull
bash scripts/outdoor_qa_prep.sh
make validate
# optional automated sim receipt:
bash scripts/sim_walk_preflight.sh
```

| Gate | Required |
| ---- | -------- |
| `make validate` | PASS |
| Known build SHA recorded | yes |
| Filled receipt path created under `docs/design/receipts/` | yes (blank rows OK) |

## 1. Build identity (fill at install time)

| Field | Value |
| ----- | ----- |
| `git_sha` (full) | |
| `git_short` | |
| Config | Debug / Release |
| Device model | |
| iOS | |
| Date (local) | |
| Operator | |
| Weather / light | sun / bright shade / overcast / night street |

Install **exact** `main` tip used for the receipt. Do not mix SHAs mid-walk.

## 2. Order of operations (~25–40 min)

1. **Sim preflight (optional, 5 min)** — `SIMULATOR_PREFLIGHT.md` S1–S12 on Xcode Simulator. Ceiling: `OBSERVED_IN_SIMULATOR_ONLY`.
2. **Outdoor UI Pass A — Day** — `OUTDOOR_QA_CHECKLIST.md` D1–D8 (Home + Demo/Real walk chrome).
3. **Outdoor AR Pass E — Physical Lira (#41)** — table below (AR Lab or in-session AR surface).
4. **Outdoor UI Pass B — Night** (or dark indoor proxy if night walk not available) — N1–N6.
5. **Pass C — Reduce Motion** — R1–R3 (can be shade/indoor after day walk).
6. **Pass D — Pressure tone** — H1–H3 during demo pressure or real pursuit language.
7. **Sign receipt** → `docs/design/receipts/OUTDOOR_QA_RECEIPT_<YYYYMMDD>_<device>.md`
8. Failures → **new bounded defect issue** (do not edit product code on the sidewalk).

## 3. Pass E — Physical AR presentation (Issue #41)

Evidence-only. No gameplay claims.

| ID | Check | Result | Notes |
| -- | ----- | ------ | ----- |
| E1 | Lira visible at normal outdoor brightness | PASS / FAIL / NA | |
| E2 | Idle / Follow / Investigate / Alert / Celebrate distinguishable without color alone | PASS / FAIL / NA | |
| E3 | Placement on horizontal outdoor surface succeeds | PASS / FAIL / NA | |
| E4 | Repeated companion replace → one Lira, no ghost anchors | PASS / FAIL / NA | |
| E5 | Clear removes all visible entities | PASS / FAIL / NA | |
| E6 | Background/reopen does not resurrect cleared entities | PASS / FAIL / NA | |
| E7 | Celebrate completes and returns to Idle | PASS / FAIL / NA | |
| E8 | Thermal / battery notes for bounded run | NOTED / NA | |
| E9 | Tracking limits / lighting / surface / duration recorded | NOTED / NA | |

Privacy: do not retain camera frames, precise GPS traces, or private map imagery in the receipt.

## 4. Real walk vs Demo

| Mode | Use for |
| ---- | ------- |
| **Demo Walk** | UI chrome, pressure language, audio cues, glance phrase, AR Lab without GPS |
| **Real Walk** | GPS integrity feel, outdoor distance, location permission path (no coord dumps in receipt) |

Both may be exercised; mark modes in the receipt meta table.

## 5. Explicitly still NOT_COMPUTABLE without this packet

- Outdoor sun glare / night street washout
- True outdoor AR tracking quality
- Battery / thermal on long walks
- Physical Ray-Ban glance HUD
- GPS meter accuracy claims

## 6. After overall OBSERVED / PARTIAL

1. Commit receipt under `docs/design/receipts/` (no private EXIF).
2. Comment on Issue #41 with SHA + evidence class + link to receipt.
3. Close #41 only if E1–E7 are PASS or explicitly NA with reason; else leave open with PARTIAL.
4. Open defect issues for any FAIL rows.
5. Update `ACTIVE_WORK.md` blocked row for outdoor QA.

## Related docs

- [OUTDOOR_QA_CHECKLIST.md](OUTDOOR_QA_CHECKLIST.md)
- [OUTDOOR_QA_RECEIPT_TEMPLATE.md](OUTDOOR_QA_RECEIPT_TEMPLATE.md)
- [SIMULATOR_PREFLIGHT.md](SIMULATOR_PREFLIGHT.md)
- Issue #41 — physical AR validation
