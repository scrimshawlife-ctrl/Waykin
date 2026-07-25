# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-25 (main `d9d1df7` — Hallmark #236 merged)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| Issue #41 — outdoor / physical validation | Human device | **Parked / PARTIAL** — re-walk on tip `d9d1df7`+ | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) · daylight |
| Indoor AR hybrid smoke | Human device | **Armed** — tip `d9d1df7` (Hallmark UI + DCC path); fill PENDING receipt | [INDOOR_AR_HYBRID_SMOKE.md](../design/INDOOR_AR_HYBRID_SMOKE.md) · `scripts/indoor_ar_smoke_prep.sh` |
| Internal TestFlight RC | Human (signing / ASC) | **Version cut 0.9.0 (2)** — checklist + marketing/build bump | [TESTFLIGHT_RC_CHECKLIST.md](../design/TESTFLIGHT_RC_CHECKLIST.md); #41 not required for *internal* TF |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Hallmark audit polish (Trail featured, single state chip, LiraMaterial tokens, left-bias prep/bond/sanctuary, WaykinDisplay titles) | PR #236 · main `d9d1df7` |
| Session double-End receipt/bond guard | PR #235 · main `dc54694` |
| Phase A pre-device receipt + audio cue family / lifecycle cues | PRs #230–#234 |
| Bake real joint curves into DCC clip USDZs (`mapped=6`, `clipSource=dcc`) | PR #226 · closes #225 |
| Device AR/audio: full-screen, `.playback`, plant/follow | PR #217 |
| Artist mid-LOD USDZ replaces Meshy blob | PR #222 · closes #220 |
| Privacy manifest + encryption | PRs #215 / #219 |
| Persistence WP-DB1–DB5 | PRs #185–#192 |

## Intake

| Work | Reason |
|---|---|
| Device Motion chrome: `skel_on` + `dcc` + real clip ids after plant | Indoor smoke + #41 |
| Smooth companion follow polish | Field-tune if needed after #217 |
| WP-DB6 CloudKit evaluation ADR | Only if multi-device restore required |
| Optional DM Sans / extra SVG icons | Dedicated issue only |
| Orc / FutureSelf cleanup | Migration issue + Codable tests |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| #41 outdoor COH PASS | Device + daylight | Outdoor packet + COH receipt; do not invent PASS from sim |

## Field-test JSON (agents)

Format samples (not device evidence): `docs/design/receipts/samples/` (schema 5 EXAMPLE + sim schema 4). Production: Settings → share latest receipt. Source: `Sources/WaykinCore/Diagnostics/FieldTestReceipt.swift`.

## Parked recommendations

See [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) — outdoor #41 when resumed; indoor smoke; RC/FUTURE; Orc cleanup.

## Explicitly deferred (FUTURE / RC)

- Pathfinding v2, Health v2, Watch, AI Directors RC, multi-companion
- Removing deprecated Orc/FutureSelf surfaces (needs migration issue)
- Marketplace / multiplayer

## Merge hygiene

```text
Main tip after #236: d9d1df7.
Do not reintroduce Meshy Lira_Walk as runtime Lira_AR_Base.usdz.
Ruleset requires 1 write-access approving review on PRs to main.
```

## Preservation

`wip/ar3-local-preservation` is not merge authority.

## UI authority (quick)

| Need | Doc |
|---|---|
| Product surfaces | [WAYKIN_UIUX_SPEC.md](../design/WAYKIN_UIUX_SPEC.md) |
| Tokens / candidate package | [UI_CANDIDATE_V02_POINTER.md](../design/UI_CANDIDATE_V02_POINTER.md) |
| Practice + PR receipt | [UI_ENGINEERING_PRACTICE.md](../design/UI_ENGINEERING_PRACTICE.md) · [UI_CHANGE_VALIDATION_RECEIPT.md](../design/UI_CHANGE_VALIDATION_RECEIPT.md) |
| Residual audit | [UI_CANDIDATE_RESIDUAL_AUDIT.md](../design/UI_CANDIDATE_RESIDUAL_AUDIT.md) |
| Conflicts | [DOCUMENT_AUTHORITY.md](../governance/DOCUMENT_AUTHORITY.md) |
