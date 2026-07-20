# Waykin Audio Asset Contract

Waykin's core emits semantic `AudioCue` values. Only the app target maps those values to filenames and playback behavior.

## Emission contract (#130)

1. **World-event cues (primary):** when `WorldEventGenerator` fires, `AudioExperienceLayer.map(event:)` emits the matching cue.
2. **Behavior-transition cues (coupling):** when no world event fires, a change in companion-visible behavior (`drawNear` / `lead` / `rest` / `observe` / `celebrate`) may emit a cue via `AudioExperienceLayer.map(behavior:)` onto the **same** produced basenames. Cooldown: 12 s session elapsed. First behavior seed is silent.
3. **Not coupled:** AR skeletal motion, filament bob, continuous footsteps, or camera-relative pose loops.
4. **Gain:** catalog volumes are outdoor-aware (~0.30–0.45). Physical outdoor loudness remains **NOT_COMPUTABLE** without device re-walk evidence.

| Semantic cue | Asset basename | Channel | Priority | Catalog volume |
|---|---|---|---:|---:|
| `companionNear` | `companion_near` | foreground | 2 | 0.40 |
| `companionAhead` | `companion_ahead` | foreground | 2 | 0.40 |
| `distantFootsteps` | `distant_presence` | foreground | 3 | 0.36 |
| `pursuitPressure` | `pursuit_pressure` | foreground | 4 | 0.45 |
| `pursuitRelease` | `pursuit_release` | foreground | 3 | 0.36 |
| `bondMotif` | `bond_motif` | foreground | 5 | 0.42 |
| `quietShift` | `quiet_shift` | ambient | 1 | 0.30 |

## Format And Sound Guidance

- Bundle local, repository-owned or properly licensed `.wav` files.
- Prefer nonverbal, subtle cues with comfortable headroom and no clipping.
- **Soft duration guidance:** foreground cues ideally ≤ ~2 s; ambient beds may run slightly longer (current `quiet_shift` ≈ 3 s is accepted). Bond motif may run slightly longer for cadence (current `bond_motif` ≈ 2.76 s is accepted).
- Design for intermittent presence rather than notification-like urgency. Do not mask environmental awareness.
- The adapter allows at most one foreground cue and one ambient cue. Higher-priority foreground cues replace lower-priority foreground cues.

## Current assets (production cues)

Produced sound-design WAVs (owner-rendered 2026-07-19), first-party licensing:

- Format: stereo 48 kHz 16-bit PCM (adapter is basename-based; mono 22.05 kHz is not required).
- Engineering placeholder tones (mono 22.05 kHz) are obsolete; regenerate only for local sandbox work via `swift scripts/generate_placeholder_audio.swift`.
- Physical audibility, outdoor masking, and loudness balance remain **NOT_COMPUTABLE** without device evidence.

## Failure And Replacement

Missing or invalid files produce safe silence, one bounded diagnostic per asset name, and no session failure. The adapter does not repeatedly attempt a failed asset during the same app lifetime. Adapter diagnostics may record planner, asset, session, player, route, interruption, and playback-request outcomes, but never prove that a person heard a cue. Stop and fade diagnostics record requests; `playbackStopped` is reserved for an observed player stop.

To replace a cue, preserve its basename and `.wav` extension, verify ownership and licensing, keep duration and loudness within this contract, then run the focused audio tests and full validation suite. Adding cue kinds, channels, remote delivery, streaming, procedural audio, or environment packs is outside this contract and requires a separate scoped decision.
