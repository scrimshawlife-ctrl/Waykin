# Waykin Agent Operating Contract

## Authority Before Action

Before editing, read:

1. `docs/SOLO_MVP_SCOPE.md`
2. `WAYKIN_SPEC.md`
3. `README.md`
4. `ARCHITECTURE.md`
5. The approved issue and relevant ADRs

When instructions conflict, follow `docs/governance/DOCUMENT_AUTHORITY.md`.

## Scope Rules

- Implement only approved issue acceptance criteria.
- Treat documents marked `FUTURE`, `REFERENCE_ONLY`, or `DEFERRED` as non-authorizing.
- Prefer the smallest coherent patch.
- Extend existing owners rather than creating parallel systems.
- Do not expand product scope incidentally while refactoring.
- Do not add Abraxas runtime dependencies or generalized symbolic infrastructure.

## Architecture Rules

- Keep `WaykinCore` independent from ARKit, RealityKit, SwiftUI, MapKit, SwiftData, and audio filenames.
- Preserve deterministic behavior where it already exists.
- Preserve movement, Bond, persistence, field-receipt, safety, and semantic-audio ownership unless the issue explicitly authorizes a change.
- Presentation and device adapters consume semantic state; they do not own gameplay truth.

## Evidence Rules

Use only:

- `OBSERVED` for directly verified evidence.
- `INFERRED` for evidence-based conclusions.
- `NOT_COMPUTABLE` when evidence is missing.

Never claim physical GPS, device audio, AR tracking, interruption recovery, battery, thermal, or outdoor usability behavior without direct device evidence.

## Required Validation

```bash
make build
make test
make validate
git diff --check
```

Also run:

- `make validate-simulator` for simulator-visible behavior.
- The relevant physical-device protocol for device-dependent behavior.

Report commands, results, changed files, assumptions, and unresolved evidence. Do not report completion while required checks are failing.
