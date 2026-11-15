# E2E test plan and current coverage

The XCUITest target exists and contains 11 test methods. `make e2e` builds
the app, bundles its editor assets and CLI, then runs the UI tests. Build,
signing, and test failures propagate to the command and CI. Results are
written to `build/e2e-result.xcresult`.

The 13 rows below are the acceptance plan, not a claim of 13 completed
scenarios. Source audit: 2026-11-15. A test method's name alone is not
evidence that its full planned behavior is asserted.

## Validation evidence

[PR #1](https://github.com/gas217/md-editor/pull/1) carries the current CI results.
CI runs the full suite, then repeats comment creation/navigation and persisted
thread reopening three times. Every iteration must pass; this is not retry-until-green.
Result bundles and the complete UI log are uploaded for seven days on both
success and failure. UI steps have a ten-minute timeout, and superseded PR runs
are cancelled. Both build configurations verify their assembled bundle signature. CI uses `macos-15`; the retired `macos-14` runner cannot start jobs.

The November 15 local unit run passed 84 tests with 18 existing acceptance
placeholders skipped. The local UI runner timed out enabling macOS automation
before executing tests; that is not a product pass or a failed app assertion.
Normal-mode manual QA exercised keyboard and toolbar comment creation, exact
selection persistence, immediate markers, thread clicks, reopen, two comments
on one line, and a bundled-CLI resolve/reply observed after reopening. Document
bytes were unchanged. The earlier November 9 result (9/10 UI methods passed)
is historical and does not describe the expanded suite.

## Coverage

| # | Planned behavior | Current automated assertion / gap |
|---|---|---|
| 1 | Open .md from Finder; editor is ready with content | `testOpensMdFile` opens via test launch arguments and checks the window title. Finder routing and editor readiness are not checked by this method. |
| 2 | Markdown renders with appropriately sized headings | `testMarkdownActuallyRenders` checks h1/h2 and inline-code DOM classes. Computed heading sizes are not checked. |
| 3 | Gutter has no white strip | `testGutterHasNoWhiteStrip` checks the computed background is transparent. |
| 4 | Comment command without selection does not open composer | `testCommentWithoutSelectionDoesNothing` clicks the toolbar without selection and checks composer and sidecar absence. |
| 5 | Select text + comment command opens composer with quote | `testCreateCommentAndOpenThread` selects the fixture through the real editor and invokes Cmd-Shift-M. It checks the composer, then the exact saved quote. The toolbar selection path and visible quote are also checked manually. |
| 6 | Enter comment + save writes a valid sidecar | The creation test types immediately through the app without clicking the composer, saves with Cmd-Return, checks one comment, exact body/quote, agent addressability, immediate marker and thread, and unchanged document bytes. |
| 7 | Quit/reopen restores a comment's gutter dot | `testReopenShowsGutterDot` loads a valid seeded sidecar, reopens, checks a real DOM marker and accessible button, clicks to read the saved body, and verifies the sidecar bytes were not rewritten. |
| 8 | Click gutter dot reveals the matching thread | Both comment tests click the real accessible marker and require the matching visible thread text. The creation test closes the automatically shown thread before clicking, preventing a false pass from an already-open thread. |
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
execution result before reporting the suite as passing. CI retains result
bundles and `build/e2e.log` on success and failure.

The creation test also cancels a typed draft with Escape and verifies unchanged
sidecar and document bytes. Remaining comment coverage includes multi-document UI
isolation, keyboard activation of marker buttons, long/Unicode selections,
and external refresh (13). A file watcher is not implemented: reopen to see
an agent's external sidecar edit. Native Accessibility exposes composer controls
and comment buttons; the test bridge observes marker counts without creating
comments or clicking on the test's behalf.

The unit suite still has explicitly skipped acceptance placeholders.
`scripts/score.sh` awards verification points for E2E scaffolding; it does
not execute the suite or certify these acceptance rows. CI invokes
`make e2e` separately.

## Outside this suite

- Preview MD's Quick Look extension (separate repo).
- Sparkle update delivery.
- macOS Writing Tools / Apple Intelligence.
- Pixel-perfect visual comparison against Preview MD.
