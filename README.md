# MD Editor

A lightweight native macOS viewer + light-editor for the text formats AI agents produce — `.md`, `.txt`, `.csv`, `.json`, `.html`, and (V2) `.pdf` — with first-class commenting and a Claude-style agent loop.

**Status:** pre-V1.0. The vision is locked (see [VISION.md](VISION.md)); the build is starting.

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
- **[METRICS.md](METRICS.md)** — the build-readiness rubric we hill-climb against
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to help
- **Sibling project: [preview-md](https://github.com/gas217/preview-md)** — Quick Look extension that ships the same rendering engine

## Build

Requires macOS 14+, Xcode 15+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
make project   # generate MDEditor.xcodeproj from project.yml
make build     # build Debug
make test      # run unit tests
make score     # print current build-readiness rubric scores
```

## Current readiness score

Run `make score` to see the live numbers. Target: 95% average, no dimension below 80%. The score has its own CI workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) so regressions surface on every push.

## License

MIT. See [LICENSE](LICENSE).
