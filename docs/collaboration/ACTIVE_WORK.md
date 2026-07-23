# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-23 (board refresh while #217 CI/device; distribution unblocked on main)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| [PR #217](https://github.com/scrimshawlife-ctrl/Waykin/pull/217) — AR/audio device fixes + skinned walk Lira | **prabu-openclaw** | **In flight** — full-screen, `.playback` audio, ground plant/continuity, rigged USDZ; walk anim device play still open | CI + review; Info.plist reconciles with #216 if both merge |
| [PR #216](https://github.com/scrimshawlife-ctrl/Waykin/pull/216) — Info.plist encryption sync + TestFlight RC checklist | scrimshawlife-ctrl | **APPROVED / green** — land after or folded into #217 Info.plist story | Do not double-edit Info.plist vs #217 |
| Issue #41 — outdoor / physical validation | Human device | **Parked / PARTIAL** — re-walk on tip after #217 | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) · daylight |
| Indoor AR hybrid smoke | Human device | **Armed** — fill PENDING receipt on named tip | [INDOOR_AR_HYBRID_SMOKE.md](../design/INDOOR_AR_HYBRID_SMOKE.md) · `scripts/indoor_ar_smoke_prep.sh` |
| Internal TestFlight RC | Human (signing / ASC) | **Unblocked for engineering** after #215 privacy/encryption; use #216 checklist when merged | Bump build number before archive; #41 not required for *internal* TF |

## Recently completed (main)

| Work | Evidence |
|---|---|
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
| Walk-cycle playback on device (`clips=N` diagnosis) | #217 known issue — field receipt `arPresentation.finalLODDescription` |
| Smooth companion follow (vs ~6 m replant teleports) | Product decision; not threshold-only |
| Soft-budget USDZ slim (&lt;12 MB) while keeping skinned walk | Optional; hard cap 20 MB |
| WP-DB6 CloudKit evaluation ADR | Only if product requires multi-device restore |
| Evidence class rename beyond `MESHY_TEXTURED_STATIC_V1` | Only with catalog + tests + EXPORT_OK |
| Optional DM Sans / extra SVG icons | Dedicated issue only |
| Orc / FutureSelf cleanup | Migration issue + Codable tests |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| #41 outdoor COH PASS | Device + daylight + tip after mitigations | Outdoor packet + COH receipt; do not invent PASS from sim |

## Field-test JSON (agents)

Format samples (not device evidence): `docs/design/receipts/samples/` when present on a branch (schema 5 EXAMPLE + sim schema 4). Production: Settings → share latest receipt. Source: `Sources/WaykinCore/Diagnostics/FieldTestReceipt.swift`.

## Parked recommendations

See [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) — outdoor #41 first when resumed; indoor smoke; DCC package slim-down; RC/FUTURE; Orc cleanup.

## Explicitly deferred (FUTURE / RC)

- Pathfinding v2, Health v2, Watch, AI Directors RC, multi-companion
- Removing deprecated Orc/FutureSelf surfaces (needs migration issue)
- Marketplace / multiplayer

## Merge hygiene (open PRs)

```text
Preferred: land #217 (product/device) then re-cut #216 or rebase checklist onto tip
          OR fold encryption-stable Info.plist + TF checklist into #217 before merge
Avoid: parallel Info.plist thrash — xcodegen must leave a clean tree on tip
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
