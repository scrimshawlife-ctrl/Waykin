# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-23 (post-merge #222 + #217; tip `68ba09d`)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| Issue #41 — outdoor / physical validation | Human device | **Parked / PARTIAL** — re-walk on tip after #217+#222 | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) · daylight · tip `68ba09d` |
| Indoor AR hybrid smoke | Human device | **Armed** — re-prep on `68ba09d`; prior receipts PENDING older SHAs | [INDOOR_AR_HYBRID_SMOKE.md](../design/INDOOR_AR_HYBRID_SMOKE.md) · `scripts/indoor_ar_smoke_prep.sh` |
| DCC clip composition follow-up | Engineering | **Open** — sidecars in USDZ; default layer is base mesh; full state-driven `availableAnimations` may still be puppet/hybrid | `EXPORT_OK` `clip_packaging=…composition_followup` |
| Internal TestFlight RC | Human (signing / ASC) | **Checklist ready** | [TESTFLIGHT_RC_CHECKLIST.md](../design/TESTFLIGHT_RC_CHECKLIST.md); tip `68ba09d`; #41 not required for *internal* TF |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Device AR/audio: full-screen, `.playback`, plant/follow, multi-part guard | PR #217 · main `68ba09d` |
| Artist mid-LOD USDZ replaces Meshy blob | PR #222 · main `ee57a7d` · closes #220 |
| Collab board + TF checklist + receipt samples | PR #218 · main `0d27074` |
| Info.plist encryption key only | PR #219 |
| Privacy manifest + encryption declaration | PR #215 · main `8beec34` |
| CI UI-test retry on hosted flake | PR #213 |
| Meshy textured Lira + puppet + spectral FX + compress | PRs #208–#211 |
| Native + UI test gate + AR integration re-ratify | PRs #205 / #207 |
| A11y + map-secondary law restore | PR #202 |
| Persistence WP-DB1–DB5 | PRs #185–#192 · recovery quarantine |
| Time-aware splash + Waykin display font | PR #184 |
| Debug D5–D7 + receipt schema 5 | Issue #196 · PR #197 |
| Grok skill pack (team-tracked `.grok/skills`) | PRs #198–#199 |

## Intake

| Work | Reason |
|---|---|
| Bind six DCC clip sidecars into runtime AnimationLibrary | Packaging follow-up; receipt should show `dcc:`/`hybrid:` + clip ids when done |
| Device Motion chrome: `skel_on` + real clip id after plant | Indoor smoke + #41; do not invent from sim alone |
| Smooth companion follow polish | Product; leash/follow shipped in #217 — field-tune if needed |
| WP-DB6 CloudKit evaluation ADR | Only if product requires multi-device restore |
| Optional DM Sans / extra SVG icons | Dedicated issue only |
| Orc / FutureSelf cleanup | Migration issue + Codable tests |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| #41 outdoor COH PASS | Device + daylight + tip after mitigations | Outdoor packet + COH receipt; do not invent PASS from sim |

## Field-test JSON (agents)

Format samples (not device evidence): `docs/design/receipts/samples/` (schema 5 EXAMPLE + sim schema 4). Production: Settings → share latest receipt. Source: `Sources/WaykinCore/Diagnostics/FieldTestReceipt.swift`.

## Parked recommendations

See [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) — outdoor #41 when resumed; indoor smoke; DCC clip composition; RC/FUTURE; Orc cleanup.

## Explicitly deferred (FUTURE / RC)

- Pathfinding v2, Health v2, Watch, AI Directors RC, multi-companion
- Removing deprecated Orc/FutureSelf surfaces (needs migration issue)
- Marketplace / multiplayer

## Merge hygiene

```text
Main is clear of open product PRs as of 68ba09d.
Prefer small docs/board PRs separate from AR code.
Avoid reintroducing Meshy Lira_Walk as runtime Lira_AR_Base.usdz.
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
