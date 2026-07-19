# Outdoor Day/Night QA Checklist (Echo, Phase 4 step 3)

Companion to Issue #41's device protocol. Every item below is
**NOT_COMPUTABLE** until executed on a physical device outdoors — nothing
here may be marked from simulator evidence. Record results per item as
OBSERVED (with device, conditions, time of day) or leave NOT_COMPUTABLE.

## Conditions matrix

Run each section in as many of these as possible:

- [ ] Direct midday sun
- [ ] Overcast day
- [ ] Golden hour / low sun
- [ ] Dusk (night palette threshold)
- [ ] Full night (street lighting)

## Day palette (cool mist)

- [ ] Session background (`E4E8EC` wash) does not wash out under direct sun
- [ ] Primary text (`141820`) readable at arm's length while walking
- [ ] Bond gold (`D4A45A`) distinguishable from caution (`E0B040`) at a glance
- [ ] Pressure ring visible at rest (hunterFilament `7B8C9E` @ 0.22) — if not,
      confirm the *thickness* change still reads when pressure rises
- [ ] Guide teal (`3F8F8A`) presence silhouette reads as figure + head, not a blob

## Night palette (indigo-earth)

- [ ] Night background (`12151C`) does not smear under AMOLED at low brightness
- [ ] Primary text (`E6EAF0`) readable without glare halos
- [ ] Non-inverted night confirmed: surfaces feel warm-dark, not negative-image
- [ ] Pressure ring visible against night background at rest and under pressure
- [ ] Auto light/dark switch at dusk does not produce an unreadable in-between

## Lira presence & AR (Living Familiar anchors)

- [ ] Session silhouette reads as Lira (body + A1 head + A2 bond core +
      A3 filament) at a glance while walking
- [ ] AR placeholder: head/snout facing readable from 2–4 m
- [ ] A2 chest bond core (gold) visible in sunlight and at night
- [ ] A3 filament beads visible but not distracting
- [ ] App icon recognizable on the home screen in sun and at night

## Reduced Motion

- [ ] With Reduce Motion ON: presence is static; state changes still
      perceptible via scale/text/ring thickness outdoors
- [ ] Toggling Reduce Motion mid-session produces no stuck animation
- [ ] Celebrate still visibly completes (state change without pulse)

## Accessibility outdoors

- [ ] VoiceOver traversal usable with device in sunlight (screen-curtain walk)
- [ ] Largest Dynamic Type: controls reachable one-handed while walking
- [ ] Pause / Resume / End hit targets workable with the device held low

## Evidence record

| Item | Result | Device | Conditions | Date | Notes |
|---|---|---|---|---|---|
| (fill per walk) | NOT_COMPUTABLE | | | | |
