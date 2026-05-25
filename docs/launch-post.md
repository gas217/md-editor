# Launch Post (Draft)

Posted on launch day to HN, Mastodon, Twitter, and the README. Update before V1.1 release.

---

## MD Editor — a lightweight macOS viewer + light-editor for the files AI agents produce

Open source. Native. MIT. No Electron, no account, no subscription.

I built MD Editor because I kept opening `.md`, `.csv`, and `.json` files my Claude Code sessions had just dropped into my repo, and reaching for VS Code or Cursor felt like overkill for "look at this for 10 seconds and maybe add a note for the next run." Quick Look couldn't comment. Numbers mangled my CSVs. Browser couldn't edit HTML. There was no tool shaped like the job.

So:

- **Preview-by-default.** Markdown becomes typeset prose. CSV becomes a sortable table. JSON becomes a collapsible tree. HTML renders sandboxed. Plain text just looks like text.
- **Comments on any line, in any format.** Select, Cmd-Shift-M, type. Saved to a sidecar `foo.md.comments.json` next to your file — git-friendly, AI-readable, drift-tolerant when the file changes.
- **AI-agent loop.** `@claude this needs more detail` in a comment. Run Claude on the file. It reads the sidecar, addresses the comment, replies, marks it resolved. The schema is the API.
- **Native macOS.** Real AppKit menus, real `NSDocument`, real `NSFileVersion`-backed history, Apple Writing Tools, Apple Intelligence Services. Not Electron, not Catalyst.
- **Lightweight.** Cold launch under half a second. Under 10 MB binary. Under 80 MB idle RAM. Hard budgets in CI.

### What it isn't

- Not an IDE.
- Not a spreadsheet (CSV is viewed as a table; edited as text).
- Not a notebook (JSON is viewed as a tree; edited as text).
- Not a markdown editor with extras (CSV / JSON / HTML / PDF are first-class).
- Not Obsidian (no vault, no graph, no plugins, ever).
- Not Cursor (no AI chat panel; comments are the agent API).

### The pitch in one sentence

A local Google Docs, with Claude in the loop, for the plain-text files your AI workflow actually produces.

### Try it

```bash
brew install --cask mdedit
mdedit some-file.md
```

Or grab the DMG from [github.com/gas217/md-editor/releases](https://github.com/gas217/md-editor/releases).

### The wedge against MarkEdit

If you've used MarkEdit (which you should — it's excellent), MD Editor is its cousin: same architecture (AppKit + CodeMirror 6 in WKWebView), same MIT license, same "feels native" bar. Difference: MD Editor opens to a preview, ships first-class commenting, handles the multi-format use case, and treats the agent loop as the design center. MarkEdit is "minimal markdown source editor"; MD Editor is "lightweight viewer + light edit surface for AI outputs."

### Roadmap

- **V1.0 (now):** `.md`, `.txt`, commenting, anchor cascade, CLI agent loop. Markdown foundation.
- **V1.1:** `.csv`, `.json`/`.jsonl`, `.html`. Slash menu, Spotlight indexing, Finder Sync badges.
- **V2:** `.pdf`. PDFKit rendering, page-region comments, on-device Apple Intelligence "Address" Services entry.

Full architecture in [VISION.md](https://github.com/gas217/md-editor/blob/main/VISION.md). Production-readiness checklist in [PRODUCTION-READINESS.md](https://github.com/gas217/md-editor/blob/main/PRODUCTION-READINESS.md).

MIT-licensed. No paid tier, no sponsorship asks (until I want one), no telemetry.

Issues, ideas, vision-feedback: [github.com/gas217/md-editor/issues](https://github.com/gas217/md-editor/issues).
