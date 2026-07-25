# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-25 (Hallmark UI polish #236 CI green; auto-merge awaits write review)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| Issue #41 — outdoor / physical validation | Human device | **Parked / PARTIAL** — re-walk after #217–#226 + UI polish on tip | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) · daylight |
| Indoor AR hybrid smoke | Human device | **Armed** — re-prep on post-#236 tip (expect Motion `dcc` / mapped clips) | [INDOOR_AR_HYBRID_SMOKE.md](../design/INDOOR_AR_HYBRID_SMOKE.md) · `scripts/indoor_ar_smoke_prep.sh` |
| Internal TestFlight RC | Human (signing / ASC) | **Checklist ready** | [TESTFLIGHT_RC_CHECKLIST.md](../design/TESTFLIGHT_RC_CHECKLIST.md); #41 not required for *internal* TF |
| PR #236 Hallmark UI polish | Agent / reviewer | **CI green · auto-merge** — needs 1 write-access approving review (author cannot self-approve) | https://github.com/scrimshawlife-ctrl/Waykin/pull/236 |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Hallmark audit polish (Trail featured, single state chip, LiraMaterial tokens, left-bias prep/bond/sanctuary, WaykinDisplay titles) | PR #236 (merge pending review) · tip `04b7089` |
| Phase A pre-device receipt + audio cue family / lifecycle cues | PRs #230–#234 · main through `0586429` |
| Board after #226 (ACTIVE_WORK + indoor scaffold) | PR #227 · main `f061b4e` |
| Bake real joint curves into DCC clip USDZs (`mapped=6`, `clipSource=dcc`) | PR #226 · main `c4995f4` · closes #225 |
| DCC clip sidecar composition path (bundle + load-before-publish) | PR #224 · main `7931120` |
| Device AR/audio: full-screen, `.playback`, plant/follow, multi-part guard | PR #217 · main `68ba09d` |
| Artist mid-LOD USDZ replaces Meshy blob | PR #222 · main `ee57a7d` · closes #220 |
| Collab board + TF checklist + receipt samples | PR #218 |
| Privacy manifest + encryption + Info.plist sync | PRs #215 / #219 |
| CI UI-test retry + native gate | PRs #213 / #205 |
| Persistence WP-DB1–DB5 | PRs #185–#192 |

## Intake

| Work | Reason |
|---|---|
| Device Motion chrome: `skel_on` + `dcc` + real clip ids after plant | Indoor smoke + #41; sim evidence on #226, device still NOT_COMPUTABLE |
| Smooth companion follow polish | Product; leash/follow shipped in #217 — field-tune if needed |
| WP-DB6 CloudKit evaluation ADR | Only if product requires multi-device restore |
| Optional DM Sans / extra SVG icons | Dedicated issue only |
| Orc / FutureSelf cleanup | Migration issue + Codable tests |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| #41 outdoor COH PASS | Device + daylight + tip after mitigations | Outdoor packet + COH receipt; do not invent PASS from sim |
| #236 merge | Branch ruleset: ≥1 approving review from write access | Collaborator approve → auto-merge |

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
Prefer small docs/board PRs separate from AR code.
Do not reintroduce Meshy Lira_Walk as runtime Lira_AR_Base.usdz.
Hallmark UI polish is App-only; re-validate indoor smoke after #236 lands.
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
