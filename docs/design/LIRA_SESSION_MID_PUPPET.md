# Lira Session-Mid Puppet (Issue #59)

```yaml
issue: 59
status: IN_APP_PRESENTATION
lod: session_mid
anchors: [A1_head, A2_chest_bond, A3_filament]
skins: [Dawn_via_Echo_tokens]
production_sculpted_mesh: false
```

## What shipped

| Item | Path |
| ---- | ---- |
| Pose resolver | `App/Theme/LiraSessionPose.swift` |
| Multi-pose figure | `App/Theme/LiraSessionFigure.swift` |
| Presence wiring | `CompanionPresenceView` → `LiraSessionFigure` |
| Tests | `AppTests/LiraSessionPoseTests.swift` |

## Poses

| Pose | Trigger (priority) |
| ---- | ------------------ |
| Manifesting | Opening session |
| Hunter | Pursuit approaching / close |
| Rival | Pursuit noticed (non-bond) |
| Sanctuary | Pursuit fading or rest behavior |
| Bond | Bond event / celebrate / drawNear |
| Dormant | Quiet interval or paused idle |
| Guide | Lead / follow / default |

## Hunter rules (enforced in figure)

- Delayed dashed echo silhouette
- Cool hunter filament
- Lower crouch
- No gore / teeth / red-only

## Next art steps

1. Replace Canvas puppet with exported stills/atlas from true rig when ready
2. Dawn material polish; Veil/Rupture later
3. Outdoor receipt after device walk
