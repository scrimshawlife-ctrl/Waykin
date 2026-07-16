# Waykin Architecture (MPOC)

See the directive for canonical layers.

Core boundaries:
- MovementEngine consumes providers, emits snapshots
- Experiences are pure: input snapshot + context → update + commands
- CompanionRuntime interprets commands (presentation neutral)
- MemoryEngine is deterministic first

All engines are dependency-injected and testable.

Presentation adapters (Map, Audio, AR) consume ExperienceUpdate and CompanionRuntime state.

## Data Flow (Proven in Demo)
Choose activity + experience → start session → simulate/update loop → finish → memory → updated companion → new recommendation

## Future
Add real LocationProvider, SwiftData persistence, RealityKit adapter.