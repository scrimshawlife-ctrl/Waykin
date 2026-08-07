# Changelog

All notable changes to **Waykin** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Version artifacts: `VERSION`, `BUILD`, `App/Info.plist`, `project.yml` — see [docs/VERSIONING.md](docs/VERSIONING.md).

## [Unreleased]

### Added

- Semantic versioning scaffolding (`VERSION`, `BUILD`, `Tools/version.py`) with parity checks across Info.plist and `project.yml`.
- App-product process docs: `CHANGELOG.md`, `docs/VERSIONING.md`, `docs/TESTING.md`, `docs/SHIP_CHECKLIST.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`.

### Changed

- LICENSE is **proprietary** (Zero State / Zero State LLC); Apache-2.0 no longer applies to the current tree.
- README clone/badge paths point at the Zero-State-LLC org remote where applicable.
- Phase 0 product identity: AR-designed primary surface with movement as gameplay authority (see `WAYKIN_SPEC.md`, `docs/SOLO_MVP_SCOPE.md`).

## [0.9.0] - 2026-07-25

### Added

- Internal TestFlight cut baseline (marketing `0.9.0`, build `2`).
- Ember Fox companion packaging and AR placement path (#246).
- HealthKit read enrichment hardening (#104).
- Evidence-gated roadmap, capability matrix, and AR redesign reference docs.

### Notes

- Physical outdoor GPS/AR evidence for #41 remains open.
- Demo Mode and package tests remain the CI-authoritative loop.

---

[Unreleased]: https://github.com/Zero-State-LLC/Waykin/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/Zero-State-LLC/Waykin/releases/tag/v0.9.0
