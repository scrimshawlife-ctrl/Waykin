# Waykin Skill Pack — Installation Report

```yaml
pack: waykin-skill-pack
version: 1.0.0
date_utc: 2026-07-20
repo_sha: 60afcef
installer: skills/install.sh
```

## Installed skills

| Skill | Slash | User path | Repo path | Smoke |
|-------|-------|-----------|-----------|-------|
| waykin-build | `/waykin-build` | `~/.grok/skills/waykin-build` | `.grok/skills/waykin-build` | OK |
| waykin-validate | `/waykin-validate` | `~/.grok/skills/waykin-validate` | `.grok/skills/waykin-validate` | OK |
| waykin-ui-review | `/waykin-ui-review` | `~/.grok/skills/waykin-ui-review` | `.grok/skills/waykin-ui-review` | OK |
| waykin-device-testing | `/waykin-device-testing` | `~/.grok/skills/waykin-device-testing` | `.grok/skills/waykin-device-testing` | OK |
| waykin-ar-debug | `/waykin-ar-debug` | `~/.grok/skills/waykin-ar-debug` | `.grok/skills/waykin-ar-debug` | OK |
| waykin-audio | `/waykin-audio` | `~/.grok/skills/waykin-audio` | `.grok/skills/waykin-audio` | OK |
| waykin-healthkit | `/waykin-healthkit` | `~/.grok/skills/waykin-healthkit` | `.grok/skills/waykin-healthkit` | OK |
| waykin-performance | `/waykin-performance` | `~/.grok/skills/waykin-performance` | `.grok/skills/waykin-performance` | OK |
| waykin-pr-review | `/waykin-pr-review` | `~/.grok/skills/waykin-pr-review` | `.grok/skills/waykin-pr-review` | OK |
| waykin-release | `/waykin-release` | `~/.grok/skills/waykin-release` | `.grok/skills/waykin-release` | OK |

Canonical source tree: `skills/` (committed).  
Install copies: `~/.grok/skills` + `.grok/skills` (local; `.grok/` gitignored).

## Dependencies detected

| Tool | Status |
|------|--------|
| swift | FOUND |
| xcodegen | FOUND |
| xcodebuild | FOUND |
| make | FOUND |
| git | FOUND |
| python3 | FOUND |
| gh | FOUND |
| rsync | FOUND |

Optional (performance skill): Instruments — use when available.

## Validation status

| Check | Result |
|-------|--------|
| Frontmatter `name` + `description` | PASS (all 10 × 2 installs) |
| Embedded `references/REPO_CONTEXT.md` | PASS |
| Repo-specific command needles | PASS |
| Grok discovery paths written | PASS |
| Live slash menu | Auto-reload; invoke `/waykin-validate` to confirm in TUI |

## Missing requirements

None for host tooling on this machine. Physical device / outdoor evidence remains human-gated (#41).

## Suggested improvements

1. Add `waykin-persistence` skill when CloudKit/WP-DB6 becomes active.  
2. Wire CI job that runs `skills/install.sh --user-only` dry-check frontmatter only.  
3. Optional: Graphite-specific PR skill once stack workflow is mandatory.  
4. Keep `skills/MANIFEST.toml` baseline SHA updated on pack bumps.

## Reinstall

```bash
cd /path/to/Waykin
./skills/install.sh
```
