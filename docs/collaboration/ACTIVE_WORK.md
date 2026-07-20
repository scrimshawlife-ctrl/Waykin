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
| Issue #41 — outdoor / physical AR validation | Device operator | evidence-only (no product branch) | `docs/design/receipts/**` only | Ready for device walk | Exact `main` build; packet: `OUTDOOR_SESSION_PACKET.md` |

## Intake (not Ready)

| Work | Reason | Required resolution |
|---|---|---|
| — | — | — |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Issue #41 — physical AR + outdoor QA | Awaiting human device walk | Run `OUTDOOR_SESSION_PACKET.md` on named device; fill pending receipt under `docs/design/receipts/`; unobserved rows stay `NOT_COMPUTABLE` |

## Completed (recent)

| Issue / PR | Outcome | Evidence |
|---|---|---|
| Issue #115 — glasses glance adapter | Expansion ratified; mock-first adapter shipped (flag default off) | PR pending close with merge |
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
