# Remote Collaborator Guide

This guide defines the default workflow for a remote human collaborator using a coding agent in the Waykin repository.

## Start Here

Before editing, read:

1. `WAYKIN_SPEC.md`
2. `ARCHITECTURE.md`
3. `AGENTS.md`
4. `CONTRIBUTING.md`
5. The assigned GitHub issue

Future-state and master-pack documents do not authorize implementation unless promoted through `docs/governance/SPEC_PROMOTION_PROCESS.md`.

## Local Setup

```bash
git clone https://github.com/scrimshawlife-ctrl/Waykin.git
cd Waykin
git checkout main
git pull --ff-only

make build
make test
make validate
```

Run `make validate-simulator` when the task changes simulator-visible behavior.

### Grok Build skill pack (all collaborators)

Waykin ships repo-specific Grok skills under `.grok/skills/waykin-*` (tracked in git).  
**After clone or pull, Grok discovers them automatically** when the working directory is the Waykin repo — no per-user install required for team members (including `prabu-openclaw`).

Optional personal copy (any machine, any CWD):

```bash
./skills/install.sh --user-only   # → ~/.grok/skills/waykin-*
./skills/install.sh --check       # verify discovery files
```

| Slash | Use for |
|-------|---------|
| `/waykin-build` | Package + App build / diagnose |
| `/waykin-validate` | Full `make validate` report |
| `/waykin-ui-review` | SwiftUI vs UIUX + practice docs |
| `/waykin-device-testing` | Device / outdoor #41 readiness |
| `/waykin-ar-debug` | Product AR stack |
| `/waykin-audio` | Semantic audio + App player |
| `/waykin-healthkit` | Optional HK enrichment |
| `/waykin-performance` | Hot paths / jank prioritization |
| `/waykin-pr-review` | PR verdict PASS / REQUEST CHANGES |
| `/waykin-release` | RC / TestFlight checklist |

Canonical source + reinstall: [`skills/README.md`](../../skills/README.md).  
Skills invoke existing `scripts/*` and Makefile targets — they do not replace them.

## Work Selection

Do not begin from a chat message or broad design document. Start from an assigned GitHub issue containing:

- User-visible outcome
- Acceptance criteria
- Allowed paths
- Frozen paths
- Required tests
- Device-evidence requirements
- Explicit non-goals

If those fields are missing or contradictory, stop and update the issue before coding.

## Branching

Create one branch per issue from current `main`:

```bash
git checkout main
git pull --ff-only
git checkout -b feat/<issue>-<short-name>
```

Use `fix/`, `test/`, `docs/`, or `chore/` when appropriate. Do not base ordinary work on another feature branch unless the issue explicitly declares a reviewed stacked dependency.

## Agent Context

Give the agent the completed `docs/collaboration/AGENT_TASK_PACKET_TEMPLATE.md`. The agent must not infer authority from a future design document, expand scope, or edit frozen paths.

## Implementation Rules

- Keep the patch as small as possible.
- Extend existing owners instead of creating parallel systems.
- Do not move gameplay truth into SwiftUI, ARKit, RealityKit, MapKit, SwiftData, or audio adapters.
- Do not change movement, Bond, persistence, receipt, safety, or semantic-audio contracts without explicit issue authorization.
- Do not claim physical GPS, audio, AR tracking, battery, thermal, or outdoor behavior without direct device evidence.
- Commit focused changes rather than one mixed agent dump.

## Required Handoff Validation

```bash
make build
make test
make validate
git diff --check
```

Also run:

- `make validate-simulator` for simulator-visible behavior.
- The relevant physical-device protocol for device-dependent behavior.
- Framework isolation checks when editing AR presentation.

## Pull Request Handoff

Open a draft PR and include:

- Issue reference
- Authority documents read
- Changed and frozen paths
- Agent/tool used
- Commands and exact results
- Device-evidence status
- Assumptions and unresolved items
- Parent or superseded PR, if any

Do not mark the PR ready until the required checks pass and the human implementer has inspected the complete diff.

## Stop Conditions

Stop and request issue clarification when:

- The task requires a frozen path.
- Two active tasks need the same file.
- The implementation introduces a new source of gameplay truth.
- A future document conflicts with current authority.
- Required validation cannot be run.
- The agent proposes backend, marketplace, multiplayer, LiveOps, generalized AI, or other unapproved scope.
