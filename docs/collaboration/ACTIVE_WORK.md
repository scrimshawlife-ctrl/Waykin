# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-20

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) (closed completed; PR #48) · **Live workflow state:** [GitHub Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · **Repository snapshot and protocol:** this ledger · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Rules

- One active owner per issue.
- One declared branch per issue.
- Declare allowed and frozen path groups before coding.
- Do not run parallel tasks that require the same file.
- Update this ledger when work starts, blocks, transfers, or completes.
- Remove completed entries after the corresponding PR merges or closes.
- Local WIP branches are preservation surfaces, not merge authority.

## Active

| Issue / PR | Owner | Branch / worktree | Allowed paths | Status | Dependency |
|---|---|---|---|---|---|

| Issue #130 — audio ↔ companion actions + produced cues not perceived | UNASSIGNED | — | AudioExperienceLayer, AppAudioCuePlayer, session wiring, docs | Ready | #41 PARTIAL; event-only audio architecture |
| Issue #125 — AR continuity (disappear ~10–15 m) | UNASSIGNED | — | `App/AR/**`, AppTests, docs | Ready (IMPLEMENT after claim) | #41 PARTIAL receipt |
| Issue #126 — session/AR menu UX audit | UNASSIGNED | — | App session chrome, docs | Ready (audit first) | #41 PARTIAL; before more outdoor AR |

## Intake (not Ready)

| Work | Reason | Required resolution |
|---|---|---|
| — | — | — |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Issue #41 — outdoor / physical AR validation | **PARTIAL device evidence** recorded; full PASS blocked | Address #125 + #126 (or accept world-plant design); then resume outdoor packet |
| Further outdoor AR PASS claims | Continuity + menu friction | Do not claim continuous outdoor AR until #125 closed or explicitly accepted |

## Completed (recent)

| Issue / PR | Outcome | Evidence |
|---|---|---|
| Issue #133 — graphics LOD diagnostics | Session still path + AR load notes (not hero mesh claim) | PR pending |
| Issue #132 — UI/UX design spec | PROPOSED docs landed | PR #135 merged |
| Issue #128 — session elapsed ~2s steps | Fixed wall-clock presentation + 1Hz refresh | PR #129 merged |
| Issue #121 — session map follow + path trace + GPS chip | Complete (path-trace ratified presentation-only) | PR #123 merged |
| Issue #115 — glasses glance adapter | Expansion ratified; mock-first adapter shipped (flag default off) | PR #120 merged |
| Issue #47 — agent coordination board | Complete | PR #48 merged; Project #1 live; closed 2026-07-20 |
| Issue #46 — AR command replay + soak | Complete | `ARCommandReplaySoakTests` + docs |
| Issue #104 — HealthKit V1 hardening | Complete | PR #106 |
| Issue #101 — produced audio cues | Complete | PR #108 |
| Issue #107 / #110 — test defect repairs | Complete | PRs #109, #113 |
| PR #112 — USDZ v1.1 + AR motion + still quality | Complete | merged |
| PR #114 — Veil/Rupture still quality | Complete | merged |
| PR #116 — MeshDescriptor mid-LOD mesh + animation channels | Complete | merged |
| PR #117 — joint-hierarchy skeletal AnimationLibrary | Complete | merged (`86da7ad`) |

## Historical completed (abridged)

Earlier closed issues (#35, #42, #50–#90 art/AR indoor ladder, etc.) remain in GitHub closed-issue history. Prefer Project #1 **Completed Receipts** for workflow state.

## Preservation Boundary

The local `wip/ar3-local-preservation` branch remains an isolated preservation surface. It is not merge authority.

## Handoff Entry Template

```yaml
issue:
owner:
agent:
branch:
allowed_paths:
frozen_paths:
status:
notes:
```
