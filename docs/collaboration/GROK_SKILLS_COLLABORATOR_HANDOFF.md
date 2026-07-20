# Grok skills — collaborator handoff (Prabu & team)

```yaml
document_id: WAYKIN-GROK-SKILLS-HANDOFF
audience: prabu-openclaw and all write collaborators
status: CURRENT
main_tip_at_write: 2246b20+
```

## For Prabu (`prabu-openclaw`)

You already have **write** access on `scrimshawlife-ctrl/Waykin`. Skills are **in the repo** — not only on Daniel’s laptop.

### One-time / after each pull

```bash
git clone https://github.com/scrimshawlife-ctrl/Waykin.git   # if needed
cd Waykin
git checkout main
git pull --ff-only origin main

# Open Grok Build with workspace = this directory (repo root)
```

Grok discovers:

`.grok/skills/waykin-*`  ← **tracked in git**

Optional personal copy (skills work even if CWD is not Waykin):

```bash
./skills/install.sh --user-only
./skills/install.sh --check
# or
make install-skills
make check-skills
```

### Slash commands

| Command | Use when |
|---------|----------|
| `/waykin-validate` | Before PR; full engineering report |
| `/waykin-build` | Build/sim failures |
| `/waykin-pr-review` | Review a PR (PASS / REQUEST CHANGES) |
| `/waykin-ui-review` | SwiftUI / a11y vs product UI law |
| `/waykin-ar-debug` | AR plant / continuity / LOD |
| `/waykin-device-testing` | Device / outdoor readiness |
| `/waykin-audio` | Cues silent / routing |
| `/waykin-healthkit` | Optional HK enrichment |
| `/waykin-performance` | Jank / thrash prioritization |
| `/waykin-release` | RC checklist |

### Rules that still apply

- Issue-based work; `AGENTS.md` + `DOCUMENT_AUTHORITY`
- No outdoor PASS without #41 device evidence
- Skills **call** `make validate` / `scripts/*` — they do not replace them

### Docs

- [`skills/README.md`](../../skills/README.md)
- [`REMOTE_COLLABORATOR_GUIDE.md`](REMOTE_COLLABORATOR_GUIDE.md) (setup section)
- Source pack: `skills/` · discovery: `.grok/skills/`

### If skills don’t show in Grok

1. Confirm CWD is the **Waykin repo root** (not a parent folder).
2. `ls .grok/skills/waykin-validate/SKILL.md`
3. `./skills/install.sh --user-only` then restart Grok
4. Ask in team chat with `git rev-parse --short HEAD` output

---

## Indoor AR hybrid smoke (team next device task)

When a phone is available **indoors** (not outdoor #41):

1. `bash scripts/indoor_ar_smoke_prep.sh`
2. Follow [`docs/design/INDOOR_AR_HYBRID_SMOKE.md`](../design/INDOOR_AR_HYBRID_SMOKE.md)
3. Fill the PENDING receipt under `docs/design/receipts/`
4. Open a small docs PR with OBSERVED rows

Outdoor COH remains issue **#41** only.
