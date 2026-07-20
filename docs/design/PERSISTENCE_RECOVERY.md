# Persistence recovery (support-safe)

```yaml
document_id: WAYKIN-PERSISTENCE-RECOVERY-001
status: IMPLEMENTED_WP_DB5
scope: local SwiftData store only
cloud: out_of_scope
```

## Principles

1. **Never silently delete** Application Support `Waykin.store` (or sidecars).
2. **Quarantine** moves unreadable data aside so a fresh store can open.
3. **Field-test receipts** live in a separate directory and are not touched by store recovery.
4. Recovery does **not** restore Bond/memories from quarantine automatically — that is a manual/support step if needed.

## Store locations

| Artifact | Path (typical) |
| -------- | -------------- |
| SwiftData store | `Application Support/Waykin/Waykin.store` |
| Quarantine | `Application Support/Waykin/StoreQuarantine/Waykin.store.<unix>/` |
| Field-test receipts | `Application Support/Waykin/FieldTestReceipts/` |

## Operator steps (device)

1. Note the app is degraded (`DEGRADED_IN_MEMORY` / persistence failed) or crashes on launch.
2. Pull the app container via Xcode if investigating.
3. **Do not** delete `Waykin.store` by hand unless a copy exists.
4. Prefer API / engineering path: `PersistenceRecovery.diagnose` → if `presentUnopenable`, `quarantineStore` or `openFreshAfterQuarantine`.
5. After quarantine, relaunch: app opens a **new empty** durable store; Bond resets to default until user walks again.
6. Quarantined folder can be archived for engineering diagnosis (privacy: may contain bond/memory text — treat as personal data).

## App behavior (OBSERVED in code)

| Event | Behavior |
| ----- | -------- |
| File-backed open succeeds | `PersistenceAvailability.availableFileBacked` |
| File-backed open fails | Degraded **in-memory** substitute; does not claim file durability |
| Quarantine + reopen | Fresh empty file-backed store; prior bytes in `StoreQuarantine/` |

## Explicit non-goals

- Automatic silent wipe of user data
- CloudKit restore (WP-DB6 / separate ADR)
- Reconstructing sessions from field-test receipt JSON into SwiftData

## Related

- [PERSISTENCE_ARCHITECTURE.md](PERSISTENCE_ARCHITECTURE.md)
- [PERSISTENCE_HARDENING_PLAN.md](../plans/PERSISTENCE_HARDENING_PLAN.md)
- ADR-0003 local-first SwiftData
