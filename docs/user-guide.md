# MD Editor User Guide

Five minutes to a working understanding.

## What you can open

Double-click any of these and MD Editor opens it rendered:

- `.md` `.markdown` `.mdown` `.mkd` `.mkdn` — markdown
- `.txt` — plain text
- `.csv` `.tsv` — tabular (V1.1+)
- `.json` `.jsonl` `.ndjson` — structured (V1.1+)
- `.html` `.htm` — sandboxed rendered page (V1.1+)
- `.pdf` — PDFKit-rendered (V2+)

## Opening a file

Four ways, ranked by friction:

1. **Double-click in Finder.** Lowest friction. MD Editor registers as a default opener for the formats above.
2. **`mdedit foo.md` from the shell.** Same effect, scriptable. See `docs/cli.md`.
3. **Drag-and-drop onto the dock icon.** Opens in a new window.
4. **File → Open** inside the app. Standard.

## Reading

Files open in a rendered view by default. Markdown becomes typeset prose; CSV becomes a sortable table; JSON becomes a collapsible tree; HTML renders as the page (no JS, no network); PDF scrolls page-by-page.

Cmd-+ / Cmd-- adjusts the rendering size. Dark mode tracks System Settings.

## Editing

- **Markdown:** click anywhere in the rendered view to start editing. The syntax markers (`**bold**`, `# headings`) appear only on the line your cursor is on (Obsidian's "Live Preview" model). Cmd-E flips to full raw source view.
- **Focus mode** (V1.1+) hides markers even on the active line for pure WYSIWYG (Typora model). Cmd-Shift-F to toggle.
- **CSV / JSON / HTML:** preview is read-only by default. Cmd-E flips to source mode where you can edit the raw text.
- **PDF:** view only. No editing.

Cmd-S saves. Atomic write — your file stays consistent even if you yank power mid-save. macOS Versions ("File → Revert To → Browse All Versions") gives you the history slider.

## Commenting

Select text → Cmd-Shift-M → margin thread appears. Type your comment. The comment is saved to `foo.<ext>.comments.json` next to the file.

- **`@claude`** in a comment tells Claude Code to address it on the next run.
- **`#tags`** in a comment make it filterable.
- Click a comment indicator in the gutter to scroll to that thread.
- Resolve a comment by clicking the checkmark; deleted comments archive (Cmd-Shift-A to see archived).

## The AI agent loop

1. You write `@claude this section needs more detail` on a paragraph and save.
2. You run `claude` (or any Claude Code session) and tell it `read comments in plan.md and address them`.
3. Claude reads `plan.md.comments.json`, makes the edits, appends a reply to your thread, sets `resolved: true`.
4. You reopen the file to verify.

You can also run the CLI: `mdedit comments plan.md --unresolved --addressable`.

## Sidebar

Drop a folder onto the app to open it. The sidebar lists all supported files. Click to open. No vault, no graph — just a folder browser.

## What MD Editor doesn't do

By design — see VISION.md non-goals.

- No project / workspace concept. Each file is independent.
- No plugins. Never.
- No cloud sync (iCloud / Dropbox / git handle this — your files stay portable).
- No real-time collaboration (async only).
- No first-party AI chat panel. Comments are the API; Claude Code is the client.
- No CSV edit-in-cell, no JSON edit-in-tree (use source mode for edits in V1).
- No PDF editing (view + comment only).

## Reporting bugs

Open a GitHub issue with the `bug` template. If the app crashed, include the relevant lines from `Console.app` filtered by `mdedit`.

## Privacy

Zero data collected by default. See `PRIVACY.md`.
