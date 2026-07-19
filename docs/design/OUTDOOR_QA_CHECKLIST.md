# Outdoor Day / Night QA Checklist

```yaml
document_id: WAYKIN-OUTDOOR-QA-001
version: 0.1
date: 2026-07-19
status: CHECKLIST_ONLY
evidence_class: NOT_COMPUTABLE_UNTIL_DEVICE_WALK
depends_on: [WK_TOKENS_v0.2, Issue_50, Issue_52, Issue_55]
companion_name: Lira
```

This checklist is the Phase 4 outdoor validation protocol. Completing items on a physical device upgrades evidence from `NOT_COMPUTABLE` to `OBSERVED`. Do not claim outdoor contrast or glare performance from simulator alone.

## Preconditions

- [ ] Build from a known `main` SHA: _______________
- [ ] Device model / iOS: _______________
- [ ] Appearance: Auto / Forced Day / Forced Night (note which)
- [ ] Reduced Motion: Off for pass A; On for pass B
- [ ] Location permission granted for real walk path (or Demo Mode for UI-only checks)

## Pass A — Day (outdoor sun or bright shade)

| ID | Check | Pass? | Notes |
| -- | ----- | ----- | ----- |
| D1 | Home: Waykin title + Bond Filament mark readable | | |
| D2 | Home: Begin Walk primary (guide teal) contrast adequate | | |
| D3 | Active: state phrase (title3) glanceable without squinting | | |
| D4 | Active: Pause / End targets ≥48pt, thumb reachable | | |
| D5 | Active: Lira silhouette distinguishable from mist background | | |
| D6 | Bond gold label readable on day mist (uses bondText) | | |
| D7 | Pressure / hunter state readable without color alone (ring + ahead/behind icon + text) | | |
| D8 | Summary warm foundation + closing phrase readable | | |

## Pass B — Night (low light outdoor or dark indoor proxy)

| ID | Check | Pass? | Notes |
| -- | ----- | ----- | ----- |
| N1 | Night indigo-earth not a pure invert of day | | |
| N2 | Primary soft silver text readable on `#12151C` field | | |
| N3 | Guide / bond accents not washed out by OLED glare | | |
| N4 | Pause control still findable under pressure UI | | |
| N5 | Hunter state not alarming (no red-only, no flash) | | |
| N6 | Map chrome does not dominate companion presence | | |

## Pass C — Reduced motion

| ID | Check | Pass? | Notes |
| -- | ----- | ----- | ----- |
| R1 | OS Reduce Motion on: presence does not loop amplify | | |
| R2 | State still legible via static silhouette + labels | | |
| R3 | No full-screen pulse or flash | | |

## Pass D — Hunt / pressure tone

| ID | Check | Pass? | Notes |
| -- | ----- | ----- | ----- |
| H1 | Pressure language is controlled, not panic | | |
| H2 | End remains calm (not destructive red) | | |
| H3 | Safety-relevant: user can stop anytime without failure framing | | |

## Sign-off

```yaml
walker:
device:
build_sha:
day_pass: true | false | partial
night_pass: true | false | partial
reduced_motion_pass: true | false | partial
evidence_class: OBSERVED | PARTIAL | NOT_COMPUTABLE
notes: |
```

## After OBSERVED pass

1. Update `docs/design/ECHO_THEME_IMPORT.md` outdoor_qa field
2. Optionally mark HO-001 outdoor contrast as validated in engineering notes
3. Do **not** set APPROVED_FOR_EXPORT / INTEGRATED without human product owner

## Explicitly still deferred

- Production sculpted Lira mesh
- Dawn / Veil / Rupture skin rebuild on rig
- Store icon marketing screenshots
