# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-19

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow state:** [GitHub Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · **Repository snapshot and protocol:** this ledger · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

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
| — | — | — | — | Idle | Event weight light tune; outdoor/AR device still blocked |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Issue #41 — physical AR validation | Physical device access is unavailable | Execute the evidence-only protocol on the named device and exact build; all unobserved fields remain `NOT_COMPUTABLE` |
| Outdoor QA receipt | Device walk deferred by product owner | Fill `OUTDOOR_QA_RECEIPT_TEMPLATE.md` on named device |

## Completed

| Issue | Outcome | Evidence |
|---|---|---|
| Issue #35 — living-companion presentation | Complete | PR #40 merged as `4c645395`; Issue #35 closed completed |
| Issue #42 — canonical runtime AR integration | Complete | PR #45 merged as `16af4d2`; Issue #42 closed completed |
| Issue #46 — AR command replay + soak | Complete | `ARCommandReplaySoakTests` + `docs/AR_REPLAY_VALIDATION.md` |
| Issue #50 — Echo theme tokens | Complete | PR #51 merged as `c5f97e4` |
| Issue #52 — Echo icons + Bond Filament | Complete | PR #53 merged as `54582c4` |
| Issue #55 — App Icon + Lira Echo + outdoor QA | Complete | PR #56 merged as `63d632e` |
| Issue #57 — Lira art pipeline + outdoor receipt | Complete | PR #58 merged |
| Issue #59 — Lira session-mid puppet | Complete | PR #60 merged |
| Issue #61 — Lira skins + Home presence | Complete | PR #62 merged |
| Issue #63 — AR skins, appearance, stills, sim | Complete | PR #64 merged |
| Issue #66 — Dawn stills + glyph LOD | Complete | PR #67 merged |
| Issue #68 — Veil/Rupture still matrix (SVG) | Complete | PR #69 merged |
| Issue #70 — spectral Lira generated art | Complete | PR #71 merged as `89f251a` |
| Issue #72 — complete Veil/Rupture AI poses | Complete | PR #73 merged as `e0f2479` |
| Issue #74 — sim walk preflight + a11y | Complete | PR #75 merged as `fdb269e` |

## Preservation Boundary

The local `wip/ar3-local-preservation` branch remains an isolated preservation surface. It is not merge authority for Issue #46 or any later work.

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
