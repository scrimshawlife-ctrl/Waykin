# Waykin Documentation Index

This index separates **binding current authority**, **supporting implementation guidance**, **validation evidence**, and **future-state reference material**.

## Start Here

| Document | Authority | Purpose |
|---|---|---|
| [`../WAYKIN_SPEC.md`](../WAYKIN_SPEC.md) | Binding | Current product contract, MVP pillars, non-goals, and evidence rules |
| [`../ARCHITECTURE.md`](../ARCHITECTURE.md) | Binding | Runtime boundaries, dependency direction, and deferred seams |
| [`../AGENTS.md`](../AGENTS.md) | Binding | Operating contract for coding agents and automation |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | Binding | Human collaboration, branches, pull requests, and validation workflow |
| [`governance/DOCUMENT_AUTHORITY.md`](governance/DOCUMENT_AUTHORITY.md) | Binding | Document precedence and maturity classes |

## Current Product and Architecture

| Document | Purpose |
|---|---|
| [`canonical/CURRENT_CAPABILITY_MATRIX.md`](canonical/CURRENT_CAPABILITY_MATRIX.md) | Current implementation, verification state, and deferred surfaces |
| [`SOLO_MVP_SCOPE.md`](SOLO_MVP_SCOPE.md) | Solo-implementable MVP boundary |
| [`../KNOWN_LIMITATIONS.md`](../KNOWN_LIMITATIONS.md) | Validated, partial, deferred, and `NOT_COMPUTABLE` gates |
| [`../DEMO_SCRIPT.md`](../DEMO_SCRIPT.md) | Terminal demo and iOS simulator flows |
| [`AUDIO_ASSET_CONTRACT.md`](AUDIO_ASSET_CONTRACT.md) | Semantic audio-to-asset boundary |

## Validation and Evidence

| Document | Purpose |
|---|---|
| [`PHYSICAL_DEVICE_WALK_VALIDATION.md`](PHYSICAL_DEVICE_WALK_VALIDATION.md) | Manual physical-iPhone walk protocol |
| [`FIELD_TEST_PROTOCOL.md`](FIELD_TEST_PROTOCOL.md) | First-walk evidence gate, receipts, notes, and stop conditions |
| [`assets/screenshots/README.md`](assets/screenshots/README.md) | Distinction between real screenshots and concept visuals |
| [`../WAYKIN_MPOC_IMPLEMENTATION_RECEIPT.md`](../WAYKIN_MPOC_IMPLEMENTATION_RECEIPT.md) | Historical MPOC implementation snapshot |

## Governance and Specification Promotion

| Document | Purpose |
|---|---|
| [`governance/MASTER_PACK_INDEX.md`](governance/MASTER_PACK_INDEX.md) | Classification of the master documentation pack |
| [`governance/SPEC_PROMOTION_PROCESS.md`](governance/SPEC_PROMOTION_PROCESS.md) | Process for promoting future material into implementation authority |
| [`decisions/ADR-0001-document-authority-and-scope.md`](decisions/ADR-0001-document-authority-and-scope.md) | Decision establishing document authority and scope separation |

## Visual Identity

| Document or asset | Purpose |
|---|---|
| [`assets/BRAND_GUIDE.md`](assets/BRAND_GUIDE.md) | Palette, tone, provenance, labeling, and usage rules |
| [`assets/waykin-hero.svg`](assets/waykin-hero.svg) | Current README hero concept visual |

## Evidence Language

Repository claims use the following labels:

- `OBSERVED` — directly verified from code, command output, or physical evidence.
- `INFERRED` — derived from observed evidence and identified as inference.
- `NOT_COMPUTABLE` — required evidence is unavailable.

Validation language may also use `VALIDATED`, `IMPLEMENTED_UNVERIFIED`, and `DEFERRED` where defined by the relevant document.

## Maintenance Rules

1. Run `make validate` before updating build or test claims.
2. Run `make validate-simulator` before updating simulator UI claims.
3. Require direct device evidence before updating GPS, device audio, battery, outdoor usability, or AR claims.
4. Treat dated validation results as evidence for the tested commit and environment, not permanent guarantees.
5. Do not treat future-state or master-pack material as approved implementation scope without completing the specification-promotion process.
6. Label concept visuals and engineering diagrams explicitly; they are not proof of implemented product behavior.
