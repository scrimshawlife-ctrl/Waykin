---
name: waykin-audio
description: >
  Inspect Waykin semantic audio pipeline: AudioExperienceLayer, AppAudioCuePlayer,
  AVAudioSession routing, field-test audio diagnostics. Use when /waykin-audio,
  cue silent, route change, interruption, or audio assets.
metadata:
  short-description: "Waykin semantic audio debug"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-audio

Waykin is **audio-first**. Semantic cues are Core; filenames and AVAudioSession are App.

## 0. Ownership

| Layer | Location | Owns |
|-------|----------|------|
| Semantic cue kinds | `Sources/WaykinCore/Engines/AudioExperienceLayer.swift` | What cue, intensity, cooldown groups |
| Path soft cues | `PathAudioCoupling` / path engine | path:strained etc. |
| Playback | `App/AppAudioCuePlayer.swift` | AVAudioSession, assets, diagnostics |
| Contract | `docs/AUDIO_ASSET_CONTRACT.md` | Asset mapping |
| Placeholder gen | `scripts/generate_placeholder_audio.swift` | Dev assets only |
| Receipts | `FieldTestAudioDiagnosticSummary` | Software-stage only |

**No audio filenames in WaykinCore.**

ElevenLabs / voice pipelines: only if assets/docs in repo explicitly reference them; do not invent cloud voice unless present.

## 1. Inspect pipeline

```bash
cd "$(git rev-parse --show-toplevel)"
rg -n 'AudioCue|AudioExperienceLayer|AppAudioCuePlayer|AVAudioSession' \
  Sources/WaykinCore App --glob '*.swift' | head -80
ls App/Resources/Audio/ 2>/dev/null || ls App/Resources/**/*.wav 2>/dev/null | head
```

## 2. Runtime debug

- Operator strip: last audio cue kind
- Console: `WaykinLog.audio` / category `audio`
- Receipt: `semanticAudioCueCounts`, `audioSuppressionCount`, `audioDiagnostics` (route category enums only — no device names)
- Demo Mode must work **without** special audio hardware

## 3. Checklist

- [ ] Cue selection deterministic for demo seed
- [ ] Planner suppressions recorded (not silent drop without diagnostic)
- [ ] Session category / mix-with-others policy matches product (walking outdoor)
- [ ] Interruption begin/end → resume disposition honest
- [ ] Background: real walk pauses when inactive (product law) — do not claim background audio play without evidence
- [ ] Missing asset → diagnostic `assetMissing`, not crash
- [ ] Spatial bias is semantic (left/center/behind), not full Ambisonics unless implemented

## 4. Latency / mixing

Measure only with device tools if user requests; otherwise:

- Prefer OBSERVED software timestamps in diagnostics
- Physical latency / headphone route = `NOT_COMPUTABLE` without device notes

## 5. Report

```markdown
## Waykin audio report
- SHA:
- Core cue path healthy: Y/N
- App player issues:
- Asset gaps:
- Receipt diagnostics present: Y/N
- Recommendations (file:line):
- Claims requiring device:
```