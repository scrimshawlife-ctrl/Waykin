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
| Issue #50 / PR #51 — Echo theme tokens (App presentation) | design-agent | `feat/50-echo-theme-tokens` | `App/Theme/**`, `App/CompanionPresenceView.swift`, `App/WaykinApp.swift`, `AppTests/WKTokensTests.swift`, `docs/assets/BRAND_GUIDE.md`, `docs/design/**`, `docs/collaboration/ACTIVE_WORK.md` | Merge-ready | No Core; no AR runtime ownership |
| Issue #46 — deterministic AR command replay and soak validation | Unassigned | Not started; branch must begin from current `main` | `AppTests/**`, focused test fixtures, directly affected validation docs | Ready | PR #45 merged as `16af4d2` |
| Issue #47 / PR #48 — GitHub Project coordination | Daniel + Codex | `agent/github-project-coordination` | `.github/**`, `AGENTS.md`, `Makefile`, `docs/collaboration/**`, `scripts/**` | Merged on main | Reconciled with `main@16af4d2` |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Issue #41 — physical AR validation | Physical device access is unavailable | Execute the evidence-only protocol on the named device and exact build; all unobserved fields remain `NOT_COMPUTABLE` |

## Completed

| Issue | Outcome | Evidence |
|---|---|---|
| Issue #35 — living-companion presentation | Complete | PR #40 merged as `4c645395`; Issue #35 closed completed |
| Issue #42 — canonical runtime AR integration | Complete | PR #45 merged as `16af4d2`; Issue #42 closed completed |

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
last_validated_commit:
commands_run:
blockers:
next_action:
```
