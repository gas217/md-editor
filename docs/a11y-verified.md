# Accessibility Verification

Last verified: NOT YET — V1.0 build hasn't produced a binary. Update this file with date + macOS version after each release.

## What we promise

- VoiceOver navigates every primary surface (editor, sidebar, comment composer, comment thread).
- All controls have accessibility labels.
- Color contrast meets WCAG AA in both light and dark mode.
- Full keyboard control — no mouse-only flows.
- Reduce-motion preference honored.

## How we verify (per release)

1. **Automated:** `Tests/Accessibility.swift` exercises every named accessibility label and asserts they're present and non-empty.
2. **Manual VoiceOver pass.** With VoiceOver enabled:
   - Open a `.md` file via Cmd-O. VoiceOver should announce the open dialog and the resulting document.
   - Navigate the editor with VO arrows. Selection and cursor positions announced.
   - Add a comment via Cmd-Shift-M. Composer should be focused; VO announces the composer and the active selection.
   - Save with Cmd-S. VO announces the save.
   - Open the sidebar with VO+J or the menu. Navigate file list with VO arrows.
3. **Contrast audit.** Run the rendered preview through a contrast checker (Stark, the macOS Accessibility Inspector contrast tool, or equivalent). Both themes must hit WCAG AA. Capture before/after screenshots in this file.
4. **Keyboard-only run.** Unplug the mouse, perform Stories 1, 3, 4 of V1.0 from cold launch. Note any flows that required pointer input.
5. **Reduce motion.** System Settings → Accessibility → Display → Reduce motion. Re-run Story 1 and verify animations are short-circuited.

## Verification log

| Date | macOS version | App version | Pass/fail | Notes |
|---|---|---|---|---|
| TBD | TBD | v0.1.0 (scaffold) | n/a | No binary to verify |

## Known gaps (to fix before V1.0 ships)

- `Tests/Accessibility.swift` does not exist yet. Story 1 should add a baseline pass; further coverage tracks story implementation.
- The WKWebView-based editor surface inherits CodeMirror 6's a11y story, which is acceptable but not great. MarkEdit ships with VoiceOver workable; we match their bar.
- PDFKit (V2) has good built-in a11y; verify when V2 ships.
