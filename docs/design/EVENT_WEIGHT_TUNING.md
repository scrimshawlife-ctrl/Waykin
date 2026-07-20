# Event Weight Light Tune

```yaml
document_id: WAYKIN-EVENT-WEIGHT-001
version: 1.1
status: IMPLEMENTED
scope: WorldEventGeneratorConfiguration.defaultRules only
```

## Goals

Companion-first pacing for real Companion Walk generation:

1. Lira presence cues win more often when eligible.
2. Pursuit entry is rarer and requires more pressure/energy.
3. Bond / familiar place become available slightly earlier.
4. Global spacing stays sparse (`minimumTickSpacing` = 40s).

Demo Mode schedules its own arc and **does not** use these weights for selection.

## Defaults (v1.1)

| Kind | Weight | Cooldown (s) | Notable thresholds |
| ---- | -----: | -----------: | ------------------ |
| quietInterval | 3 | 28 | max pressure 0.25 |
| companionDrawsNear | 7 | 24 | min energy 0.05 |
| companionMovesAhead | 4 | 30 | min energy 0.40 |
| companionObserves | 4 | 22 | min pressure 0.04 |
| distantPresence | 3 | 44 | min pressure 0.24 |
| pursuitBegins | 2 | 70 | min energy 0.28, min pressure 0.36 |
| pursuitIntensifies | 3 | 48 | min pressure 0.55 |
| pursuitFades | 3 | 38 | min energy 0.50 |
| familiarPlaceStirs | 3 | 50 | min familiarity 0.30 |
| bondMoment | 3 | 60 | min bond 8, min energy 0.20 |

## Invariants (tested)

- Rules cover exactly the bounded `WorldEventKind` set.
- Combined companion presence weight > distantPresence + pursuitBegins.
- `pursuitBegins` cooldown and min pressure > `companionDrawsNear`.
- Frequency fixture ≤ 8 events over 30 ticks × 10s.
- Seeded evaluation remains deterministic.

## Non-goals

- New event kinds or narrative graphs
- Per-user remote config
- Outdoor-calibrated absolute rates (await device receipts)
