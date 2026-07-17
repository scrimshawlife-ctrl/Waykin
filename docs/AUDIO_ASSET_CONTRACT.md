# Waykin Audio Asset Contract

Waykin's core emits semantic `AudioCue` values. Only the app target maps those values to filenames and playback behavior.

| Semantic cue | Asset basename | Channel | Priority |
|---|---|---|---:|
| `companionNear` | `companion_near` | foreground | 2 |
| `companionAhead` | `companion_ahead` | foreground | 2 |
| `distantFootsteps` | `distant_presence` | foreground | 3 |
| `pursuitPressure` | `pursuit_pressure` | foreground | 4 |
| `pursuitRelease` | `pursuit_release` | foreground | 3 |
| `bondMotif` | `bond_motif` | foreground | 5 |
| `quietShift` | `quiet_shift` | ambient | 1 |

## Format And Sound Guidance

- Bundle local, repository-owned or properly licensed `.wav` files.
- Keep cues nonverbal, short, subtle, and conservatively normalized. A practical target is under two seconds with comfortable headroom and no clipping.
- Design for intermittent presence rather than notification-like urgency. Do not mask environmental awareness.
- The adapter allows at most one foreground cue and one ambient cue. Higher-priority foreground cues replace lower-priority foreground cues.

The current files are deterministic mono 16-bit PCM engineering tones at 22.05 kHz. They prove loading and lifecycle behavior only; they are not production sound design. Regenerate them with `swift scripts/generate_placeholder_audio.swift`.

## Failure And Replacement

Missing or invalid files produce safe silence, one bounded diagnostic per asset name, and no session failure. The adapter does not repeatedly attempt a failed asset during the same app lifetime. Adapter diagnostics may record planner, asset, session, player, route, interruption, and playback-request outcomes, but never prove that a person heard a cue. Stop and fade diagnostics record requests; `playbackStopped` is reserved for an observed player stop.

To replace a cue, preserve its basename and `.wav` extension, verify ownership and licensing, keep duration and loudness within this contract, then run the focused audio tests and full validation suite. Adding cue kinds, channels, remote delivery, streaming, procedural audio, or environment packs is outside this contract and requires a separate scoped decision.
