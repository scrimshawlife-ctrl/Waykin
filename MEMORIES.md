# Bug-finding memories

- `App/WaykinApp.swift` `endDemo`: non-idempotent End finalizes live field-test receipt as `.invalidState` while persist pending; unordered persist tasks can regress bond — https://github.com/scrimshawlife-ctrl/Waykin/pull/235 — status: open — 2026-07-25
