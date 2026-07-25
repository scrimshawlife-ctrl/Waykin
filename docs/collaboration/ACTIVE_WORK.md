# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-25 (Phase A validate PASS on `3cc8ac2`; device offline)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| Issue #41 — outdoor / physical validation | Human device | **Parked / PARTIAL** — daylight re-walk on tip `3cc8ac2` | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) · outdoor PENDING receipt |
| Indoor AR hybrid smoke | Human device | **Armed** — tip `3cc8ac2`; Phase A PASS; **iPhone offline** | [INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md](../design/receipts/INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md) |
| Internal TestFlight RC | Human (signing / ASC) | **Validate PASS** on tip · 0.9.0 (2) · archive when phone/signing ready | [TESTFLIGHT_RC_CHECKLIST.md](../design/TESTFLIGHT_RC_CHECKLIST.md) · [PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md](../design/receipts/PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2.md) |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Phase A local validate on archive tip | Receipt `PHASE_A_PREDEVICE_20260725T194535Z_3cc8ac2` · 130 package tests |
| TF cut SHA pin | PR #238 · `3cc8ac2` |
| Board + indoor scaffold + marketing 0.9.0 (2) | PR #237 · `2d969a0` |
| Hallmark UI polish | PR #236 · `d9d1df7` |
| Session double-End receipt/bond guard | PR #235 |
| Audio cue family + lifecycle + AR presentation audio | PRs #230–#234 |
| DCC bake / composition / artist mid-LOD | PRs #222–#226 |
| Privacy manifest + encryption | PRs #215 / #219 |

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
| Indoor smoke OBSERVED | Physical iPhone was offline at prep | Connect device; install Debug `3cc8ac2`; fill I1–I12 |
| #41 outdoor COH PASS | Device + daylight | Outdoor packet + COH receipt |
| TestFlight upload | Human Apple signing / ASC | Archive Release of tip; Internal Testing |

## Field-test JSON (agents)

Format samples (not device evidence): `docs/design/receipts/samples/`. Production: Settings → share latest receipt. Schema **5**.

## Parked recommendations

See [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md).

## Explicitly deferred (FUTURE / RC)

- Pathfinding v2, Health v2, Watch, AI Directors RC, multi-companion
- Marketplace / multiplayer

## Merge hygiene

```text
Main tip: 3cc8ac2 · version 0.9.0 (2)
Ruleset: 1 write-access approving review required
Do not reintroduce Meshy walk as default Lira_AR_Base.usdz
```

## UI authority (quick)

| Need | Doc |
|---|---|
| Product surfaces | [WAYKIN_UIUX_SPEC.md](../design/WAYKIN_UIUX_SPEC.md) |
| Tokens | [UI_CANDIDATE_V02_POINTER.md](../design/UI_CANDIDATE_V02_POINTER.md) |
| Practice | [UI_ENGINEERING_PRACTICE.md](../design/UI_ENGINEERING_PRACTICE.md) |
| Conflicts | [DOCUMENT_AUTHORITY.md](../governance/DOCUMENT_AUTHORITY.md) |
