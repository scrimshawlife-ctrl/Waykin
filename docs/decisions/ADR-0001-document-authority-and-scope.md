# ADR-0001: Document Authority and Scope Separation

- Status: Accepted
- Date: 2026-07-18

## Context

Waykin has a narrow live MVP and a broad master documentation pack containing current, near-term, and future-state designs. Without an authority model, humans and coding agents can mistake detailed future specifications for approved implementation scope.

## Decision

Waykin will use explicit document precedence, maturity classes, and a promotion process. The current solo MVP remains authoritative. Master-pack future material is retained as `REFERENCE_ONLY` until promoted through issue, architecture review, ADR when required, milestone approval, implementation, and validation.

## Consequences

- Agents can use future material to preserve seams but cannot build it without approval.
- Current scope remains small and solo-developer feasible.
- Broader capabilities require explicit architectural and product decisions.
- Documentation conflicts resolve toward the narrower current contract.
