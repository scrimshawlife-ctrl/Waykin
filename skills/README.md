# Waykin Skill Pack (Grok Build)

Installable engineering skills bound to **this repository**, not generic Swift advice.

## Team use (Prabu and every collaborator)

**Tracked install path:** `.grok/skills/waykin-*` is **committed** so Grok discovers skills after a normal `git clone` / `git pull` when CWD is the Waykin repo. No private machine-only install is required for shared work.

```bash
git pull --ff-only origin main
# Open Grok Build with workspace = Waykin root
# Slash: /waykin-validate , /waykin-build , ...
./skills/install.sh --check   # optional verify
```

## Install (optional personal copy)

```bash
cd /path/to/Waykin
./skills/install.sh              # user + refresh repo .grok/skills
./skills/install.sh --user-only  # ~/.grok/skills only (any CWD later)
./skills/install.sh --repo-only  # refresh committed discovery path
```

Paths:

- `~/.grok/skills/waykin-*` — personal (all projects)
- `.grok/skills/waykin-*` — **team**, tracked in git

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
