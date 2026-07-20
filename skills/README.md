# Waykin Skill Pack (Grok Build)

Installable engineering skills bound to **this repository**, not generic Swift advice.

## Install

```bash
cd /path/to/Waykin
./skills/install.sh
```

Installs into:

- `~/.grok/skills/waykin-*` (user, all sessions)
- `.grok/skills/waykin-*` (repo-local, highest priority when CWD is Waykin)

## Skills

| Slash | Purpose |
|-------|---------|
| `/waykin-build` | Inspect, generate, build sim/device, diagnose failures |
| `/waykin-validate` | Full engineering validation report (CI parity) |
| `/waykin-ui-review` | SwiftUI / UX review against Waykin UI law |
| `/waykin-device-testing` | Physical-device readiness + evidence receipts |
| `/waykin-ar-debug` | Product AR / RealityKit debug (repo-specific) |
| `/waykin-audio` | Semantic audio + AppAudioCuePlayer / session routing |
| `/waykin-healthkit` | Optional HealthKit enrichment review |
| `/waykin-performance` | Startup, concurrency, render, energy prioritization |
| `/waykin-pr-review` | PR review with PASS / PASS WITH COMMENTS / REQUEST CHANGES |
| `/waykin-release` | Release candidate / TestFlight readiness checklist |

## Shared context

Every skill embeds `references/REPO_CONTEXT.md` on install (copied from `_shared/`).

## Do not

- Duplicate `scripts/*` tooling — invoke it.
- Claim outdoor PASS without #41 device evidence.
- Expand product scope (run/cycle, multiplayer, CloudKit) without binding docs.
