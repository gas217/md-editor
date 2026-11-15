# E2E test plan and current coverage

The XCUITest target exists and contains 10 test methods. `make e2e` builds
the app, bundles its editor assets and CLI, then runs the UI tests. Build,
signing, and test failures propagate to the command and CI. Results are
written to `build/e2e-result.xcresult`.

The 13 rows below are the acceptance plan, not a claim of 13 completed
scenarios. Source audit: 2026-11-08. A test method's name alone is not
evidence that its full planned behavior is asserted.

## Latest local run

On 2026-11-09 with Xcode 26.4.1, 9 of 10 tests passed.
`testCmdShiftMShowsComposer` failed while waiting for `e2e-state` to appear;
the result bundle is `build/e2e-result.xcresult`. `make e2e` returned a failing
status. The remaining assertion gaps below exist independently of this failure.

## Coverage

| # | Planned behavior | Current automated assertion / gap |
|---|---|---|
| 1 | Open .md from Finder; editor is ready with content | `testOpensMdFile` opens via test launch arguments and checks the window title. Finder routing and editor readiness are not checked by this method. |
| 2 | Markdown renders with appropriately sized headings | `testMarkdownActuallyRenders` checks h1/h2 and inline-code DOM classes. Computed heading sizes are not checked. |
| 3 | Gutter has no white strip | `testGutterHasNoWhiteStrip` checks the computed background is transparent. |
| 4 | Comment command without selection does not open composer | `testCmdShiftMShowsComposer` actually clicks the toolbar button without a selection and checks composer absence. The keyboard shortcut and sidecar absence are not checked. |
| 5 | Select text + comment command opens composer with quote | Not implemented. |
| 6 | Enter comment + save writes a valid sidecar | Not implemented. |
| 7 | Quit/reopen restores a comment's gutter dot | `testReopenShowsGutterDot` checks document content loads and a seeded sidecar survives. It does not assert marker restoration or successful sidecar decoding. |
| 8 | Click gutter dot reveals the matching thread | Not implemented. |
| 9 | CSV opens with table preview | `testOpensCsvPreview` checks at least four HTML table rows and two web views. The preview uses WKWebView, not NSTableView. |
| 10 | JSON opens with a tree preview | `testOpensJsonPreview` accepts JSON keys or any body content, plus two web views. Tree structure and expand/collapse behavior remain unverified. |
| 11 | HTML opens with rendered body content | `testOpensHtmlPreview` checks at least three body children and two web views. |
| 12 | PDF opens with a loaded document | `testOpensPdfShowsPDFView` checks PDFView presence only; it does not check that the document loaded. |
| 13 | External agent sidecar edit refreshes inspector within 1s | `testAgentEditRefreshesSidecar` writes and reads JSON in the test process. It does not observe an app refresh; a file watcher and observable inspector assertions remain open. |

## Existing test hooks

`App/E2EBridge.swift` activates only with `--e2e=1` or `MDEDIT_E2E=1`.
It opens `--e2e-fixture=<path>`, uses `--e2e-tmp=<path>` for test sidecars,
and polls DOM state into an Accessibility field named `e2e-state`.
`E2ETests/E2EHelpers.swift` stages fixtures in a fresh temporary directory
and decodes that field. The hook exposes predefined probes, not an
arbitrary-JavaScript message handler.

Current signals include editor heading/code counts, text length, gutter
background, comment-marker count, preview table/key/body counts, PDFView
presence, and web-view count. Full composer, inspector, computed heading
style, and PDF document state need additional observable signals.

## Running and extending

Run `make e2e` from an interactive macOS session with Xcode installed.
macOS may request Automation or Accessibility access for the test runner.
A build-for-testing pass verifies compilation only; inspect the test
execution result before reporting the suite as passing. CI uploads the
result bundle on failure when one exists.

Prioritize the missing comment workflow (5, 6, 8), then strengthen 7 and
13 so they observe the app consuming valid sidecars. Add any required AX
identifiers/probes, fixtures under `E2ETests/Fixtures/`, and update this
table in the same change.

The unit suite still has explicitly skipped acceptance placeholders.
`scripts/score.sh` awards verification points for E2E scaffolding; it does
not execute the suite or certify these acceptance rows. CI invokes
`make e2e` separately.

## Outside this suite

- Preview MD's Quick Look extension (separate repo).
- Sparkle update delivery.
- macOS Writing Tools / Apple Intelligence.
- Pixel-perfect visual comparison against Preview MD.
