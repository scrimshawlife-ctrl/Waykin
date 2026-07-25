# Audio cue assets

Semantic `AudioCue`s (Core) → WAV basenames (App catalog in
`App/AppAudioCuePlayer.swift`). One coherent Lira leitmotif family; generation
briefs and per-cue prompts live in `docs/design/LIRA_AUDIO_CUE_FAMILY.md`.

Format for every file: **48 kHz / 16-bit / stereo PCM WAV**. Master all cues to
a common reference loudness (≈ −18 LUFS, true-peak ≤ −3 dBTP); the per-cue
`volume` in the catalog is the single source of relative balance — do **not**
bake level differences into the files.

## Walk cues (shipped audio)

`companion_near` · `companion_ahead` · `distant_presence` · `pursuit_pressure`
· `pursuit_release` · `bond_motif` · `quiet_shift`

## Lifecycle "moment" cues — PLACEHOLDERS

These four ship as **silent placeholders** at the intended durations so the
bundle validates and the app never crashes on a missing asset. Replace each in
place (same filename) with the real audio from the brief; no code changes
needed.

| File | Moment | Placeholder dur |
|---|---|---|
| `lira_launch_theme.wav` | app open — full Lira theme | 9.0 s |
| `lira_companion_reveal.wav` | end of onboarding — first reveal | 1.5 s |
| `lira_spawn_theme.wav` | companion materialize / session start | 2.5 s |
| `lira_bond_milestone.wav` | session summary when bond grew | 2.0 s |

A missing or silent asset degrades to no sound (diagnosed, never fatal), so the
code is safe to ship ahead of the sound pass.
