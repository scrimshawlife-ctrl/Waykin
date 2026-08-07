# Security Policy

Waykin is a **proprietary** product owned by **Zero State / Zero State LLC**.

## Scope

- Local session state, Bond, and concise session memories (on-device)
- Optional HealthKit enrichment (read)
- Location **only** during an active real walk (When-In-Use)
- Camera for AR session presentation when enabled
- Privacy-filtered local field-test receipts (no automatic upload)
- No accounts / backend in the current MVP

## Reporting a vulnerability

**Do not** open a public GitHub issue for security-sensitive findings.

Report privately to the **repository owner / Zero State** with:

- clear reproduction steps
- device and OS version (or CI context)
- impacted path, dependency, or entitlement
- severity assessment

Do not disclose publicly until a fix ships or the owner approves disclosure.

## Engineering rules

- No credentials, API keys, or provisioning profiles in source control.
- Field receipts must remain privacy-filtered (no coordinates / personal memory text in retained artifacts per product rules).
- `WaykinCore` must not become a network client without an explicit architecture promotion.
- Third-party SDK introductions require privacy-label and threat-model updates in `docs/legal/`.

## Data handling

- No login required for core play.
- Demo Mode requires no location or Health access.
- See [docs/legal/PRIVACY.md](docs/legal/PRIVACY.md) and [docs/legal/SAFETY.md](docs/legal/SAFETY.md).

## Related

- [LICENSE](LICENSE) — proprietary ownership  
- [CONTRIBUTING.md](CONTRIBUTING.md)  
