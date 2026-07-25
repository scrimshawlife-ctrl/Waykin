# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-25 (main `d7954ac` — Phase A PASS; device + TF human lane)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| Issue #41 — outdoor / physical validation | Human device | **Parked / PARTIAL** — daylight re-walk on tip `d7954ac` (or ≥ `3cc8ac2` with same binary identity) | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) · [OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md](../design/receipts/OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md) |
| Indoor AR hybrid smoke | Human device | **Armed** — Phase A PASS; fill PENDING on install tip | [INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md](../design/receipts/INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md) · protocol [INDOOR_AR_HYBRID_SMOKE.md](../design/INDOOR_AR_HYBRID_SMOKE.md) |
| Internal TestFlight RC | Human (signing / ASC) | **Ready to archive** — marketing **0.9.0** / build **2**; laptop validate PASS | [TESTFLIGHT_RC_CHECKLIST.md](../design/TESTFLIGHT_RC_CHECKLIST.md) · [PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md](../design/receipts/PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md) |

## Tip identity

| Field | Value |
|---|---|
| `main` tip (full) | `d7954ac44000da76f53ee687ebb26fed9dcfeeca` |
| `main` tip (short) | `d7954ac` |
| Marketing / build | **0.9.0 (2)** |
| Phase A validate SHA | `3cc8ac2` (ancestor; app version + binary same; tip adds docs only via #239) |
| Open product issues | [#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41) only |
| Open PRs | Prefer none; board is device/TF human lane |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Coordination doc sync to tip | PR #240 · main `d7954ac` |
| Phase A + device/TF handoff receipts | PR #239 · `7089b5d` |
| TF cut SHA pin | PR #238 · `3cc8ac2` |
| Marketing 0.9.0 (2) + board + indoor scaffold | PR #237 · `2d969a0` |
| Hallmark UI polish (Trail featured, single state chip, LiraMaterial tokens, left-bias, WaykinDisplay titles) | PR #236 · `d9d1df7` |
| Session double-End receipt/bond guard | PR #235 · `dc54694` |
| Audio cue family + lifecycle + AR presentation audio | PRs #230–#234 |
| DCC bake / composition / artist mid-LOD | PRs #222–#226 |
| Privacy manifest + encryption | PRs #215 / #219 |
| Persistence WP-DB1–DB5 | PRs #185–#192 |

## Operator order (human)

1. **Connect iPhone** → install Debug tip `d7954ac` → indoor I1–I12 → `evidence_class: OBSERVED` (note indoor).
2. **Archive Release** tip → Internal Testing (0.9.0 / 2) — re-run `make validate` if tip moved past Phase A receipt.
3. **Daylight outdoor #41** on same tip when free; COH only with OBSERVED device rows.

## Intake

| Work | Reason |
|---|---|
| Device Motion chrome after plant (`dcc` / clip ids) | Indoor smoke + #41 |
| Smooth companion follow polish | Field-tune if needed after #217 |
| WP-DB6 CloudKit evaluation ADR | Only if multi-device restore required |
| Optional DM Sans / extra SVG icons | Dedicated issue only |
| Orc / FutureSelf cleanup | Migration issue + Codable tests |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Indoor smoke OBSERVED | Needs physical iPhone | Connect device; fill indoor PENDING receipt |
| #41 outdoor COH PASS | Device + daylight | Outdoor packet + COH; do not invent PASS from sim |
| TestFlight upload | Human Apple signing / ASC | Organizer archive of tip with 0.9.0 (2) |

## Field-test JSON (agents)

Format samples (not device evidence): `docs/design/receipts/samples/`. Production: Settings → share latest receipt. Schema **5**.

## Parked recommendations

See [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md).

## Explicitly deferred (FUTURE / RC)

- Pathfinding v2, Health v2, Watch, AI Directors RC, multi-companion
- Marketplace / multiplayer

## Merge hygiene

```text
Main tip: d7954ac · version 0.9.0 (2)
Ruleset: 1 write-access approving review required
Do not reintroduce Meshy walk as default Lira_AR_Base.usdz
Do not claim outdoor PASS without #41 device receipt
```

## UI authority (quick)

| Need | Doc |
|---|---|
| Product surfaces | [WAYKIN_UIUX_SPEC.md](../design/WAYKIN_UIUX_SPEC.md) |
| Tokens | [UI_CANDIDATE_V02_POINTER.md](../design/UI_CANDIDATE_V02_POINTER.md) |
| Practice | [UI_ENGINEERING_PRACTICE.md](../design/UI_ENGINEERING_PRACTICE.md) |
| Continuation | [CONTINUATION_PLAN.md](../design/CONTINUATION_PLAN.md) |
| Conflicts | [DOCUMENT_AUTHORITY.md](../governance/DOCUMENT_AUTHORITY.md) |
