# Simulator screenshots

```yaml
evidence_class: SIMULATOR
git_sha: 5619244
date_utc: 20260720T084445Z
device: iPhone 17
bundle: com.waykin.WaykinApp
full_matrix: 1
issue: 194
```

## Files

| File | Intended screen |
| ---- | --------------- |
| 01_home_day.png | Home (day) |
| 02_session_day.png | Active Session Demo (day) |
| 03_summary_day.png | Session Summary (day) |
| 04_home_night.png | Home (night) |
| 05_session_night.png | Active Session Demo (night) |
| 06_summary_night.png | Session Summary (night) |


## Claims

- **OBSERVED in simulator only.**
- Not outdoor glare, GPS, physical AR, battery, or headphone evidence.
- Night frames use app appearance force and/or sim dark mode — not outdoor night.

## Reproduce

```bash
# Home day/night only
./scripts/capture_sim_screenshots.sh "iPhone 17"

# Full walk surfaces
WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh "iPhone 17"
```
