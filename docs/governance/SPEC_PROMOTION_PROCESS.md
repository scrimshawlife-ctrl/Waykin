# Waykin Specification Promotion Process

Future material cannot enter implementation scope directly from a design document or agent prompt.

## Lifecycle

```text
REFERENCE_ONLY
  → proposal issue
  → architecture review
  → ADR when required
  → scope and dependency analysis
  → milestone approval
  → PLANNED
  → implementation issue
  → PARTIAL
  → validation
  → IMPLEMENTED
```

## ADR Required When

A proposal:

- Introduces a module boundary
- Changes data ownership
- Changes persistence format
- Changes deterministic behavior
- Adds a framework dependency to a lower layer
- Promotes a future master-pack capability into approved scope

## Promotion Gate

A capability may be marked `PLANNED` only when the proposal identifies:

- User-visible outcome
- Current authority documents
- Allowed and frozen systems
- Dependencies and migration needs
- Required tests
- Device evidence
- Explicit non-goals
- Solo-developer feasibility

No coding agent may skip this process because future documentation contains schemas, pseudocode, APIs, or module layouts.
