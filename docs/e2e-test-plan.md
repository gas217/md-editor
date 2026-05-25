# E2E test plan

Why this exists: the user has caught three USE-level bugs in a row that the
existing test suite (78 unit tests, all green) reported nothing about — file
opens but renders raw markdown, ⌘⇧M opens inspector but composer never
appears, etc. "Builds & file exists" ≠ "works for a user."

This plan defines a USE-level test layer that catches those bugs before the
user sees them.

## Test pyramid (after this lands)

```
Layer          | What it tests                          | Tooling
---------------+----------------------------------------+------------------
e2e (NEW)      | USE scenarios — open, render, save,    | XCUITest + JS
               | comment, reopen, agent reply           | bridge assertions
integration    | Swift package APIs + sidecars + bridge | XCTest (existing)
unit (78×)     | TextCanon, AnchorResolver, CSV parse,  | XCTest (existing)
               | comment serialisation                  |
```

Today: only the bottom two exist. Adding e2e fills the gap that has been
allowed to bite.

## Scenarios to cover (V1.0)

Each scenario is one XCUITest test method. Each must FAIL today on a broken
build and PASS only when the user-visible behaviour works.

| # | Scenario | Pass condition |
|---|----------|----------------|
| 1 | `open .md from Finder` → window appears | window.title contains filename; bridge replied editor.ready; JS doc.toString() length > 0 |
| 2 | `open .md` → markdown actually renders | JS `document.querySelector('.cm-h1')` matches at least one element AND its computed fontSize > 1.5em |
| 3 | `open .md` → gutter has no white strip | JS `getComputedStyle(document.querySelector('.cm-gutters')).backgroundColor` is `rgba(0,0,0,0)` or transparent |
| 4 | `⌘⇧M without selection` → no composer | inspector stays collapsed; sidecar JSON not created |
| 5 | `select text + ⌘⇧M` → composer shows | inspector pane width > 0; "On: …selected text…" label visible |
| 6 | `type comment + ⌘↩` → sidecar written | `<file>.md.comments.json` exists; contains 1 comment with body |
| 7 | `quit + reopen file` → gutter shows comment dot | JS `.cm-comment-active` element exists in gutter |
| 8 | `click gutter dot` → ThreadView shows in inspector | inspector visible; body text matches saved comment |
| 9 | `open .csv` → preview pane shows table | NSTableView with >0 rows visible on right pane |
| 10 | `open .json` → preview pane shows tree | DisclosureGroup or similar visible on right pane |
| 11 | `open .html` → preview pane shows rendered | WKWebView on right pane has document.body.children.length > 0 |
| 12 | `open .pdf` → PDFKit shows document | PDFView present, hasDocument == true |
| 13 | `agent edits sidecar externally` → inspector refreshes | write sidecar from test process; inspector ThreadView updates within 1s |

## What needs to ship in the app to make these testable

XCUITest drives the app via Accessibility. WKWebView's DOM is opaque to it,
so we need bridge hooks:

1. **Launch-arg test mode**: `--e2e=1` enables a test-only message handler
   `webkit.messageHandlers.test` that lets XCUITest evaluate arbitrary JS
   in the editor and read the result. This is the standard MarkEdit /
   VS Code pattern.

2. **Deterministic temp dir**: `--e2e-tmp=<path>` forces the doc dir + sidecar
   dir to a temp location the test owns. Prevents tests from polluting the
   user's real docs.

3. **AX identifiers** on the toolbar buttons, inspector pane, composer fields
   (`addCommentButton`, `inspectorPane`, `composerBody`, `composerSave`) so
   XCUITest can grab them by name not by index.

4. **Test-only entry point in CommentInspectorModel** to read the current
   `composer` / `activeThread` state from outside (a debug `currentState()`
   that test mode wires to the test bridge).

None of these affect production behaviour — gated on `--e2e=1`.

## Test targets

- Add `MDEditorE2ETests` target (XCUITest bundle) to `project.yml`.
- Add `make e2e` → `xcodebuild test -scheme MDEditor -only-testing:MDEditorE2ETests`.
- Add `make e2e-CI` → same plus `-resultBundlePath` for CI artifacts.
- Wire into existing `scripts/score.sh` so the verification dimension
  (currently file-existence + build success) actually requires e2e green.

## What this will NOT do

- Test PreviewMD's QuickLook extension (separate repo).
- Test Sparkle update flow (would require a fake appcast server).
- Test macOS Writing Tools / Apple Intelligence (no public test API).
- Validate visual rendering pixel-perfect against PreviewMD (instead we
  assert on DOM properties + computed styles).

## Effort estimate

- Project scaffolding + AX identifiers: ~1 day
- Scenarios 1–8: ~2 days
- Scenarios 9–13: ~1 day
- CI hook + score.sh wiring: ~0.5 day
- **Total**: ~1 week of focused work

## Open questions for the user

1. Build this now in V1.0 or defer to V1.1? V1.0 ships sooner without it,
   but the past 24 hours show the cost: 3 user-caught USE bugs.
2. Should we also add a Playwright/Detox-style JS test for the CM6 bundle
   in isolation? Faster feedback loop, but doesn't cover the Swift⇄JS path.
3. CI runner: GitHub Actions macOS runners support XCUITest but are slow
   (~8 min per scenario). Acceptable, or self-hosted?
