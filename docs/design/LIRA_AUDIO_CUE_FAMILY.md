# Lira Audio Cue Family — leitmotif spec

Draft spec for regenerating the seven produced cue WAVs as **one coherent
sound identity**, built from a single Lira leitmotif, so the audio matches the
six DCC animation clips end-to-end (#229) and the AR-presentation → cue mapping
(#230).

> Status: **draft for review** (prabu). No code or asset changes yet — this is
> the generation brief a sound pass would execute against. Ground truth pulled
> from `App/AppAudioCuePlayer.swift` (catalog) and `App/Resources/Audio/*.wav`.

---

## 1. The Lira leitmotif (the DNA)

Every cue is a transformation of one 4-note signature. Locking the pitches makes
the family recognizably "Lira" the way a character theme recurs across a score.

- **Motif:** scale degrees **5 – 6 – 1̂ – 2** rising, in **D major pentatonic**
  (concert **A4 – B4 – D5 – E5**), on a **glass/bell/mallet** timbre with a soft
  attack and a long, airy tail.
- **Character:** bright, hopeful, *unresolved* (it lands on the 2, not the
  tonic) — it feels like a companion looking up, waiting for you.
- **Resolution tag:** dropping the last note to the tonic (**…D5**) is the
  "bonded / at rest" resolution. Reserve it for `bond_motif` and
  `pursuit_release` so resolution always *means* something.
- **Tension transform:** same intervals, **minor pentatonic**, down a fifth,
  faster attack, slight detune — this is the "something's coming" version used
  for pursuit.

This motif is also the seed for the app-load theme discussed separately — the
theme *introduces* it, the cues *reference* it.

---

## 2. Ground-truth catalog (what we're regenerating)

Do **not** rename files, change count, or alter durations — the resolver
(`AppAudioCuePlayer`) and tests key off these exact basenames, and the
per-cue catalog volume is the single source of relative balance. Master every
cue to the **same reference loudness** and let the `volume` column do the mix.

| Cue kind | File (`App/Resources/Audio/`) | Dur | Ch | Prio | Vol | Presentation state (#230) |
|---|---|---:|---|---:|---:|---|
| `bondMotif` | `bond_motif.wav` | 2.76 s | fg | 5 | 0.42 | **celebrate** |
| `pursuitPressure` | `pursuit_pressure.wav` | 1.76 s | fg | 4 | 0.45 | **alert** |
| `quietShift` | `quiet_shift.wav` | 3.00 s | amb | 1 | 0.30 | **investigate** |
| `companionAhead` | `companion_ahead.wav` | 1.28 s | fg | 2 | 0.40 | follow / lead |
| `companionNear` | `companion_near.wav` | 1.08 s | fg | 2 | 0.40 | (world-event: near) |
| `distantFootsteps` | `distant_presence.wav` | 2.00 s | fg | 3 | 0.36 | (approach) |
| `pursuitRelease` | `pursuit_release.wav` | 1.60 s | fg | 3 | 0.36 | (recovered) |

Master target: **48 kHz / 16-bit / stereo**, integrated **≈ −18 LUFS**,
true-peak **≤ −3 dBTP**, no cue longer than the duration above (trim tails so
overlapping cues don't smear). All outdoor-aware and quiet by design.

---

## 3. Per-cue generation briefs

Each brief = how the motif is transformed + a generator prompt. Keep them
instrumental and dry-ish; the app owns spatialization and gain.

### `bond_motif` — celebrate (the payoff)
- **Transform:** full motif, **major**, warm, *resolved to the tonic*. One
  gentle upward octave doubling on the last note. This is the only truly
  "happy" cue — earn it.
- **Prompt:** `Warm celebratory chime, 2.5s. Glass-bell mallet plays a rising
  4-note pentatonic motif (A–B–D–E) resolving up to D, doubled an octave with a
  soft marimba. Brief airy shimmer tail. Hopeful, intimate, major. No drums.
  Dry-ish, small room. 48kHz stereo.`

### `pursuit_pressure` — alert (tension)
- **Transform:** motif in **minor pentatonic, down a fifth**, faster attack,
  slight detune/tremolo, low sustained drone underneath. Spatial bias is
  *behind* the listener in-app — leave headroom for that.
- **Prompt:** `Tense low chime pulse, 1.7s. Same 4-note motif but minor and
  lower, muted metallic mallet with a faint detuned shadow, a low sub drone
  swelling underneath. Watchful, "something is close." No melody resolution.
  Dry, focused. 48kHz stereo.`

### `quiet_shift` — investigate (curiosity, ambient)
- **Transform:** a **single fragment** of the motif — just the 6→1̂ interval —
  soft, high, one hit with a long reverb bloom. Ambient channel, lowest volume.
- **Prompt:** `Soft curious ambient tone, 3s. One high glass-bell note (B up to
  D) with a long airy reverb tail, faint breath of wind texture underneath.
  Gentle, questioning, unresolved, very quiet. No rhythm. 48kHz stereo.`

### `companion_ahead` — follow / lead
- **Transform:** motif **fragment (5→6→1̂)**, mid register, with a subtle
  left→right movement and a soft footstep-adjacent pulse implying forward
  travel. Bright but not a full statement (follow is high-frequency; keep it
  small).
- **Prompt:** `Short forward-motion chime, 1.3s. Three-note rising bell figure
  (A–B–D), gentle, with a soft implied step pulse and a light stereo drift left
  to right. "This way." Warm, brief, unresolved. 48kHz stereo.`

### `companion_near` — proximity (world event)
- **Transform:** motif **fragment (1̂→2)**, close and intimate, minimal tail,
  slightly warmer/rounder timbre (felt mallet). The "right beside you" cue.
- **Prompt:** `Intimate close chime, 1s. Two soft rounded bell notes (D to E),
  warm felt-mallet timbre, minimal reverb, present and close. Reassuring, tiny.
  No tail. 48kHz stereo.`

### `distant_presence` — approach (world event)
- **Transform:** full motif but **very reverberant, low-passed, distant**, slow
  attack — the same identity heard from far off.
- **Prompt:** `Distant reverberant chime, 2s. The 4-note pentatonic motif heard
  far away — heavily low-passed, long hall reverb, slow soft attack, faint.
  Mysterious, approaching, spacious. 48kHz stereo.`

### `pursuit_release` — recovered (tension resolves)
- **Transform:** the **tension version relaxing back to major** and *resolving
  to the tonic* — the detune drifts back into tune, drone fades. Pair it
  sonically with `pursuit_pressure` so release always answers pressure.
- **Prompt:** `Tension-release chime, 1.6s. A low detuned metallic tone drifts
  back into tune and rises to a clean resolved major bell chord (settling on D),
  low drone fading out. Relief, exhale, resolved. 48kHz stereo.`

---

## 4. Spawn — the Lira theme (approved, follow-up PR)

The **Spawn** clip (crouch → unfold → shake → settle) has **no audio cue**.
`spawn` isn't in the AR-presentation vocabulary — it's a one-shot
materialization, not a steady presentation state — so #230 never maps it.

**Decision (prabu):** the spawn cue **is the Lira theme itself** — when she
materializes, you hear her full signature. This is the one place the complete,
resolved leitmotif plays; every other cue is a fragment or transform of it. It
also ties spawn to the app-load theme: both state the full theme, so
encountering Lira always sounds like *her*.

This is a **code change, not just an asset**:

1. new `AudioCueKind.spawnTheme` + `lira_spawn_theme.wav` in the catalog,
2. a one-shot trigger when the companion materializes (not a transition cue —
   it fires once on spawn, outside the presentation-transition cooldown logic).

**Spawn brief:** the full theme *assembling from nothing*, mirroring the
crouch→unfold animation — scattered partials coalescing into the complete
resolved motif.
- **Prompt:** `Companion materialize theme, 2.5s. Scattered soft bell partials
  swirl and coalesce from silence into the full resolved Lira motif
  (A–B–D–E rising, resolving up to D), octave-doubled with a warm marimba and an
  airy synth bloom underneath. Magical arrival, hopeful, bright, resolved. No
  drums. 48kHz stereo.` (This is the same theme statement as the app-load
  cue — master one, derive the other by trimming the intro.)

Build this **after** the seven-cue family lands, as its own small PR, so the
asset pass and the code change review separately.

---

## 5. Suggested rollout

1. Regenerate the 7 WAVs to this brief; keep names/durations; master to the
   common −18 LUFS reference. Drop-in replacement — no code touched.
2. Verify: `make validate` + `AppAudioCuePlayerTests` (catalog integrity) stay
   green; the #230 mapping tests are unaffected (kinds unchanged).
3. Follow-up PR: spawn = Lira theme (new `spawnTheme` kind +
   `lira_spawn_theme.wav` + one-shot materialize trigger).
