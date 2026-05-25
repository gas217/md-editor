# Third-Party Licenses

MD Editor ships under MIT (see `LICENSE`). The binary links the following dependencies, all license-compatible with MIT distribution. This file is the source of truth for the production-readiness "no GPL in production binary" gate.

## Swift packages (linked into the .app bundle)

| Package | Version | License | Source |
|---|---|---|---|
| preview-md-shared | local (this repo's sibling) | MIT | `../preview-md-shared/LICENSE` |
| swift-markdown (planned, Story 0a) | TBD | Apache-2.0 | https://github.com/apple/swift-markdown |
| Yams (planned, Story 0a) | TBD | MIT | https://github.com/jpsim/Yams |

## JavaScript dependencies (bundled into Editor/web/editor.js)

| Package | Version | License | Source |
|---|---|---|---|
| @codemirror/state | 6.4.1 | MIT | https://github.com/codemirror/state |
| @codemirror/view | 6.28.4 | MIT | https://github.com/codemirror/view |
| @codemirror/commands | 6.6.0 | MIT | https://github.com/codemirror/commands |
| @codemirror/lang-markdown | 6.2.5 | MIT | https://github.com/codemirror/lang-markdown |
| @codemirror/lang-json | 6.0.1 | MIT | https://github.com/codemirror/lang-json |
| @codemirror/lang-html | 6.4.9 | MIT | https://github.com/codemirror/lang-html |
| @codemirror/search | 6.5.6 | MIT | https://github.com/codemirror/search |
| @codemirror/language | 6.10.2 | MIT | https://github.com/codemirror/language |

## Build-only dependencies (not shipped in the binary)

| Package | Version | License |
|---|---|---|
| esbuild | 0.21.5 | MIT |
| typescript | 5.4.5 | Apache-2.0 |
| xcodegen | latest | MIT |

## System frameworks

Apple's WebKit, PDFKit, AppKit, SwiftUI, Foundation, CryptoKit, NSDocument, NSFileVersion — governed by the Apple Developer Program License Agreement and the [Apple Operating System and System Software License Agreement](https://www.apple.com/legal/sla/).

## Audit policy

- All new Swift package dependencies must be added to this file in the same PR.
- All new JS dependencies must be added to this file when `Editor/web/package.json` changes.
- GPL/AGPL/LGPL licenses are **not permitted** in any code that links into the shipped binary. (GPL build-only tools — e.g., a hypothetical future fuzzer — are acceptable but don't go in here.)
- CI may add a license-compatibility checker; until then, this file is reviewed manually in PR.
