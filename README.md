# MD Editor

A lightweight native macOS viewer + light-editor for the text formats AI agents produce — `.md`, `.txt`, `.csv`, `.json`, `.html`, `.pdf` — with first-class commenting and a Claude-style agent loop.

**Status:** pre-V1.0; core features are implemented, with verification gaps listed below. Markdown renders (CodeMirror 6 + Obsidian-style hybrid live preview, with typography based on the [preview-md](https://github.com/gas217/preview-md) Quick Look extension). Commenting is implemented: ⌘⇧M + a visible toolbar button create comments anchored via W3C-style selectors and persisted to sidecar JSON for agent consumption. CSV/JSON/HTML get a preview pane; PDFs use PDFKit. The XCUITest target contains 11 tests with partial coverage of the 13 planned scenarios; see [the coverage table](docs/e2e-test-plan.md).

## What this is

You open a file. Whatever format — `.md`, `.csv`, `.json` — the goal is a clean rendered preview in under half a second; cold-launch performance is still an unimplemented acceptance check. Select text, drop a comment in the margin, save. Quit. Reopen tomorrow on another machine; the comment finds its anchor even if the line moved. Run Claude on the file — it reads the sidecar, addresses the comments, replies, marks them resolved.

**Not** an IDE. **Not** a spreadsheet. **Not** a notebook. **Not** an Electron app. A viewer with a light edit surface.

## What this isn't

- Not a markdown editor with extra features — it's a viewer for the formats AI workflows produce.
- Not a competitor to Cursor/VS Code — those are for writing code; this is for glancing at and lightly editing AI outputs.
- Not Obsidian — no vault, no graph, no plugin system, ever.
- Not for sale — MIT, free, no telemetry, no account.

See [VISION.md](VISION.md) for the full thesis, design principles, competitive positioning, and architecture.

## Quick links

- **[VISION.md](VISION.md)** — what we're building and why (~700 lines, opinionated)
- **[docs/e2e-test-plan.md](docs/e2e-test-plan.md)** — the 13 planned scenarios and what the current tests actually assert
- **[METRICS.md](METRICS.md)** — the build-readiness rubric we hill-climb against
- **[App quality rubrics](docs/quality-rubrics.md)** — observable product quality, [look and feel](docs/look-and-feel-rubric.md), correctness gates, and evidence standards; use the [evaluation template](docs/quality-evaluation-template.md) for a candidate
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to help
- **Sibling project: [preview-md](https://github.com/gas217/preview-md)** — Quick Look extension from which the rendering package was extracted. This repo includes the package snapshot in `Vendor/preview-md-shared`; sibling checkouts are optional

## Try it

Requires full Xcode with its command-line tools selected, XcodeGen, and Node.js/npm (CI uses Node 22). If Homebrew does not put Node 22 on your PATH, follow its installation instructions. The renderer package is included; no sibling repository is required.

```bash
brew install xcodegen node@22
make build                                    # builds + bundles the CM6 editor
./scripts/deploy-light.sh                     # installs to /Applications, ad-hoc signed
open -a MDEditor path/to/file.md              # markdown with hybrid live preview
open -a MDEditor path/to/data.csv             # csv with table preview
open -a MDEditor path/to/payload.json         # json with tree preview
```

⌘⇧M with text selected → comment composer. Save with ⌘↩. Sidecar lands at `path/to/file.md.comments.json`. The saved thread opens immediately; click its margin marker to return to it. Reopen the file to load agent replies and resolved states.

Window opens at 1/3 width × full screen height on displays ≥2500 px, otherwise 1/2 width.

## Build targets

```
make project              Generate MDEditor.xcodeproj from project.yml (requires xcodegen)
make install-editor-deps  npm ci in Editor/web/ (locked dependencies)
make editor-bundle        Build the CodeMirror 6 bundle (esbuild)
make build                Build Debug configuration (depends on editor-bundle)
make build-release        Build Release app + CLI (no notarization/distribution steps)
make test                 Build app + CLI and run unit tests (includes explicit skips)
make e2e                  Run XCUITest scenarios — see docs/e2e-test-plan.md
make score                Run scripts/score.sh; report current build-readiness metrics
make baseline             Run scripts/measure-markedit-baseline.sh; write baselines.json
make dist                 Build distributable Debug bundle (no notarization)
make release              Release build + sign + notarize (requires MDEDIT_APPLE_ID env)
make clean                Remove build artifacts
```

## Testing

Three layers:

| layer | tool | what it gates |
|---|---|---|
| unit | XCTest (`make test`) | TextCanon, AnchorResolver, CSV/JSON parsing, comment serialisation |
| e2e USE | XCUITest (`make e2e`) | 11 tests, including comment creation and thread navigation; remaining gaps — see [docs/e2e-test-plan.md](docs/e2e-test-plan.md) |
| build-readiness | `make score` | 12-dimensional rubric, target 95% avg / 80% min |

Additional checks: `swift test --package-path Vendor/preview-md-shared` runs the renderer tests; `python3 scripts/test-build-harness.py` checks build/test failure reporting without Xcode.

Historical reconciliation results (2026-11-09, Xcode 26.4.1; see [current validation evidence](docs/e2e-test-plan.md#validation-evidence) for the expanded suite):

- Debug and Release app/CLI builds pass using the included renderer. The Release
  size check passes the 15 MB ceiling, with a warning above the 10 MB target.
- Unit suite: 96 tests, 78 passed and 18 skipped; no failures.
- Renderer package: 11 tests passed. Build-harness regression checks: 5 passed.
- Readiness rubric: 92 average (target 95), minimum 80; gate not met. Historical
  review scores were reused by the script, not freshly reassessed.
- E2E: 9 of 10 tests passed. `testCmdShiftMShowsComposer` failed because the
  `e2e-state` Accessibility field did not appear. The full suite is not green;
  see `build/e2e-result.xcresult` locally and the [coverage gaps](docs/e2e-test-plan.md).

E2E first-run setup: macOS may pop a TCC Automation prompt for `MDEditorE2ETests-Runner.app`; approve once in System Settings → Privacy & Security → Automation. UI testing requires an interactive macOS session and the required Automation/Accessibility access. A successful build-for-testing alone does not establish an E2E pass.

## Current readiness score

Run `make score` to see the live numbers. Target: 95% average, no dimension below 80%. The [CI workflow](.github/workflows/ci.yml) runs the score, but its readiness threshold is advisory during pre-V1.0. Build, unit-test, and E2E failures are blocking; the Release binary-size check remains advisory. The rubric includes scaffolding and historical review scores; it is not a claim that all acceptance criteria pass. `make score` runs a fresh build; `FAST_SCORE=1 make score` skips it and assigns zero build credit.

## License

MIT. See [LICENSE](LICENSE).
