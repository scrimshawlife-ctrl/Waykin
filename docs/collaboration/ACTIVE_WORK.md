# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-20 (post #126; non-outdoor polish #147–#150 in flight)

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
| Issues #147–#150 — non-outdoor polish | agent | `fix/147-non-outdoor-polish` | App UI/AR chrome, docs, AppTests, scripts | In progress | Sim-only; no outdoor claims |
| Issue #41 — outdoor / physical validation | — | — | receipts | **Blocked (dark / deferred)** | Daylight re-walk on main tip |

## Intake (not Ready)

| Work | Reason | Required resolution |
|---|---|---|
| — | — | — |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Issue #41 outdoor PASS | Device walk required; dark outdoor deferred | Daylight re-walk + Pass COH + continuity + audio |

## Completed (recent)

| Issue / PR | Outcome | Evidence |
|---|---|---|
| #126 menu UX | Home CTA priority + AR full-screen + mirrored controls | PR #146 |
| #139–#143 coupling | Presentation matrix, path audio/AR, distance, COH receipt | PR #145 |
| #125 AR continuity code | Re-plant + camera fallback | PR #138 |
| #130 audio coupling code | Behavior-transition cues + gain | PR #138 |
| #133 graphics diagnostics | still/LOD paths | PR #136 |
| #128 elapsed clock | Wall-clock presentation | PR #129 |
| #121 session map | Follow + trace + GPS chip | PR #123 |
| #115 glasses glance | Mock adapter, flag off | PR #120 |

## Preservation Boundary

The local `wip/ar3-local-preservation` branch remains an isolated preservation surface. It is not merge authority.
