# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-23 (artist AR package #222; device AR #217; main has #218/#219)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| [PR #222](https://github.com/scrimshawlife-ctrl/Waykin/pull/222) — artist Lira mid-LOD USDZ | eng | **In flight** — package ~4.8 MB `ARTIST_BLEND_HERO_DCC_MID_LOD` | Issue #220 |
| [PR #217](https://github.com/scrimshawlife-ctrl/Waykin/pull/217) — device AR/audio | prabu-openclaw | **In flight** — full-screen, playback, plant/follow; **do not clobber #222 USDZ** | Rebase after #222 |
| [PR #221](https://github.com/scrimshawlife-ctrl/Waykin/pull/221) — sculpt plan docs | — | Green / needs non-author review | Issue #220 |
| Issue #41 — outdoor physical validation | Human device | **Parked / PARTIAL** | Daylight re-walk on tip |
| Indoor AR hybrid smoke | Human device | Armed scaffold on main (#218) | Fill PENDING receipt |
| Internal TestFlight RC | Human | Checklist on main (#218); encryption plist (#219) | Bump build; signing |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Board refresh + TF checklist + receipt samples | PR #218 |
| Info.plist encryption key | PR #219 |
| Privacy manifest + encryption declaration | PR #215 |
| Meshy textured Lira ladder (interim) | PRs #208–#211 |
| CI native/UI gates + flake retry | #205 / #213 |
| Persistence WP-DB1–DB5 | #185–#192 |
| Grok skill pack | #198–#199 |

## Intake

| Work | Reason |
|---|---|
| [Issue #220](https://github.com/scrimshawlife-ctrl/Waykin/issues/220) — AR production sculpt / brand package | #222 packaging; device silhouette OBSERVED still open |
| Walk-cycle playback on device (`clips=N`) | #217 known issue |
| Soft-budget / freehand silhouette polish | Only if indoor still fails brand gates |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| #41 outdoor COH PASS | Device + daylight | Outdoor packet + COH on tip SHA |

## Merge hygiene

```text
Prefer: #221 (docs) → #222 (artist USDZ) → #217 (device code, keep main package)
Avoid:  #217 reintroducing Meshy as Lira_AR_Base.usdz after #222
```

## UI authority (quick)

| Need | Doc |
|---|---|
| Product surfaces | [WAYKIN_UIUX_SPEC.md](../design/WAYKIN_UIUX_SPEC.md) |
| Practice + PR receipt | [UI_ENGINEERING_PRACTICE.md](../design/UI_ENGINEERING_PRACTICE.md) |
| Conflicts | [DOCUMENT_AUTHORITY.md](../governance/DOCUMENT_AUTHORITY.md) |
