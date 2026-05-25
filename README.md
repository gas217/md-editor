# MD Editor

A lightweight native macOS viewer + light-editor for the text formats AI agents produce — `.md`, `.txt`, `.csv`, `.json`, `.html`, `.pdf` — with first-class commenting and a Claude-style agent loop.

**Status:** pre-V1.0, but the core surface works. Markdown renders (CodeMirror 6 + Obsidian-style hybrid live preview, sized to match the [preview-md](https://github.com/gas217/preview-md) Quick Look extension exactly). Commenting wedge ships: ⌘⇧M + a visible toolbar button create comments anchored via W3C-style selectors and persisted to sidecar JSON for agent consumption. CSV/JSON/HTML get a preview pane; PDFs use PDFKit. 10-scenario XCUITest suite gates regressions of the user-visible behaviour.

## What this is

You open a file. Whatever format — `.md`, `.csv`, `.json` — you see a clean rendered preview in under half a second. Select text, drop a comment in the margin, save. Quit. Reopen tomorrow on another machine; the comment finds its anchor even if the line moved. Run Claude on the file — it reads the sidecar, addresses the comments, replies, marks them resolved.

**Not** an IDE. **Not** a spreadsheet. **Not** a notebook. **Not** an Electron app. A viewer with a light edit surface.

## What this isn't

- Not a markdown editor with extra features — it's a viewer for the formats AI workflows produce.
- Not a competitor to Cursor/VS Code — those are for writing code; this is for glancing at and lightly editing AI outputs.
- Not Obsidian — no vault, no graph, no plugin system, ever.
- Not for sale — MIT, free, no telemetry, no account.

See [VISION.md](VISION.md) for the full thesis, design principles, competitive positioning, and architecture.

## Quick links

- **[VISION.md](VISION.md)** — what we're building and why (~700 lines, opinionated)
- **[docs/e2e-test-plan.md](docs/e2e-test-plan.md)** — the 13 USE-level scenarios the XCUITest suite gates against
- **[METRICS.md](METRICS.md)** — the build-readiness rubric we hill-climb against
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to help
- **Sibling project: [preview-md](https://github.com/gas217/preview-md)** — Quick Look extension that ships the same rendering engine (typography mirrored exactly via `preview-md-shared`)

## Try it

```bash
brew install xcodegen
make build                                    # builds + bundles the CM6 editor
./scripts/deploy-light.sh                     # installs to /Applications, ad-hoc signed
open -a MDEditor path/to/file.md              # markdown with hybrid live preview
open -a MDEditor path/to/data.csv             # csv with table preview
open -a MDEditor path/to/payload.json         # json with tree preview
```

⌘⇧M with text selected → comment composer. Save with ⌘↩. Sidecar lands at `path/to/file.md.comments.json`.

Window opens at 1/3 width × full screen height on displays ≥2500 px, otherwise 1/2 width.

## Build targets

```
make project              Generate MDEditor.xcodeproj from project.yml (requires xcodegen)
make install-editor-deps  npm install in Editor/web/
make editor-bundle        Build the CodeMirror 6 bundle (esbuild)
make build                Build Debug configuration (depends on editor-bundle)
make test                 Run unit tests (78 currently green)
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
| e2e USE | XCUITest (`make e2e`) | 10 scenarios across .md/.csv/.json/.html/.pdf — see [docs/e2e-test-plan.md](docs/e2e-test-plan.md) |
| build-readiness | `make score` | 12-dimensional rubric, target 95% avg / 80% min |

E2E first-run setup: macOS will pop a TCC Automation prompt for `MDEditorE2ETests-Runner.app`; approve once in System Settings → Privacy & Security → Automation. Subsequent runs are silent.

## Current readiness score

Run `make score` to see the live numbers. Target: 95% average, no dimension below 80%. The score has its own CI workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) so regressions surface on every push.

## License

MIT. See [LICENSE](LICENSE).
