# Contributing to MD Editor

Thanks for the interest. Quick principles, then process.

## Principles (the parts you can't argue with)

Read [VISION.md](VISION.md) first. The non-goals are load-bearing:

- **No plugin system, ever.** Not in V1, not in V5.
- **No first-party AI chat panel / sidebar / inline LLM cursor.** The comment schema is the API; Claude Code is the client.
- **Lightweight is not negotiable.** Cold launch <500 ms, idle RSS <80 MB. A feature that breaks the speed budgets in *Success Metrics* doesn't ship.
- **No structured editing for non-markdown formats in V1.** CSV/JSON/HTML edits go through source mode.
- **No sync, no cloud, no account.** Plain files; iCloud Drive / Dropbox / git handle distribution.

If your contribution wants to violate one of these, open a discussion first — we'll either say "this is V2+", "this is a different product", or (rarely) revise the principle.

## Getting started

```bash
git clone https://github.com/gas217/md-editor
cd md-editor
brew install xcodegen
make project
make build
make score   # see what's missing from V1.0 build-readiness
```

The scoring rubric in [METRICS.md](METRICS.md) tells you what's already scaffolded and what isn't. Pick the lowest-scoring dimension and work on it.

## What's a good first contribution

Three categories, in order of impact:

1. **V1.0 Story implementation.** Each story in VISION.md (Story 0–7) has automated acceptance criteria with named test files in `Tests/`. Pick a stubbed test (`XCTFail("not yet implemented")`), make it pass, send a PR. Story 0 (preview-md-shared extraction + MarkEdit baseline measurement + TextCanon ship) is the prerequisite to everything else.
2. **Test corpus.** `Tests/Fixtures/corpus/` needs ≥50 real-world `.md` files (READMEs, plans, specs, frontmatter-heavy docs) for round-trip and anchor-drift tests. `Tests/Fixtures/ime/` needs 30 scripted CJK input scenarios.
3. **E2E scenario coverage.** `docs/e2e-test-plan.md` enumerates the 13 USE-level scenarios. 10 are implemented as `make e2e` tests in `E2ETests/Scenarios.swift`; row 6 (sidecar write via composer), row 8 (click gutter dot), and the positive variant of row 5 (with-selection composer) are still open. Each is one table-row addition — `App/E2EBridge.swift`'s probe surfaces the signals you need.
4. **Bug reports against the vision.** Reading VISION.md and finding a contradiction, missing detail, or risk we didn't address is genuinely valuable. Open an issue tagged `vision`.

## Testing

Three layers, each with a different scope:

- `make test` — XCTest unit suite. Internal logic (TextCanon, AnchorResolver, CSV/JSON parsing, comment serialisation). Fast; runs on every push.
- `make e2e` — XCUITest USE suite. 10 scenarios from `docs/e2e-test-plan.md` covering open/render/comment/preview across .md/.csv/.json/.html/.pdf. Gates CI; the load-bearing signal that user-visible behaviour didn't regress.
- `make score` — 12-dimensional build-readiness rubric. Target 95% avg / 80% min per dimension.

First-time e2e setup on a developer machine: macOS pops a TCC Automation prompt for `MDEditorE2ETests-Runner.app` on the first `make e2e`. Approve once in System Settings → Privacy & Security → Automation; subsequent runs are silent. GitHub Actions runners auto-grant this, so CI doesn't need the dance.

If you add a new scenario: extend the probe in `App/E2EBridge.swift` if the signal you assert on isn't already surfaced, add a fixture under `E2ETests/Fixtures/`, and add a row to the scenario table in `docs/e2e-test-plan.md` so the scenario count stays honest.

## PR conventions

- **One change per PR.** Multi-purpose PRs get sent back with "split this please."
- **Commit messages: imperative subject ≤50 chars, body explains the why.** "Fix anchor drift" not "fixed the bug".
- **All acceptance criteria your PR claims to satisfy must be in CI** before merge. No "trust me, I tested locally."
- **Run `make score` before pushing.** If your PR drops a dimension's score, explain why or revert.

## Architecture rules (the load-bearing engineering invariants)

- **`TextCanon.swift` is the only file allowed to touch CRLF/NFC/UTF-16.** `Tests/CanonOwnership.swift` enforces this via SwiftSyntax. Adding to the allowlist requires PR justification.
- **`NSFileCoordinator`-mediated atomic save path. Never `rename(2)` directly.** Bypassing the coordinator breaks NSFileVersion (the History feature).
- **UTF-16 offsets everywhere in the bridge protocol.** Same units as the anchor schema. No conversions in handler code.
- **CodeMirror 6 version pinned in `package-lock.json`.** Never auto-bump; every CM6 upgrade requires the IME regression corpus to pass.
- **No file in `App/Editor/Comments/Sidebar/Preview/Bridge/` may depend on test code.**

## Communication

- **Bugs / proposals:** GitHub Issues.
- **Real-time:** there isn't any. By design.
- **Reviewing AI-drafted PRs:** treat them like any PR. The CI gates apply.

## License

By contributing, you agree your contribution is MIT-licensed under the same terms as the rest of the repo.
