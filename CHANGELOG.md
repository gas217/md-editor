# Changelog

All notable changes to MD Editor will be documented in this file. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Story 0a (in progress): `preview-md-shared` Swift package extraction begun
- Story 0c (in progress): `TextCanon.swift` canonicalization module (LF, NFC, UTF-16, SHA-256)

## [0.1.0] — 2026-05-24

Initial scaffold. Not a release — repository structure only.

### Added

- Complete `VISION.md` (12-section product vision, ~700 lines, scored 9.4/10 by adversarial product reviewer and 8.7/10 by principal engineer reviewer)
- `METRICS.md` defining the 12-dimensional build-readiness + production-readiness rubric
- `PRODUCTION-READINESS.md` checklist
- `feature-inventory.yml` mapping VISION.md features to required artifacts
- `scripts/score.sh` automated scorer (emits `score.json`, appends to `score-history.jsonl`)
- Project scaffolding: `App/`, `Editor/`, `Bridge/`, `Comments/`, `Sidebar/`, `Preview/`, `Tests/`
- `project.yml` (XcodeGen spec), `Makefile`, `Editor/web/` (CM6 + esbuild pipeline)
- Sibling Swift package: `preview-md-shared/` (5 source files + `Package.swift`)
- 28 stub test files covering V1.0 + V1.1 acceptance criteria
- `.github/workflows/ci.yml`, issue templates, PR template
- `README.md`, `CONTRIBUTING.md`, `LICENSE` (MIT), `.gitignore`
- `PRIVACY.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`

### Not yet

- Any V1.0 acceptance criterion passes — they all `XCTFail("not yet implemented")` by design
- `make build` produces a binary (depends on Story 0a)
- Signed/notarized releases

[Unreleased]: https://github.com/gas217/md-editor/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/gas217/md-editor/releases/tag/v0.1.0
