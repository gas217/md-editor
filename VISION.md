# MD Editor — Product Vision

**Local Google Docs, with Claude as your co-author** — applied to the plain-text formats devs and AI agents actually pass back and forth (markdown, plain text, CSV, JSON, HTML). Every file opens to a rendered preview. You can drop a margin comment on any line, same as Docs. Claude reads those comments, addresses them, replies, and resolves them — the same loop you'd have with a human collaborator. Open source, native macOS, no cloud account, your files stay on your disk.

## Design Principles

Two principles override everything else.

1. **Speed.** Cold launch under half a second. Idle memory under 80 MB. Typing latency indistinguishable from native. If a feature breaks the budgets in *Success Metrics*, it doesn't ship.
2. **Ease of use.** No config screen, no account, no project model. Double-click a file, see it rendered. Standard macOS shortcuts. Dictation works because we use system text-input surfaces. Mental model: TextEdit-shaped *out of the box* — single window, source-or-preview, no modes a casual user has to learn. Power features (Focus mode, slash menu, Cmd-E source flip, sidebar) are progressive disclosure — present in menus, not in your face. **One onboarding exception:** the V1.1 Finder Sync badge requires per-folder access via System Settings (Apple's entitlement model — we can't bypass it). First time a user enables the Finder badge feature, an in-app explainer walks them through that one grant; baseline app usage has zero onboarding.

## Thesis

AI agents produce a flood of structured-text files — plans in `.md`, results in `.csv`, tool outputs in `.json`, reports in `.html` and `.pdf`. The human job is *glance, tweak, comment, move on* — not *open a project, configure a workspace*. Today that falls to **code editors** (VS Code, Cursor — half a gig of IDE for a one-character change), **format-specific tools** (Numbers, jq, browser, Preview.app — each a context switch with no commenting), or **markdown editors** (MarkEdit, Obsidian — `.md` only). All wrong shape.

The gap is a single lightweight native macOS app that opens any of these formats to a rendered preview in under 500 ms, lets you edit lightly, lets you comment on any line, and stores comments in a sidecar an AI agent can read and address. Not an IDE, not a spreadsheet, not a notebook. A viewer with a light edit surface.

The objection is "but Cursor is already open." We're not asking anyone to close it. The entry point is Finder (double-click a file the agent just dropped), or `mdedit foo.csv` from the shell, or Quick Look's "Open With." The competition is the 2–4 seconds of cognitive friction of switching to the IDE for what should be a glance — dozens of trips per day per user.

## Who It's For

**Primary:** the solo dev whose workflow is AI agents producing structured files all day. They want to open one, glance at it, fix a typo or flag a row, move on. They have VS Code and Cursor — for writing code, not for checking AI outputs. They won't install Electron, sign into a service, or pay a subscription to mark up a file on their own disk.

**Secondary:** technical writers reviewing AI-drafted docs in git, data analysts triaging CSV exports without booting Excel, anyone whose AI output pile grew past `cat` and `less`.

**Not the persona:** Obsidian power users wanting a graph, novelists wanting Scrivener, data scientists wanting Jupyter, backend engineers refactoring schemas (use the IDE). Good tools; this isn't one of them.

**TAM honesty.** Five-figure audience today, six-figure by 2027 as agent workflows generalize. Not venture-scale — that's why it's MIT, not a startup.

## The Product

Open a file — `.md`, `.txt`, `.csv`, `.json`, `.html`, or `.pdf` — and see a rendered preview. Markdown becomes typeset prose. CSV becomes a sortable table. JSON becomes a collapsible tree. HTML renders as a sandboxed page. PDF opens with PDFKit.

For `.md`, click anywhere to edit in place — syntax revealed only on the active line (Obsidian Live Preview); Focus mode hides markers even on the active line (Typora). For other text formats, Cmd-E flips to source mode. PDF is view + comment only.

Select text, Cmd-Shift-M, type — a margin comment appears, saved to `foo.<ext>.comments.json` next to the file. Reopen tomorrow, on another machine, or in `git diff` — the anchor finds its place even if the line moved. Run Claude — it reads the sidecar, addresses comments, replies, marks resolved.

Nothing else. No vault, no graph, no sync, no plugins — ever (see non-goals).

## User Scenarios

Concrete jobs the app is designed for. Each one is the size of "single trip to the app" — open, do the thing, close. If V1 doesn't make these scenarios feel obvious, it isn't done.

### 1. Review an AI-generated research synthesis (the canonical loop)

Claude Code finished a deep-research run and synthesized `research-2026-05-24.md` into your repo. You double-click it from Finder. The app opens to a clean rendered view in under half a second. You scroll, read, and at three places you select a paragraph and hit Cmd-Shift-M: "section 4 conflates two findings", "this citation looks wrong", "expand on the implications here". You quit. Back in the terminal, you tell Claude `read comments in research-2026-05-24.md and address them`. Claude reads the sidecar, makes the edits, appends replies to your comments, and flips them resolved. You reopen the file later to verify the resolution.

*Without us:* this goes through VS Code (slow to launch, project-shaped, comments are GitHub PR-shaped not file-shaped) or through scrollback notes (un-anchored, agent has to guess what you meant).

### 2. Triage a CSV the agent just dumped

A scraping job emitted `results.csv` with 8,000 rows. You double-click it. It opens as a sortable table in under a second. You click the "score" column header to sort descending, spot two rows that look wrong, drop a comment on each ("this URL is malformed", "duplicate of row 17"). You ask the agent to fix them.

*Without us:* Numbers takes 4 seconds to launch and tries to type-coerce your data; VS Code shows raw CSV with no sortable columns; `less` is fast but read-only and uncomment-able.

### 3. Spot-check a deeply-nested JSON tool result

The agent returned `tool-call.json` — 4 MB of nested response data. You open it. The collapsible tree appears immediately, root collapsed. You drill into `result/users/3/permissions`, see the value you care about, click to copy the JSON Pointer, paste it into your follow-up prompt. No comment needed this time — you just wanted to peek.

*Without us:* `jq` requires you to know the path you want; pasting JSON into a browser pretty-printer is a privacy footgun; opening in VS Code wraps and loses tree structure.

### 4. Fix a typo in an AI-generated config

The agent produced `config.json` with a typo in a key. You open it. Cmd-E flips to syntax-highlighted source mode (bracket-matched, fold-able). You fix the one character. Cmd-S writes atomically. Done. App still showed a rendered tree the whole time you weren't editing.

*Without us:* the IDE is overkill for one character; `vim`/`nano` works but you can't visually validate the JSON structure first.

### 5. Read an AI-generated HTML report

The agent produced `daily-report.html` — a rendered RAG output with charts and tables. You open it. It renders as a sandboxed page (no JS, no network — broken-image placeholders for any CDN-linked assets, but the structure and inline assets render fine). You select a paragraph that misstates a number, add a comment, send back to the agent.

*Without us:* opening in browser doesn't let you comment; opening in VS Code shows raw HTML; opening in Preview.app doesn't work (Preview doesn't render HTML).

### 6. Review and annotate a PDF for the agent (V1.2)

The agent retrieved `paper.pdf` for research. You open it. PDFKit renders pages instantly. You select a passage on page 7, add a comment ("apply this method to our dataset"); highlight a flawed claim on page 12, comment ("check this against ref [4]"). You tell the agent to read the comments and incorporate the feedback into its analysis.

*Without us:* Preview.app's annotations are clunky and live inside the PDF (binary modification, no git diff); Skim is good but isn't AI-aware.

### 7. Read all of today's agent outputs in one window

Claude dropped today's outputs into `~/runs/2026-05-24/` — a mix of `.md` plans, `.json` tool results, one `.csv`, one `.pdf`. You drag the folder onto the dock icon. The sidebar lists everything, filtered to supported formats. You click through each file, scan, comment where needed, move on. Total time: minutes, not the half-hour it'd take in an IDE.

*Without us:* this is what `code ~/runs/2026-05-24/` is for, but the IDE takes ~3 s to start, doesn't preview the CSV or PDF natively, and clutters your real project state.

### 8. Quick Look → upgrade to commenting

You hit spacebar on `plan.md` in Finder — PreviewMD's Quick Look shows it instantly. You decide it needs a comment. Cmd-O (or "Open With → MD Editor" from Quick Look's toolbar) hands the file to us; the comment composer is one shortcut away.

*Without us:* Quick Look ends at "view," and there's no graceful path to comment.

### 9. Dictate a comment hands-free

You're reading a long spec on your laptop, hands away from the keyboard with a coffee. You select a paragraph (trackpad), hit Cmd-Shift-M (one keystroke), press Fn-Fn (dictation), speak your comment, press Fn-Fn again. Saved.

*Without us:* the alternatives don't have commenting at all, or they require typing because their text inputs don't surface system dictation.

### 10. Search across your AI-output pile (V1.1)

Three weeks of agent outputs are sitting in `~/runs/`. You vaguely remember commenting "this is wrong" on a chart titled "regret minimization." Spotlight search: `regret minimization`. Two results appear — the file containing that title, and a different file where you wrote the comment that referenced it. (The Spotlight importer indexed comment text.)

*Without us:* Spotlight finds the title but not the comment; you'd have to grep the sidecar JSONs by hand.

## Core Differentiators

What no other shipping app does:

1. **Native macOS + first-class commenting on every supported format**, including PDF — sidecar JSON, git-friendly, AI-addressable. Closest precedent (MarkEdit) is `.md` only, no commenting.
2. **Order-of-magnitude lighter than the alternative tool people reach for** (VS Code / Cursor for text formats, Preview.app for PDF) — sub-half-second cold launch, <10 MB binary, <80 MB idle.
3. **AI-agent loop designed in, not bolted on** — the comment schema *is* the integration; Claude reads/addresses/resolves comments with no plugin.

## Competitive Landscape (2026)

The real competition isn't other markdown editors — it's the IDEs and format-specific tools devs reach for when an AI hands them a file.

### Against heavy editors (the primary competitor set)

| App | Cold launch | Binary | Native | Preview by default | Multi-format viewer | Comments on .md/.csv/.json |
|---|---|---|---|---|---|---|
| **VS Code** | 2–4 s | ~300 MB installed | No (Electron) | No (extension) | Editor only — preview is plugin-per-format | Plugin only, IDE-shaped |
| **Cursor** | 3–5 s | ~600 MB installed | No (Electron) | No | Same as VS Code | Plugin only |
| **Zed** | <1 s | ~80 MB | Yes (Rust) | Markdown tab only | Source-only for CSV/JSON | Code comments only |
| **Sublime Text** | <1 s | ~30 MB | Yes | No | Source-only | No |
| **BBEdit** | ~1 s | ~50 MB | Yes | No | Source-only | No |
| **MD Editor** | **<500 ms** | **<10 MB** | **Yes** | **Yes (all 5 formats)** | **md/txt/csv/json/html** | **Yes (sidecar, all formats)** |

Wedge: an order of magnitude lighter, preview-by-default across formats, and commenting is built in — not a plugin.

### Against format-specific tools

| Tool | Format | Cost to open and glance | Problem |
|---|---|---|---|
| **Numbers / Excel** | CSV | Slow launch, type coercion mangles data, "save as CSV" dance | Wrong tool for a 200-row CSV |
| **jq / less / cat** | JSON | Fast but read-only, no folding, no comment | Fine for piping, painful for browsing |
| **Browser** | HTML | Renders fine but no edit, no comment, no source toggle | Read-only |
| **Quick Look** | All | Instant preview but no edit, no comment | Read-only |
| **PreviewMD** (sibling project) | MD only | Instant via Quick Look | Read-only, MD only |
| **MD Editor** | All five | Instant + light edit + comment | The point of the project |

### Against other markdown editors (secondary)

`.md` is the largest format share and these are where existing markdown users come from. None compete on `.csv`/`.json`/`.html`/`.pdf`:

| App | Native? | OSS? | Preview-by-default | `.md` comments | Multi-format? |
|---|---|---|---|---|---|
| **MarkEdit** | Yes (AppKit + CM6) | MIT | No (source default; preview is an extension) | No | Markdown + plain text only |
| **iA Writer** | Yes | No ($50) | No (split) | No | Markdown + plain text |
| **Bear 2** | Yes (Apple-only) | No (sub) | Hybrid live-styled | No | Markdown (library model) |
| **CotEditor** | Yes (AppKit) | GPL | No | No | Plain text + syntax HL (no preview) |
| **Typora** | No (Electron) | No ($15) | **Yes (WYSIWYG)** | No | Markdown only |
| **Obsidian** | No (Electron) | Proprietary | Toggle | Plugin only | Markdown + a few formats via plugin |
| **MacDown** | Yes (ObjC) | MIT | Split | No | Markdown only, unmaintained |
| **Markdown Studio / Ally / VMark / Nimbalyst** | All Electron/web | Mixed | Varies | No | Markdown only |
| **MD Editor (this)** | **Yes (AppKit + CM6)** | **MIT** | **Yes** | **Yes (sidecar JSON)** | **md/txt/csv/json/html** |

Closest single competitor: **MarkEdit** on `.md`. Markdown-only, no commenting. Our real ceiling is moving people off VS Code/Cursor for non-coding tasks — a bigger pool than "convert MarkEdit users."

## Features

The complete feature list. Anything that ships in V1 is here; anything not here is out of scope. Each item maps to a milestone (V1.0 / V1.1 / V1.2) and to acceptance criteria below.

### Viewing

- **Preview-by-default** for every supported format. No mode toggle needed to see your file rendered. (V1.0–V1.2)
- **Six supported formats:** `.md` (and aliases), `.txt`, `.csv`/`.tsv`, `.json`/`.jsonl`/`.ndjson`, `.html`/`.htm`, `.pdf`. (V1.0: md/txt; V1.1: csv/json/html; V1.2: pdf)
- **Per-format renderers:** GFM + mermaid + math for markdown; sortable HTML table for CSV; collapsible tree for JSON; streamed list for JSONL; sandboxed page render for HTML (no JS, no network); PDFKit for PDF.
- **Dark mode** tracks system appearance, no reload. (V1.0)
- **File-size ceilings** with source-mode fallback for oversized files — see *Supported Formats* table. (V1.0–V1.2)

### Editing (light)

- **Hybrid live preview for `.md`** — Obsidian-style markers visible only on the active line — with **Focus mode** toggle for pure WYSIWYG (Typora model). (V1.0)
- **Source mode (Cmd-E)** for every text format. CodeMirror 6 with format-appropriate language mode (markdown, JSON, HTML, CSV-light). Multi-cursor, search/replace, undo/redo. (V1.0: md/txt; V1.1: csv/json/html)
- **Notion-inspired inline editing for `.md`** (all deferred past V1.0 — V1.0 stays "TextEdit with comments and preview"). Borrowed deliberately; hard constraint: *output must serialize to plain markdown* — no proprietary block tree.
  - **Markdown shortcut conversion.** Type `# `, `## `, `- `, `1. `, `> `, ` ``` ` and the line transforms visually as the syntax becomes meaningful — same model as Obsidian/Notion. CM6's `lang-markdown` provides most of this for free. (V1.1)
  - **Slash commands.** Type `/` at the start of a line to open a menu: heading levels, bulleted/numbered list, todo, code block, table, blockquote, admonition (`[!NOTE]`/`[!WARNING]`), horizontal rule, math, mermaid. Picking one rewrites the line to the corresponding markdown syntax. (V1.1)
  - **Drag-to-reorder blocks.** Hover a paragraph/heading/list-item and a handle appears in the margin; drag to reorder. CM6 widget overlay translating to source-range cut-and-paste. (V1.1)
  - **Block hover actions.** Hover handle reveals a menu: Comment on this block, Copy block, Move block. (V1.1)
- **Atomic save** via `NSFileCoordinator`-mediated replace (the OS performs the temp-and-swap; we never call `rename(2)` directly because that bypasses NSFileVersion). Preserves frontmatter byte-for-byte; LF line endings for `.md`/`.txt`; round-trip byte-identical for compliant inputs. (V1.0–V1.1)
- **No structured editing** in V1 for non-markdown formats (no in-cell CSV edit, no JSON tree edit, no visual HTML edit). Source-mode only. PDF is view-only forever.
- **Dictation** works out of the box in every text input (Fn-Fn) — comment composer, source mode, search field — via system text-input surfaces. No setup. (V1.0)

### Commenting (the design center)

- **Comments on any line, any range, in any format** — including PDF page regions. (V1.0: md/txt; V1.1: csv/json/html; V1.2: pdf)
- **Sidecar JSON** (`foo.<ext>.comments.json`) — git-friendly, AI-readable, the `.md` file stays canonical.
- **W3C Web Annotation-style anchor cascade** with format-specific selectors: `TextPositionSelector`, `TextQuoteSelector`, `CSVCellSelector`, `CSVRowRangeSelector`, `JSONPointerSelector`, `JSONValueSelector`, `PDFAnnotationSelector`. Always a text-position fallback.
- **Drift-tolerant** — ≥95% re-anchor across a standard edit suite; mis-anchor rate must be 0% (orphans surface in a sidebar, never silently mis-attach).
- **Threaded replies, resolved state, author kind (human/ai).**
- **`@mentions` route comments to a person or agent.** Mentions are stored both in `body` (so the comment reads naturally) and parsed into structured `mentions: [{ kind, name }]` for filtering and agent routing. `@claude` implies `addressable: true` for Claude. V1.0: schema fields written and read; no autocomplete UI. V1.1: typing `@` in the composer opens autocomplete sourcing prior authors in this folder's sidecars + known agent names (`@claude`, `@gemini`, `@codex`, `@apple-intelligence`).
- **`#tags` for triage.** Stored in `body` and parsed into structured `tags: [string]`. V1.0: schema field; V1.1: `#` autocomplete sourcing tags used across the user's commented files; sidebar filtering by tag.
- **Margin gutter UI** — comment indicators in the left gutter (small filled circle per thread; number-badge if multiple threads anchor to the same line). Click the indicator to *reveal* the thread in a right-edge inspector panel that slides in over the editor (not a popover — popovers steal focus and break dictation). The panel shows the selected thread + its replies + composer for a new reply. Cmd-Shift-M starts a new thread on the current selection; Cmd-` cycles inspector focus; Esc closes the panel. The inspector is a sibling SwiftUI view sharing the document's data store — keyboard reachable, VoiceOver-labeled, never modal.
- **`@mention` affordance** (V1.0 even though autocomplete is V1.1): the composer shows a small subtitle "tip" line under the input — `Tip: type @claude to address this comment to Claude` — so users discover the routing convention without docs.

### History (the comment loop's other half)

Comments are *what should change*; history is *what did change*. Both are first-class.

- **File version history via macOS NSFileVersion.** Every save snapshots into the system's Versions store. "File → Revert To → Browse All Versions" shows the Time-Machine-style picker — scroll older versions, compare side-by-side, restore. Free with `NSDocument`; we just don't break it. (V1.0)
- **Comment history.** Resolved comments don't disappear — V1.0 keeps them in the sidecar and the schema (`resolved: true`); the "Show resolved" toggle in the sidebar that surfaces the audit trail (oldest-to-newest, who/when/what) is V1.1. Deleting archives a comment (`status: "archived"`); a separate "Show archived" reveals those. Nothing is ever silently lost.
- **Agent-edit log.** Each time an agent addresses comments via the CLI loop and writes back, an entry appends to `foo.<ext>.history.json`: `{ at, agent, model, commentsResolved, summary }`. The file itself is the source of truth (via NSFileVersion); the log gives a structured audit of *agent* changes specifically. Optional — missing means no agent has touched the file. (V1.1)
- **Side-by-side diff** when comparing versions — read-only renderer pane on each side, scroll-synced. Built on the same renderer pipeline. (V1.1)

### AI-agent loop

- **`addressable` flag** in the schema — human authors mark "please address this with Claude"; the agent filters on it.
- **CLI for agents:** `mdedit comments <file> --unresolved --addressable` prints matching comments as JSON; `--resolve <id> --reply <text>` appends a reply and flips resolved. (V1.0)
- **No first-party AI button or LLM client.** The schema is the API; the agent (Claude Code or anything else) is the client.

### Finder integration

- **Registered as opener** for all supported extensions (V1.0: md/txt; V1.1: csv/json/html; V1.2: pdf). "Open With" menu appears automatically.
- **Drag-to-dock-icon** opens a file. (V1.0)
- **Drag-onto-window** opens a file (replaces current document with unsaved-changes prompt). (V1.0)
- **`mdedit` CLI** — separate non-sandboxed helper at `MDEditor.app/Contents/Helpers/mdedit`; Homebrew cask installs a `/usr/local/bin/mdedit` shim that execs it. The helper handles stdin/stdout natively for `comments` / `merge-comments` subcommands; `mdedit foo.md` opens via `NSWorkspace.open`. Sandbox-honest design — see `docs/cli.md`. (V1.0)
- **Quick Look preview** for `.md` is handled by sibling project PreviewMD; we do not ship a competing extension.
- **Services menu** entries ("Open in MD Editor", "Add Comment to Selection"). (V1.1)
- **Finder Sync badge** — a small overlay icon on any file with unresolved comments. (V1.1)
- **Spotlight indexing** of comment text — `mdimporter` plugin indexes comment bodies alongside file content. (V1.1)

### Sidebar / navigation

- **Single-folder file browser.** Filters by supported extensions. No vault, no wiki-links. (V1.0)
- **`*.settings.json` per-file sidecar** for view preferences (default view mode, lock to source, CSV `hasHeader` override, CSV `primaryKeyColumn`). Optional; missing means defaults.

### Apple Intelligence (first-class, OS-level)

OS-shipped AI features get full support — conditional on hardware/OS (macOS 14 floor, AI lights up on 15+ M-series). We don't ship a chat panel or LLM client — those are first-party AI UI, see non-goals.

- **Writing Tools** (Proofread, Rewrite, Summarize, Make List/Table, Key Points) in every editable surface. Free via `NSTextView` + `contenteditable`; we just confirm we don't block them. (V1.0)
- **Document-level Summarize / Key Points / Proofread** — menu commands, results in a side panel, never written to the file. (V1.1)
- **Live Text on PDF pages** — text selection in scanned PDFs without a text layer; the extracted string becomes the anchor's quote. (V1.2)
- **On-device Foundation Model fallback** for "address comment." Exposed as a *macOS Services menu* entry ("Services → Address with Apple Intelligence") that operates on the selected unresolved comment — not an in-app AI button. Reply tagged `author.kind: "ai"`, `author.model: "apple-intelligence"`. Zero network. The carve-out from "no first-party AI UI": this is the OS's Services menu acting on the OS's local model, not our chat panel. (V2, gated on macOS 26 Foundation Models framework)
- **System dictation** — covered under *Editing*.

### Quality & polish

- **Standard macOS shortcuts honored:** Cmd-O/S/W/F/Q/Z/Shift-Z, Cmd-+/-, all menu shortcuts. (V1.0)
- **No permission prompts on first launch.** No mic, no location, no contacts, no calendar, no Apple Events.
- **Lightweight** — ~10 MB binary, <80 MB idle RSS, sub-half-second cold launch. See *Success Metrics* for the full budget table.
- **Local-first** — plain files on disk, no cloud, no account, no telemetry. MIT.

## Supported Formats

All six are first-class. Text formats have a source-mode editor; PDF is view + comment only.

| Ext | Renderer (preview view) | Source view | Light edits in V1 | Comments |
|---|---|---|---|---|
| `.md` (and `.markdown`, `.mdown`, `.mkd`, `.mkdn`) | PreviewMD's renderer: GFM, frontmatter, mermaid, math, syntax highlighting | CM6 with `lang-markdown` and hybrid live preview (Obsidian model) by default, Focus mode (Typora WYSIWYG) optional | Yes — inline editing is the surface | Anchored to UTF-16 ranges in source |
| `.txt` | Monospaced wrapped text, no parsing | CM6 with no language mode | Yes — inline editing is the surface | Anchored to UTF-16 ranges |
| `.csv` (and `.tsv`) | **Virtualized** sortable, scrollable HTML table — only ~50 rows in the DOM at any time; the rest are absolute-positioned spacers (a `position: absolute` windowed list, not a `<table>` with 500k `<tr>`). **Header row detection: always-on heuristic** — first row treated as header if every cell is non-empty and the row's column types differ from row 2 (strings vs numbers). User can override per-file via menu "View → Has Header Row" (writes to per-file sidecar). Click a column header to sort (sort happens in-memory; the virtualized window re-renders). Click a cell to focus (V1.1: read-only highlight; V2: edit in place). | CM6 with `lang-csv`-equivalent (light highlighting of delimiters) | V1.1: edits go through source mode (Cmd-E). V2: edit in cell. | Anchored via `CSVCellSelector` or `CSVRowRangeSelector` (table view) or `TextPositionSelector` (source view); see *Selector types*. |
| `.json` (and `.jsonl`, `.ndjson`) | **Virtualized** collapsible tree — only visible rows are in the DOM (same windowing approach as CSV); 10⁵ nodes scrolls smoothly. Type-colored values, copy-path-on-click. Errors highlighted inline. | CM6 with `lang-json` and bracket folding | V1.1: edits go through source mode. V2: edit values in tree. | Anchored to JSON Pointer path (RFC 6901) or source range |
| `.html` (and `.htm`) | Rendered page in a sandboxed WKWebView — no JavaScript execution, no network requests (CSP locked down). Renders CSS, inline images, and structure. | CM6 with `lang-html` | V1: source mode only | Anchored to source range (V1) or DOM XPath (V1.1) |
| `.pdf` | PDFKit-rendered native PDF view — scroll, zoom, page navigation, text selection. Search via Cmd-F. No annotation editing of the PDF itself (the PDF stays unchanged). | None — PDF is view-only forever. The "edit lightly" thesis doesn't apply to PDF; users edit upstream. | None | Anchored via `PDFAnnotationSelector` `{ pageIndex, rect, quadPoints?, selectedText? }` — page coords with optional selected-text quote for drift recovery if the PDF is replaced with a new version. |

**Format detection:** by extension only. We do not sniff content. If you open `data.txt` containing CSV, it opens as text. (Right-click → "Open as → CSV" available in V1.1.)

**Per-file settings sidecar:** when the user changes a per-file preference (header-row override, CSV `primaryKeyColumn`, default view mode, locked source-mode), it persists to `foo.<ext>.settings.json` next to the file. Same naming convention as the comments sidecar, separate file so the two have independent lifecycles. Schema is intentionally tiny and forward-compatible (`{ "version": 1, "csv": { "hasHeader": bool, "primaryKeyColumn": string? }, "view": { "mode": "preview"|"source"|"split", "locked": bool }? }`). Both sidecars are optional; missing means defaults.

**File size ceilings for the rendered preview** (over the ceiling = source mode by default, with a banner; user can opt in):
- `.md` / `.txt`: 5 MB
- `.csv`: **50 MB** (~500k rows). The "data analyst triaging exports" persona regularly hits ~5 MB CSVs; 5 MB would orphan them.
- `.json`: 10 MB (the tree renderer cost is per-node, not per-byte; 10 MB JSON can be 10⁵ tree nodes).
- `.jsonl` / `.ndjson`: rendered as a streamed list (one collapsible record per line). Ceiling: 50 MB (it's intrinsically streamable).
- `.html`: 5 MB.
- `.pdf`: 100 MB (PDFKit handles paging well; we lazy-load page bitmaps). Over the ceiling, banner says "Open in Preview.app for files this large."

**HTML rendering trade-off:** the sandboxed WKWebView blocks JS and all network — CDN scripts, web fonts, remote images won't load. AI reports that inline assets render perfectly; CDN-linked ones show broken-image placeholders. Trade: zero attack surface for a viewer opening whatever the agent wrote. Source-mode is one keystroke away.

## Finder Integration

Finder is the primary entry point. Deep integration is load-bearing — the "but Cursor is already open" objection only resolves if we're closer to the file than the IDE.

| Feature | Milestone | Notes |
|---|---|---|
| **Registered as default opener** for `.md`/`.markdown`/`.mdown`/`.mkd`/`.mkdn`/`.txt`/`.csv`/`.tsv`/`.json`/`.jsonl`/`.ndjson`/`.html`/`.htm` | V1.0 (md/txt), V1.1 (others) | Declared via `LSItemContentTypes` and `UTExportedTypeDeclarations` in `Info.plist`. User picks once via "Get Info → Open With → Change All"; OS handles the rest. |
| **Open With menu** appears in Finder right-click | V1.0 | Free once UTIs are registered. |
| **Drag a file onto the dock icon** opens it | V1.0 | Free via `NSApplicationDelegate.application(_:open:)`. |
| **Drag a file onto the app window** opens it (replacing or in a new tab? V1: replace, with unsaved-changes prompt) | V1.0 | `NSDraggingDestination` on the window. |
| **`mdedit foo.md` CLI** opens the file in the running app (or launches it) | V1.0 | Symlink installed to `/usr/local/bin/mdedit` by Homebrew cask. Uses `NSWorkspace.open` to hand off to the GUI app. |
| **Quick Look preview** for all supported formats | Handled by sibling PreviewMD project (already shipping for `.md`) | We do not ship a competing Quick Look extension. PreviewMD's V2 adds Finder thumbnails; that benefits us for free. |
| **Services menu entries** ("Open in MD Editor", "Add Comment to Selection") for any text-selection context | V1.1 | Registered via `NSServices` in `Info.plist`. The "Add Comment" service writes to a default scratchpad file. |
| **Finder Sync extension — comment badge** | V1.1 | Overlay icon on any file with an unresolved-comment sidecar. Separate signed `FinderSync` app extension in its own sandbox. **macOS reality:** the extension cannot watch `/` or `~` by default — the user must grant per-directory access via System Settings → Privacy & Security → Extensions → Finder. First-run onboarding walks the user through granting access to their preferred "AI outputs" root (e.g., `~/runs`). No default-watches-home claim; we are honest about the entitlement model. |
| **Spotlight indexing of comment text** | V1.1 | `mdimporter` plugin indexes unresolved comment bodies alongside file content. The importer claims a custom UTI for `*.comments.json` (not the bare `.json` UTI — that would compete with every other JSON importer). Runs in `mdworker`'s sandbox; reads only files it's asked to index. |

### Non-goals for Finder integration

- No Finder toolbar item (HIG discourages, violates "lightweight").
- No tag writing (reading is fine).
- No whole-disk file watching. Finder Sync badge respects user-configured roots.
- No competing Quick Look extension (PreviewMD's job).

## Tech Stack & Architecture

Decided. Not reopening unless something below breaks in practice.

- **Language:** Swift 5.10+
- **Min target:** macOS 14 (Sonoma). Covers the great majority of the installed Mac base; gives us TextKit 2 in the host shell, modern `Observable` macros, the WKWebView APIs we need. macOS 13 not worth the API back-pressure.
- **App lifecycle:** AppKit `NSDocument` — not SwiftUI `DocumentGroup`. We need explicit file URL ownership, granular open/save/revert/lock hooks, atomic-write control, and a real `NSWindowController` for the comments overlay. `DocumentGroup` fights us on all four.
- **UI shell:** SwiftUI for the sidebar, comments overlay, and settings sheet; AppKit (`NSDocument`, `NSMenu`, `NSWindowController`, `NSFindPanel`) for everything load-bearing. Native chrome non-negotiable.
- **Editor surface:** **CodeMirror 6 in WKWebView**, single page with `@codemirror/lang-markdown` + `@codemirror/lang-json` + `@codemirror/lang-html` + a small CSV mode + custom decoration set for hybrid live preview on `.md`. This is the MarkEdit architecture — proven, MIT-precedented, fastest path to a polished editor without inheriting Apple's still-buggy TextKit 2 surface.
- **Renderers per format** — only markdown reuses the PreviewMD package; the others are bespoke (small, owned in this repo):
  - `.md` → `preview-md-shared` package (extracted from PreviewMD — see Story 0 below). The only shared renderer.
  - `.csv` → small Swift CSV parser (RFC 4180-ish, tolerant) emits a virtualized HTML table into the preview WKWebView. ~300 lines of Swift + ~200 lines of JS for the windowed list.
  - `.json` → `JSONSerialization` → recursive HTML emitter for the virtualized tree. ~400 lines Swift + JS.
  - `.html` → loaded directly into a sandboxed WKWebView with strict CSP (no JS, no network, no plugins).
  - `.txt` → no rendering; the source editor *is* the view.
- **`preview-md-shared` extraction (V1.0 Story 0, prerequisite to everything):** PreviewMD's `Shared/` directory becomes a standalone Swift Package. PreviewMD currently embeds CSS/JS as string constants in `HTMLTemplate.swift` and loads `mermaid.min.js` from bundle. The extraction converts those to package resources; PreviewMD becomes the first consumer. Acceptance: PreviewMD's 103 tests pass against the new package; MD Editor depends on the same version. See *V1.0 Story 0* below.
- **Commenting storage:** sidecar JSON, schema below. No database, no SQLite, no `~/Library` state.
- **Save path:** all writes go through `NSFileCoordinator` (mediated by `NSDocument`'s save pipeline), which calls `writeData(_:to:for:originalContentsURL:)` and lets the system perform an atomic replace. We **do not** call `rename(2)` directly — that bypasses `NSFileCoordinator` and breaks `NSFileVersion` (the History feature). The coordinator-mediated path provides atomic writes *and* triggers Versions automatically. Acceptance criteria use this path; "atomic write via `rename(2)`" wording in the criteria is shorthand for the coordinator-mediated atomic replace.
- **File watching:** `NSFilePresenter` (via NSDocument) for the open file. `DispatchSource.makeFileSystemObjectSource` for the sidecar (which isn't an NSDocument). Reload on out-of-band edit, prompt on conflict.
- **WKWebView process model & memory budget reconciliation:** macOS 12+ shares a single Web Content process across all WKWebViews in an app by default — `WKProcessPool` is deprecated as a no-op. The preview WebView is created lazily (markdown hybrid-live-preview uses only the editor WebView; the second WebView only spawns for CSV/JSON/HTML preview in V1.1+). Editor WebView is preloaded at app launch (`loadHTMLString("")`) to shave 150–250 ms off cold launch by warming up the shared process. **Budget math:** measured baseline of one WKWebView + CM6 + our shell on macOS 14 (Sonoma) is ~60–80 MB; with one shared process pool, a second preview WebView adds ~15–25 MB (same process, separate frame). V1.0 (md/txt only, one WebView) fits the 80 MB idle / 120 MB loaded budgets comfortably. V1.1 (two WebViews when previewing csv/json/html) pushes loaded RSS toward the 200 MB ceiling. **Trigger for the iframe fallback:** V1.1 includes `Tests/MemoryBudget.swift` that opens a 1 MB `.csv` with one comment and a 1 MB `.md` with one comment in sequence; if measured loaded RSS (`mach_task_basic_info.resident_size`) exceeds **170 MB** (85% of the 200 MB ceiling) on M-series, the two-WebView design is rejected and V1.1 ships with one WebView + two iframes instead. The fallback is scaffolded in V1.0 so the swap is one file change.
- **Canonicalization module:** a single `TextCanon.swift` is the only code that does line-ending normalization (CRLF→LF), Unicode normalization (NFC), and UTF-16 offset arithmetic. All three concerns intersect at anchor boundaries (emoji, surrogate pairs, combining marks at line breaks); centralizing them prevents off-by-one bugs. Fuzz-tested against the corpus before any anchor code lands.
- **Build:** XcodeGen + Makefile, same as PreviewMD.
- **Distribution:** Direct download + Homebrew cask. App Store is a follow-on, not a blocker.

### Why CodeMirror 6 over native NSTextView

Three reasons: (a) MarkEdit ships a feels-native macOS editor on CM6+WKWebView and the power-user community accepts it as native; (b) TextKit 2 is still buggy per Krzyzanowski (Aug 2025) — viewport jitter, FB9886911, Apple's own NSTextView doesn't opt in by default; (c) markdown live-styling + multi-cursor + find + fold + vim mode on TextKit 2 from scratch is multi-month work versus `npm install` on CM6.

IME risk on CM6 is real and the largest hidden cost. Mitigation, layered:

1. Pin CM6 to a specific minor version; never auto-bump.
2. Regression corpus of 30 CJK input scenarios (Pinyin, Kana, Hangul, Wubi, Cangjie) — CI runs on every CM6 or bridge change.
3. Subscribe to `codemirror/dev` IME-tagged issues; open CJK composition bug = hard block on upgrade.
4. Escape hatch: the editor surface is fully replaceable via the bridge protocol. Swap CM6 for STTextView or NSTextView+TextKit 2 changes only the editor pane — bounded rewrite. Trigger: if full-fidelity Writing Tools inside the edit surface or deep AX is required, migrate then.

### Project Layout

```
md-editor/
├── App/             SwiftUI app shell, NSDocument subclass, window management
├── Editor/          WKWebView host, CM6 bundle, Swift⇄JS bridge (selection, comments, file ops)
├── Comments/        Sidecar reader/writer, anchor resolver, margin UI overlay
├── Sidebar/         File browser (single folder, no vault)
├── Preview/         (depends on shared rendering package; just a render call)
├── Bridge/          Bidirectional message protocol between Swift and the CM6 webview
└── Tests/           Anchor-drift tests, sidecar round-trip tests, CM6 bridge tests

../preview-md-shared/   (new Swift package; consumed by both md-editor and preview-md)
└── Sources/Shared/  MarkdownRenderer, FrontmatterParser, HTMLConverter, HTMLTemplate, HTMLUtils
```

## Commenting Design

Borrowed from the W3C Web Annotation Data Model + Hypothesis's three-selector cascade. This is the most-validated drift-tolerant anchor design in the web; we have no reason to invent our own.

### Sidecar file

`foo.md` ⇒ `foo.md.comments.json` (sibling, same dir, same basename).

```json
{
  "version": 1,
  "document": {
    "path": "foo.md",
    "sha256": "..."        // tripwire for out-of-band edits
  },
  "comments": [
    {
      "id": "c_01HXYZABC...",
      "createdAt": "2026-05-23T14:00:00Z",
      "author": { "kind": "human", "name": "ag" },
      "body": "@claude rethink step 3 — won't work with the new API #bug #api-v2",
      "mentions": [{ "kind": "agent", "name": "claude" }],
      "tags": ["bug", "api-v2"],
      "resolved": false,
      "addressable": true,           // implied by @claude mention; an AI agent should attempt to address this
      "target": {
        "selectors": [
          { "type": "TextPositionSelector",
            "start": 1423, "end": 1467,
            "startLine": 42, "endLine": 43 },
          { "type": "TextQuoteSelector",
            "exact": "Step 3: rebuild the cache on every write",
            "prefix": "...up to 32 chars immediately before...",
            "suffix": "...up to 32 chars immediately after..." }
        ]
      },
      "thread": [
        { "author": { "kind": "ai", "model": "claude-opus-4-7" },
          "createdAt": "2026-05-23T14:12:00Z",
          "body": "Switched to invalidation on write; see commit abc123" }
      ]
    }
  ]
}
```

### Selector types (one set per format family)

All anchors share the W3C Web Annotation cascade pattern (try selectors in order, fall back on drift). But the *kinds* of selector depend on the format.

**Text formats (`.md`, `.txt`, `.html`, JSON in source mode, CSV in source mode):**

- `TextPositionSelector` — `{ start, end, startLine, endLine }`. UTF-16 code unit offsets (CM6 native); 1-indexed line numbers redundant for human inspection.
- `TextQuoteSelector` — `{ exact, prefix, suffix }`. NFC-normalized Unicode strings. 32 grapheme clusters of prefix/suffix (Hypothesis's tested sweet spot — see [their fuzzy anchoring post](https://web.hypothes.is/blog/fuzzy-anchoring/)).

**CSV-specific (when anchored in table view):**

- `CSVCellSelector` — `{ rowIndex, columnIndex, headerName? }`. 0-indexed row (excluding header), 0-indexed column. `headerName` snapshotted at anchor time so re-anchoring survives column reordering.
- `CSVRowRangeSelector` — `{ startRowIndex, endRowIndex, primaryKeyColumn?, primaryKeyValue? }`. The primary-key fields, if set in the per-file settings, let an anchor survive row reordering or insertion-above.
- Always also store a `TextPositionSelector` over the raw source — that's the universal fallback if the table re-render fails or row math drifts.

**JSON-specific (when anchored in tree view):**

- `JSONPointerSelector` — `{ pointer }`. RFC 6901 JSON Pointer (e.g. `/users/3/email`). The canonical structural anchor.
- `JSONValueSelector` — `{ valueHash }`. SHA-256 of the canonical (sorted-keys, no-whitespace) serialization of the anchored subtree, for "did this value change?" detection.
- Always also store a `TextPositionSelector` over the raw source.

**PDF-specific:**

- `PDFAnnotationSelector` — `{ pageIndex, rect: { x, y, width, height }, quadPoints?, selectedText? }`. `pageIndex` is 0-based. `rect` is in PDF user-space coordinates (origin lower-left, units 1/72 inch — the PDF convention). `quadPoints` (per the PDF 1.7 spec) carries the per-line bounding boxes of a multi-line text selection so highlight rendering is exact. `selectedText` is the OCR/text-layer-extracted string at anchor time, used for drift recovery if the PDF file is replaced with a new version (e.g., re-exported report).
- No text-position fallback (PDF isn't text). Drift recovery uses `selectedText` quote-matching against the new PDF's text layer.

**Units (universal, read this carefully):**

- `document.sha256` is computed over the file's **raw bytes** on disk, normalized to LF line endings before hashing (we always write LF; CRLF input is normalized on read). **CSV exception:** CSV preserves the input's line terminator on save (CRLF per RFC 4180 or whatever it had); for the sidecar's `document.sha256`, the hash is *still* computed over the LF-normalized form so the tripwire is stable across machines that might transit the file through tools that flip line endings.
- `TextPositionSelector.start` / `end` are **UTF-16 code unit offsets** into the normalized-LF string.
- `TextPositionSelector.startLine` / `endLine` are **1-indexed line numbers**.
- `CSVCellSelector` / `CSVRowRangeSelector` indices are 0-indexed; row 0 is the first data row (the header is *not* a row).
- `JSONPointerSelector.pointer` follows RFC 6901 strictly (including the `~0`/`~1` escapes for `~`/`/`).

**On file open (text-format cascade):**

1. If `document.sha256` matches the file bytes (after LF normalization), use `TextPositionSelector` directly. O(1) attach. Done.
2. Otherwise, run `TextQuoteSelector`:
   a. Find all occurrences of `exact` (NFC-normalized).
   b. Exactly one match → attach; recompute position selector; stage sidecar update on next save.
   c. Multiple matches → pick the one whose surrounding 32 graphemes best match `prefix` + `suffix` via Bitap. If best match has edit-distance ≤ 4 and is uniquely best, attach. Otherwise: orphan.
   d. Zero matches → try Bitap over the full document with `exact` as the pattern (edit distance ≤ 2 per 50 chars of `exact`). Unique candidate → attach with `driftRecovered: true` flag. Otherwise: orphan.

**On file open (CSV-specific cascade, when in table view):**

1. If `document.sha256` matches: use `CSVCellSelector` / `CSVRowRangeSelector` directly. Done.
2. Otherwise, if `headerName` is present and unchanged, recompute `columnIndex` from the header → cell anchor restored unless the row was deleted.
3. If `primaryKeyValue` is present, scan the column for that value → row anchor restored regardless of row reordering.
4. Otherwise fall back to the `TextPositionSelector` cascade (above) on the raw CSV source.
5. If everything fails, orphan.

**On file open (JSON-specific cascade, when in tree view):**

1. If `document.sha256` matches: use `JSONPointerSelector` directly. Done.
2. Otherwise, try the pointer first — if the path still resolves, attach (note: value may have changed; surface `valueHash` mismatch as a "value drifted" indicator on the comment).
3. If the pointer no longer resolves, fall back to `TextPositionSelector` over the raw JSON source. CSV-style recovery does not apply here.
4. If everything fails, orphan.

**Orphan handling (universal):** orphaned comments are **never silently dropped**. They appear in a "Needs reattach" sidebar section (a collapsed disclosure group under the file list) with: the original `exact` quote / pointer / valueHash, ~3 lines of original surrounding context, the date the orphan occurred, and a "Reattach selected" button that activates when the user selects text in the editor. Reattaching writes the new selectors and flips `status` back to `active`.

### Empty, loading, error, and conflict states (specifically designed, not implied)

| Situation | What the user sees |
|---|---|
| **App launched, no document yet** | A welcome window: "Open a file (Cmd-O), drag one here, or `mdedit foo.md` from the shell." Footer link to the user guide. Single primary button: Open File. |
| **Document opening (>50 ms render)** | Skeleton renderer placeholder (gray bars matching the rendered layout) for files >50 KB; for files <50 KB, render is fast enough that no placeholder shows. |
| **File too large for rendered preview** | Inline banner above source: "File too large for rendered preview (XX MB > 5 MB limit) — showing source. [Render anyway]" link if the user wants to opt in. |
| **CSV reformatted to RFC 4180 on save** | Toast (auto-dismiss after 5 s): "Saved — reformatted to comma-delimited CRLF per RFC 4180. [Undo]" The undo restores the original. |
| **Source file edited out-of-band, no edits in app** | No UI; reload silently. |
| **Source file edited out-of-band, app has unsaved edits** | Modal sheet: "File changed on disk. Your unsaved changes are still here. [Keep my version] [Discard mine and reload] [Show diff]." |
| **Sidecar conflict (git merge)** | App refuses to open; banner pointing to `mdedit merge-comments foo.md.comments.json` with one-line explainer. |
| **Comment anchor orphaned mid-session** | Inline gutter indicator flips to a hollow circle with a tooltip; orphan moves into the Needs Reattach sidebar group. |
| **JSON `valueHash` drift detected** | Comment indicator gets a small "·" dot overlay; clicking the indicator shows the old vs current value diff at the top of the thread inspector. |
| **`.md` renamed via Finder; sidecar still in old location** | On next open of either file, modal: "Found `oldname.md.comments.json`. The original file appears to have moved. [Rename sidecar to match] [Keep separate] [Help]." |
| **`.md` deleted, sidecar remains** | Sidecar shows in Sidebar's "Orphaned comments" section; clicking opens a read-only view of the comments with no editor pane. |
| **Save failed (disk full, permissions)** | Modal sheet: "Couldn't save `foo.md`. [actual NSError reason]. [Try again] [Save As...] [Cancel]." NSDocument default behavior; we don't suppress it. |
| **Updater offline / appcast unreachable** | No UI on automatic check; "Check for Updates..." (manual) shows: "Couldn't reach the update server. [Try again] [Cancel]." |
| **Crash on a previous run, opt-in to share** | One-time alert on next launch: "MD Editor crashed last time. Help → Copy Crash Log copies it to your clipboard so you can email it. [Don't ask again]." Off by default; user must explicitly opt in to even see the offer. |

**Why each format has its own cascade:** the universal `TextPositionSelector` fallback always works, but it loses structural meaning. A comment on a CSV row that re-anchors by text position will jump to a wrong line if rows were reordered; the `primaryKeyValue` lookup restores semantic intent. Same for JSON — pointer-based anchoring survives reformatting that text positions can't.

### `valueHash` drift indicator (JSON only)

When a `JSONPointerSelector` resolves but its current subtree's canonical hash no longer matches the stored `valueHash`, the comment attaches *but* the UI surfaces a small "value drifted" badge in the margin gutter — the comment's text may now reference a value that no longer exists. The user can: click the badge to see a diff of old-value vs new-value, mark the comment resolved, or update the anchor (re-snapshots the hash). The drift never blocks attach.

### Cross-view selector translation (Cmd-E mid-session)

When a user authors a comment in the table view (CSV) or tree view (JSON), then flips to source view via Cmd-E, the comment must remain visible at the source-position equivalent. The bridge translates as follows:

- **CSV table → source:** the cell's byte range in the source string is computed from the CSV parser's row/column index table (built once per load, invalidated on edit). The translated `TextPositionSelector` is sent to CM6 via `comments.set`. Cell semantics are preserved by *also* keeping the `CSVCellSelector` in the sidecar — when the user flips back to table view, the structural selector is used directly.
- **JSON tree → source:** the JSON parser preserves a (pointer → source-range) map for the loaded document. Pointer lookup gives the byte range; same translation pattern.
- **Source → structured:** when a comment is authored in source view on a CSV/JSON file, only `TextPositionSelector` is initially stored. On first flip to table/tree view, the app attempts to derive the structural selector and writes it back to the sidecar. If derivation fails (e.g., the position falls inside whitespace between JSON nodes), only the text selector is kept.

Both halves of the round-trip are tested in `Tests/SelectorTranslation.swift` (V1.1).

### Why sidecar (not CriticMarkup or inline comments)

The `.md` stays canonical and renders identically in every other markdown tool. The sidecar carries author, timestamp, thread, resolution, AI-agent metadata — fields CriticMarkup has no room for. Diff cleanly in git: comment churn never touches content. The two-file atomicity risk is real and explicitly addressed below.

### Sidecar lifecycle (the hard cases)

| Event | Behavior |
|---|---|
| **Out-of-band edit to `.md`** (vim, agent, another app) | File watcher fires. Recompute hash, mismatch detected. Re-run anchor resolution for all comments; update positions; persist sidecar with new `document.sha256`. User sees no UI unless comments orphan. |
| **Out-of-band edit to sidecar** (agent appends a reply, marks resolved) | File watcher fires. Reload sidecar in-place. UI re-renders. |
| **`.md` renamed via Finder** | We don't see it (no FS-wide watcher). On next open of either file, detect orphan: if user opens the renamed `.md`, prompt "Found `oldname.md.comments.json` — adopt? rename? ignore?". If user opens the sidecar by mistake, route to its document. |
| **`.md` deleted, sidecar remains** | On editor next launch with the sidecar's directory open, surface a "Orphaned comments" item in the sidebar. Never auto-delete user data. |
| **Sidecar deleted, `.md` remains** | Treated as "no comments." Fine. No recovery — git is the source of truth if the user wanted history. |
| **Git merge conflict in sidecar** | The JSON is structured to minimize conflicts: comments are an array sorted by `id` (ULID, time-ordered). Conflicts almost always look like "both sides appended new comments" — git auto-merges. For real conflicts (same comment edited two ways), we ship a `mdedit merge-comments foo.md.comments.json` command that opens a 3-way picker. Tested cases in V1: append/append, edit/edit, edit/delete. |
| **Two-machine concurrent edit** | Same as git merge above — last write wins on a per-comment basis if no version control, structured merge if git is involved. We document "use git or accept last-write-wins" rather than building a CRDT. |
| **Comment-id collisions** | IDs are ULIDs (Crockford base32, 26 chars, time-ordered, random tail). Birthday-collision probability for 10⁹ comments is ~10⁻¹². If a collision ever surfaces, the loader detects duplicate ids on load and refuses to open with a clear error. |
| **`addressable` field semantics** | Default `false` on human-authored comments. **Auto-derived on save** from the body — any `@<known-agent>` mention (`claude`, `gemini`, `codex`, `apple-intelligence`) flips `addressable: true`. Implemented by `CommentSidecar.deriveStructured(_:)`. UI also exposes an explicit "Address with AI" checkbox for users who prefer no inference. Only the original human author can flip the flag (manually or via mention); AI thread replies cannot set `addressable: true` on the parent. |

### Agent loop (the differentiator)

A Claude Code run sees `foo.md.comments.json` like any other JSON file. Filter `resolved == false && addressable == true`. Address each comment by editing the `.md`. Append a reply to the comment's `thread` array. Flip `resolved: true`. Write back. No new tool, no new SDK — the schema *is* the API.

## V1 Scope

**V1 is split into two milestones. PDF is a separate V2.** No calendar estimate — they take as long as they take.

- **V1.0 — Markdown & text foundation.** Ships `.md` and `.txt` with preview-by-default, hybrid live preview + Focus mode, commenting with W3C-style anchor cascade (TextPosition + TextQuote), sidebar, CLI agent loop, Bridge protocol (V1.0 subset), PreviewMD `Shared/` extraction (Story 0), basic Finder integration (registered opener, drag, `mdedit` CLI), NSFileVersion-backed history (free via NSDocument). Comment schema includes `mentions`/`tags` fields; UI autocomplete for them is V1.1.
- **V1.1 — Multi-format text expansion + UX polish.** Adds `.csv`, `.json`/`.jsonl`/`.ndjson`, `.html` with their renderers and format-specific anchor selectors (CSVCell/CSVRowRange, JSONPointer/JSONValue); preview-side commenting overlay; Services menu (incl. "Add Comment to Selection"); Finder Sync badge; Spotlight importer; @mention/#tag autocomplete; comment-history "Show resolved" + "Show archived" toggles; agent-edit log; side-by-side version diff; Notion-style inline editing (slash commands, markdown shortcut conversion, drag-to-reorder blocks, block hover actions).

Both milestones are V1 — V1.0 isn't a "real" release on its own; we don't announce until V1.1 is done.

**V1.0 → V1.1 transition gate (measurable, not vibes):**
- V1.0 dogfooded for 30 consecutive days by the author. **"Daily use" defined**: on each of the 30 days, at least one session of ≥5 minutes wall-clock time *with at least one of {save, comment created, comment resolved}* — pure-launch days don't count. Logged via `os_signpost` to a system log queryable with `log show --predicate 'subsystem == "com.mdedit.dogfood"'` (not a writable file the user can edit). A `scripts/dogfood-report.sh` reads the log and reports `qualifying_days / 30`.
- All V1.0 stories pass CI (every AC above, green for a week of pushes).
- No P0 correctness bugs open (mis-anchor rate >0%, lost comments, corrupt round-trip, OOM crash).
- Performance budgets met (speed + resource + correctness tables in Success Metrics).

Only after these four conditions hold does V1.1 start. This keeps "V1.0 dogfooded internally" from being a fuzzy gate that lets scope creep back in.

**V2 — PDF.** Adds `.pdf` viewing via PDFKit, `PDFAnnotationSelector` commenting, Live Text on scanned pages, on-device Foundation Model "Address with Apple Intelligence" Services entry. Separate release because PDF + PDFKit + PDF coordinate anchors + Live Text + Foundation Models is the riskiest, most-different subsystem in the doc and shouldn't gate V1 announce.

### V1.0 stories with acceptance criteria

0. **Extract `preview-md-shared` package + measure MarkEdit baseline + ship `TextCanon`** (prerequisite to all other stories). Three substeps:
   - **0a — Extract `preview-md-shared`.** Convert PreviewMD's `Shared/` into a standalone Swift Package. Move embedded CSS/JS string constants in `HTMLTemplate.swift` to package resources; bundle `mermaid.min.js` and KaTeX fonts. Point PreviewMD's `Package.swift` at the new package; MD Editor depends on the same version.
     - *Accept:* PreviewMD's existing 103 tests pass against the package. MD Editor renders `Tests/Fixtures/md/10kb.md` byte-equal-HTML to PreviewMD on the same fixture. Both CIs green.
   - **0b — Measure MarkEdit baseline.** `scripts/measure-markedit-baseline.sh` automates: launch MarkEdit on each `Tests/Fixtures/{md,txt}/{10kb,100kb,1mb}.{ext}` fixture, capture cold-launch time (`os_signpost`), typing-latency p95 (1000 scripted keystrokes via Accessibility API), and idle/loaded RSS via `ps -o rss`. Output: `baselines.json`. CI thresholds for Stories 1 and 2 read from this file — the placeholders in their ACs get *replaced*, not deleted.
     - *Accept:* `baselines.json` is committed; Stories 1/2 ACs evaluate against `baselines.json × multiplier` rather than hardcoded numbers.
   - **0c — Ship `TextCanon.swift`.** Single module that owns CRLF→LF normalization, NFC normalization, UTF-16 offset arithmetic. No other code in the repo may touch these concerns — enforced by `Tests/CanonOwnership.swift` using **SwiftSyntax** (AST-level, not text grep) to walk every source file and fail CI on any direct call to `.precomposedStringWithCanonicalMapping`, `.utf16.count`, `.utf16.distance(...)`, `.replacingOccurrences(of: "\r\n"...)`, or raw `\r\n` string literals — outside `TextCanon.swift` itself and an explicit `Tests/CanonOwnershipAllowlist.txt` (one file per line, reviewed in PR).
     - *Accept:* `Tests/CanonFuzz.swift` runs 10,000 random Unicode strings (heavy on emoji, ZWJ sequences, combining marks at line boundaries, surrogate-pair-crossing offsets) through round-trip canonicalize→hash→re-anchor; zero mismatches. Coverage ≥95% on `TextCanon.swift`. `Tests/CanonOwnership.swift` passes against the current allowlist; growing the allowlist requires a PR comment justifying each addition.
1. **Open and read** — Open `.md` or `.txt` from Finder, double-click, or `mdedit foo.<ext>`. File renders in format-appropriate preview. Reading view by default.
   - *Accept (automated):* `Tests/RenderPerformance.swift` opens fixtures `Tests/Fixtures/{md,txt}/{10kb,100kb,1mb}.{ext}` and records first-paint via `CFAbsoluteTimeGetCurrent` around `didFinishInitialLoad`. **Initial targets:** <100 ms / <150 ms / <300 ms. Baseline = MarkEdit on the same fixtures; CI threshold = MarkEdit × 1.5. `Tests/RenderFidelity.swift` snapshots rendered HTML; diff must be empty.
   - *Accept (automated):* `Tests/ColdLaunch.swift` measures `mdedit foo.md` end-to-end (process spawn → first paint) via `os_signpost`. Target: <500 ms cold on M-series; CI fails above 700 ms.
   - *Accept (manual, one-time):* dark mode toggle in System Settings flips the editor without reload.
2. **Edit inline** — Click into a paragraph; CodeMirror surface activates with live-styled markdown (markers visible only on the active line); Cmd-E toggles full source mode.
   - *Accept (automated):* `Tests/TypingLatency.swift` injects 1000 single-keystroke bridge messages into `Tests/Fixtures/10kb.md`; records p95 round-trip time (Swift→JS→Swift `onChange`). **Initial targets:** p95 <8 ms M-series, <16 ms Intel. Baseline = MarkEdit on the same fixture on the same hardware; CI threshold = baseline × 1.25. Numbers are placeholders until measured against the baseline. `Tests/IME.swift` replays the 30 scripted CJK input sequences in `Tests/Fixtures/ime/*.json`; final document state must match `expected.txt` byte-for-byte for each.
3. **Save** — Cmd-S writes the file. **NSFileCoordinator-mediated atomic replace** (the OS performs the temp-and-swap; we never call `rename(2)` directly because that bypasses NSFileVersion). Frontmatter preserved byte-for-byte. LF line endings for `.md`/`.txt` (CSV preserves the input's terminator, per RFC 4180 — see Story 8).
   - *Accept (automated):* `Tests/RoundTrip.swift` reads each file in `Tests/Fixtures/corpus/` (≥50 real-world `.md` files: READMEs, plans, specs, frontmatter-heavy docs), opens via the document model, saves without editing through `NSDocument.write(...)` (which invokes the coordinator-mediated atomic path), then asserts the saved bytes are identical to the input — **with one allowed normalization:** CRLF→LF on input only for `.md`/`.txt`. Any other diff is a failure. Also asserts `NSFileVersion.unresolvedConflictVersions(of:)` returns nil and `NSFileVersion.otherVersionsOfItem(at:)` returns ≥1 after the save (Versions is wired up).
4. **Comment** — Select text → Cmd-Shift-M → margin thread appears. Reply, resolve, delete. Sidecar JSON written next to the file.
   - *Accept (automated):* `Tests/CommentRoundTrip.swift` creates 100 random comments across the corpus, writes the sidecar, reads it back, asserts deep equality. Asserts JSON output is stable (same input → byte-identical sidecar) and sorted by `id`.
5. **Anchor drift** — Edit `.md`/`.txt` outside the app; reopen — anchors re-resolve.
   - *Accept (automated):* `Tests/AnchorDrift.swift` runs `EditGenerator.swift` against each corpus file: for each comment, apply each of {insert-line-above, delete-line-above, insert-line-below, delete-line-below, edit-within-anchored-text-by-1-char, edit-within-anchored-text-by-5-chars, duplicate-anchored-text-elsewhere, prepend-1KB, append-1KB, reflow-paragraph}. **Pass bar:** ≥95% re-anchor; ≤5% must orphan; CI fails if mis-anchor rate >0%. Drift report at `drift-report.json`.
6. **Sidebar** — Single-folder file browser. Filters to `.md`/`.txt` by default; toggle to show all. No vault, no wiki-links.
   - *Accept (manual):* opening a folder shows its files; clicking opens in the same window; no startup hang on a 5,000-file directory.
7. **Agent loop, manual** — Documented JSON schema (`docs/comments-schema.md`) + CLI: `mdedit comments <file> --unresolved --addressable` prints matching comments as JSON to stdout; `mdedit comments <file> --resolve <id> --reply <text>` appends a reply and flips `resolved: true`.
   - *Accept (automated):* `Tests/CLI.swift` runs the CLI against `Tests/Fixtures/comments-loop/*.json`, asserts output matches `expected/*.json`.
   - *Accept (manual, one-time):* hand a Claude Code agent the schema file and an unresolved-comment sidecar; verify it produces a valid resolved sidecar in 5/5 trials.

### V1.1 stories with acceptance criteria

8. **CSV preview + source edit** — `.csv` opens in a sortable HTML table view. Cmd-E flips to syntax-highlighted source.
   - *Accept (automated):* `Tests/CSVRender.swift` opens fixtures with widths {3, 10, 50, 200} columns and heights {100, 10k, 500k} rows; asserts the table renders without paint regression. Sort-on-header-click test asserts the visible row order matches an in-memory sort by that column. Render time targets: <300 ms for 10k rows, <2 s for 500k rows.
   - *Accept (automated):* `Tests/CSVParse.swift` parses 50 real-world CSVs (varied delimiters, quoting, embedded newlines); reads + serializes back; round-trip is **byte-identical for RFC 4180-compliant inputs**. For noncompliant inputs, output follows a defined canonical form: comma delimiter, CRLF row terminator, all fields containing `,` / `"` / `\r` / `\n` are quoted, embedded `"` escaped as `""`, no trailing newline added. Test asserts (a) the canonical form is a valid RFC 4180 document, (b) re-parsing the canonical form gives the same in-memory rows, (c) original→canonical is *idempotent* (canonical→canonical is byte-identical). Saving a noncompliant file shows a one-time "File was reformatted to RFC 4180" toast.
9. **JSON preview + source edit** — `.json` opens in a collapsible tree view; `.jsonl` opens as a streamed record list. Cmd-E flips to source with bracket folding.
   - *Accept (automated):* `Tests/JSONTree.swift` renders fixtures up to 10 MB; asserts collapse/expand state persists across re-render; asserts JSONPointer-on-click copies the right pointer to clipboard.
   - *Accept (automated):* `Tests/JSONLStream.swift` opens a 50 MB `.jsonl` fixture; asserts rendering is progressive (first 100 records visible within 200 ms; full render within 5 s); asserts no UI hang.
10. **HTML preview + source edit** — `.html` renders in a sandboxed WKWebView (JS disabled, network blocked, strict CSP). Cmd-E flips to source.
    - *Accept (automated):* `Tests/HTMLSandbox.swift` opens fixtures that attempt to fetch external resources / execute JS; asserts zero network requests and zero `console.log` output reaches the host. Asserts inline images and CSS still render.
11. **Format-specific commenting** — Comments anchored to CSV cells/rows or JSON pointers persist across edits.
    - *Accept (automated):* `Tests/CSVAnchorDrift.swift` applies {sort-by-column, insert-row-at-N, delete-row-at-N, rename-column, edit-cell-value} to CSV fixtures with anchored comments; asserts ≥95% re-anchor via primaryKey/headerName recovery; mis-anchor rate must be 0%.
    - *Accept (automated):* `Tests/JSONAnchorDrift.swift` applies {reorder-keys, add-sibling-key, remove-sibling-key, edit-value, reformat-whitespace} to JSON fixtures; asserts JSONPointer-anchored comments survive; mis-anchor rate 0%.
12. **Sidebar shows all formats** — sidebar default filter expands to `.md`/`.txt`/`.csv`/`.json`/`.jsonl`/`.ndjson`/`.html`/`.htm`.
    - *Accept (manual):* dropping a folder with mixed formats shows all by default; filter chips at the top toggle individual formats.

### Non-goals (V1)

- **Not an IDE.** No language servers, debuggers, linters, git UI, test runner, extensions.
- **Not a spreadsheet.** CSV is viewed as a table, edited as text. No formulas, charts, pivots — use Numbers.
- **Not a notebook.** JSON is viewed as a tree, edited as text. No query bar, schema validation, `jq` integration — use a notebook.
- **Not a web inspector.** HTML renders sandboxed. No DOM inspector, no devtools.
- No structured editing for non-markdown formats (edit-in-cell CSV, edit-in-tree JSON, visual HTML edit). Source-mode only. Deferred beyond V1.
- No format conversion. One format in, same format out.
- No wiki-links, backlinks, graph view, vault, tabs-across-folders, global hotkey, quick-capture window.
- **No plugin system, ever.** Obsidian's plugin model is both a feature and the source of every "Obsidian is fragile" complaint — the trade is intentional. No theme system beyond light/dark.
- No sync (iCloud/Dropbox/git work because we're plain files).
- No real-time collaboration. Comments are async by design.
- No mobile, iPad, web. macOS 14+ only.
- No paid tier, subscription, telemetry.
- **No first-party AI chat panel, sidebar, or inline LLM cursor.** Schema is the API; Claude Code is the client. OS-level Apple Intelligence (Writing Tools, Summarize, on-device Foundation Model via Services menu) is in scope — those are macOS features that every text app gets, not first-party AI UI we author.
- No CriticMarkup, no content sniffing (extension-only).
- No files above the per-format ceiling rendered (source-mode with banner).

### What V1 ships against

- **Replaces** `vim`/`code` for the user's own `.md` review workflow.
- **Beats** MarkEdit for users who want preview-by-default + comments.
- **Ignores** Obsidian users — they have a working tool; we're not for them.

## Success Metrics

Every metric below is **verifiable** — either a CI assertion, a one-line script, or a manual procedure with a pass/fail. No vibes. If any of these regress, V1 isn't done.

### Speed budgets (the headline)

| Metric | Target | Hard ceiling | How measured |
|---|---|---|---|
| **Cold launch** (process spawn → first paint) | <500 ms M-series | 700 ms | `Tests/ColdLaunch.swift` via `os_signpost`; CI runs on each push |
| **Warm launch** (app running → open another file) | <100 ms | 200 ms | `Tests/WarmLaunch.swift` opens 10 files in sequence; reports p95 |
| **Open 10 KB / 100 KB / 1 MB `.md`** | <100 / <150 / <300 ms | ×1.5 of target | `Tests/RenderPerformance.swift` |
| **Open 10k-row CSV (V1.1)** | <300 ms | 500 ms | `Tests/CSVRender.swift` |
| **Open 500k-row CSV (V1.1)** | <2 s | 4 s | `Tests/CSVRender.swift` |
| **Open 10 MB JSON tree (V1.1)** | <1 s to first paint, progressive | 2 s | `Tests/JSONTree.swift` |
| **Typing latency** (p95 keystroke → on-screen) | MarkEdit baseline × 1.0 (initial placeholder: <8 ms M-series, <16 ms Intel) | MarkEdit baseline × 1.25 (initial placeholder: <10 ms / <20 ms) | `Tests/TypingLatency.swift` — placeholders frozen until baseline measured in Story 0 |
| **Scroll** (rendered preview, 10k-line markdown) | 60 fps sustained | 30 fps min | `Tests/ScrollPerformance.swift` via `CADisplayLink` sampling |
| **CPU at idle** (file open, no input) | 0% (no polling, no timers) | <0.5% | `Tests/IdleCPU.swift` — sample `task_info` for 30 s |
| **CPU during typing** (sustained 10 keystrokes/sec) | <10% one core | <20% | `Tests/TypingCPU.swift` |

### Resource budgets

| Metric | Target | Hard ceiling | How measured |
|---|---|---|---|
| **Binary size** (signed `.app` bundle) | <10 MB | 15 MB | `Tests/BinarySize.sh` after `make release` |
| **Disk footprint** (install + caches + agents) | <15 MB | 25 MB | `du -sh /Applications/MDEditor.app ~/Library/Caches/mdedit` |
| **Idle RSS** (app running, no file open) | <80 MB | 120 MB | `Tests/MemoryFootprint.swift` reads `mach_task_basic_info.resident_size` |
| **Loaded RSS** (1 MB `.md` open in hybrid preview) | <120 MB | 200 MB | Same test, file open |
| **Loaded RSS** (10 MB JSON tree fully expanded — V1.1) | <250 MB | 400 MB | Same test, fully expanded |
| **Memory growth** (open 100 files in sequence, close each) | <10 MB net growth | 30 MB | `Tests/MemoryChurn.swift` |
| **No memory leaks on document close** | RSS returns to within 5 MB of pre-open | 15 MB | Subset of above |

### Correctness budgets

| Metric | Target | How measured |
|---|---|---|
| **Round-trip save** (save w/o edit produces byte-identical file) | 100% on RFC-compliant corpus | `Tests/RoundTrip.swift` over ≥50 corpus files |
| **Anchor re-attach rate** (after standard edit suite) | ≥95% | `Tests/AnchorDrift.swift` (md/txt; V1.1 adds csv/json) |
| **Mis-anchor rate** | 0% | Same test — orphans OK, wrong attaches fail CI |
| **IME correctness** (30 CJK scenarios) | 30/30 | `Tests/IME.swift` |
| **HTML sandbox** (no JS, no network) | 0 outbound requests, 0 console.log | `Tests/HTMLSandbox.swift` (V1.1) |
| **Sidecar round-trip** (write 100 random comments, read back) | Deep equality | `Tests/CommentRoundTrip.swift` |

### Ease-of-use budgets

| Metric | Target | How measured |
|---|---|---|
| **Permission prompts on first launch** | 0 (no mic, no location, no contacts, no calendar, no Apple Events) | Manual: factory-reset Mac, install, launch, count dialogs |
| **Onboarding screens before first useful interaction** | 0 — app opens to a file | Manual |
| **Time to comment on a sentence** (new user, no docs) | <30 s from cold launch | Manual: time a non-technical macOS user through the task |
| **Clicks to open a file** | 1 (double-click in Finder) or 0 (drag-to-icon) | Manual |
| **Clicks to add a comment** | 2 (select + Cmd-Shift-M or right-click → Add Comment) | Manual |
| **Clicks to save** | 1 (Cmd-S) | Manual |
| **Standard macOS shortcuts honored** | Cmd-O/S/W/F/Q/Z, Shift-Cmd-Z, Cmd-+/-, all menu shortcuts | `Tests/Shortcuts.swift` simulates each, asserts expected action |
| **Crash-free session rate** | >99.9% | `os_log` crash signpost; tabulate over dogfooding period |

### Adoption signals (post-release)

- **Dogfood gate:** author uses it daily for AI-output review for 30 consecutive days before announcing V1.1. V1 isn't done without this.
- **External pull:** at least one external contributor PR merged after public release.
- **Unsolicited stars:** GitHub stars from people the author has never met. Provenance > number.
- **Replacement test:** during the dogfooding period, count trips to VS Code/Cursor that were *just* to glance at or lightly edit an AI-produced file. Target: drops ≥80%.

### Kill criteria (when to stop)

V1 ships even if these are violated, but V2 (PDF) does not start unless:

- Author reaches the dogfood-gate 30 days without abandoning the app.
- Replacement-test trip count drops ≥50% (below 80% is acceptable but a yellow flag worth investigating; below 50% means V2 is premature — invest in V1 polish first).
- No unresolved P0 correctness bug at the end of V1.1 dogfooding (mis-anchor rate above 0%, lost comments, corrupt round-trips, OOM crashes on supported file sizes).
- Performance budgets still met after V1.1 feature additions (cold launch <500 ms; idle RSS <80 MB). If V1.1's Notion-style editing + multi-format renderers push us out of budget, fix performance before V2.

### Concentrated risks

- **Story 0 is the choke point.** All three substeps (preview-md-shared extraction, MarkEdit baseline measurement, TextCanon ship) must land before any other V1.0 story can start. If Story 0a stalls (e.g., PreviewMD's embedded resources resist extraction), the entire build stalls. Mitigation: 0a is mechanical refactoring; if blocked, fall back to a private copy of PreviewMD's `Shared/` inside this repo for V1.0 and re-attempt extraction in V1.1.
- **V1.1 is a bundled big-bang release** by current scoping (multi-format renderers, format-specific anchors, Notion-style editing, Spotlight/Services/FinderSync, history UI, side-by-side diff). If any one stalls, the whole release stalls. **Internal cut line** — priority for cuts is drop-first → keep-last: block hover actions → drag-to-reorder → Spotlight importer → FinderSync badge → Services menu → comment-history toggles → Notion slash menu → markdown shortcut conversion → multi-format renderers + commenting overlays. The renderers + overlays are the thesis; cut everything else first.
- **Memory-budget fallback has no second escape hatch.** If the iframe fallback also misses budget on V1.1 (after the 170 MB trigger fires), V1.1 ships in degraded mode: preview WebView is destroyed on Cmd-E flip to source and re-instantiated on flip back. Cost: ~150 ms flip latency, no preview-render incrementality. Recorded as a V1.1 "Known issues" entry, not a ship blocker.

## Relationship to PreviewMD

PreviewMD stays a Quick Look extension; MD Editor is a separate app. They share one Swift package — `preview-md-shared`, extracted from PreviewMD's `Shared/` — for the rendering engine. First build task: convert embedded CSS/JS strings into resource files, move `mermaid.min.js` into the package as a bundled resource, point PreviewMD's `Package.swift` at it, prove the existing 103 PreviewMD tests still pass.

Both MIT, both maintained by the same author.

## Relationship to MarkEdit

**MarkEdit is the closest thing to what we want, and we should be honest about that.** Same architecture (AppKit shell + CodeMirror 6 in WKWebView), same license (MIT), same "feels native" bar, same lightweight ethos. If you've used MarkEdit, our text-mode editing feels familiar by design.

Why build a separate product instead of contributing upstream:

1. **Different design centers.** MarkEdit is "a minimal source editor for markdown." We are "a viewer with a light edit surface for AI-output formats, with commenting as the design center." Same stack, different products — like Sublime Text and TextMate.
2. **Source-by-default vs preview-by-default.** MarkEdit opens to syntax-highlighted source; preview is an optional extension. We open to a rendered view; source is the escape hatch. This isn't a setting — it's the default that shapes the UX downstream.
3. **Commenting is a separate engineering system.** Sidecar JSON, W3C-style anchor cascade, drift algorithm, format-specific selectors, agent loop schema, CLI, Finder badge, Spotlight indexing. None of this fits MarkEdit's scope, and the maintainers haven't signaled they want it.
4. **Multi-format (CSV/JSON/HTML/PDF) is outside MarkEdit's surface.** Their thesis is "a great markdown editor"; ours is "a great viewer for the formats AI agents produce."
5. **We have a hard non-goal of plugins.** MarkEdit ships features as extensions you opt into. We make opinionated choices and don't ship a plugin system. Trying to fit our scope into MarkEdit's extension model would compromise both products.

**What we take from MarkEdit:** the existence proof. "Can a small team ship a feels-native macOS markdown editor on CM6+WKWebView?" Answered: yes. That removes the biggest risk from our tech stack decision. Their wiki post "Why MarkEdit" is required reading; their architecture choices inform ours.

**Where users may rationally pick MarkEdit over us:** they want a pure markdown source editor, value the extension ecosystem, don't need commenting, don't care about non-markdown formats. That's a real audience and a good product. We aren't trying to convert them.

## Decided Open Questions

- **Name:** `MD Editor` is the working name; codename `mdedit`. Final name deferred until we have a working binary.
- **Pricing:** Free, MIT, no paid tier ever. Optional GitHub Sponsors later.
- **Distribution:** Direct download + Homebrew cask first. App Store deferred (sandboxing for file-watch + sidecar is non-trivial).
- **Editor component:** CodeMirror 6 in WKWebView. Re-evaluate only if a hard product requirement forces TextKit 2.

## Still Open (intentionally)

- The `mdedit` CLI surface beyond `comments {list,resolve}`. V1 ships only what's needed to demonstrate the agent loop; broader CLI (`mdedit search`, `mdedit lint`) is a follow-on.
- Whether to add an explicit `Suggestion` comment type in V1.1 (replacement text alongside the body, accepted/rejected like Google Docs Suggesting). Out of V1; revisit after dogfooding.
- Whether the `Reading view` is read-only or accepts click-to-edit. V1 ships click-to-edit (Typora model); if dogfooding reveals accidental edits, add a "Locked" toggle.

## Appendix A: Swift⇄JS Bridge Protocol

JSON over `WKScriptMessageHandler` (Swift→JS via `evaluateJavaScript`, JS→Swift via `webkit.messageHandlers.bridge.postMessage`). Every message: `{ id, type, payload }`. Replies echo `id` with `type: "reply"` and either `result` or `error`. One channel for the editor WebView; a parallel channel for the preview WebView using the same wire format.

### A.1 — V1.0 subset (editor channel only)

**JS → Swift:**

| `type` | `payload` | Purpose |
|---|---|---|
| `editor.ready` | `{}` | CM6 finished loading; Swift may send `doc.load`. |
| `doc.changed` | `{ length, version }` | Debounced (50 ms) change notification. |
| `selection.changed` | `{ from, to, line, ch }` | UTF-16 offsets. Drives comment-affordance hover. |
| `comment.requested` | `{ from, to, exact, prefix, suffix }` | User hit Cmd-Shift-M. |
| `comment.clicked` | `{ id }` | User clicked a comment indicator. |
| `log` | `{ level, message }` | Forwarded to `os_log`. |

**Swift → JS:**

| `type` | `payload` | Purpose |
|---|---|---|
| `doc.load` | `{ text, language: "markdown"\|"plain", readOnly }` | Replace document, reset undo. |
| `doc.applyEdit` | `{ from, to, insert }` | Programmatic edit via CM6 transaction, preserving undo. |
| `comments.set` | `{ comments: [{ id, from, to, status: "active"\|"orphaned"\|"resolved"\|"archived" }] }` | Render gutter indicators. Always source-mode positions; structural selectors translated by Swift before sending. |
| `theme.set` | `{ mode: "light"\|"dark" }` | Track system appearance. |
| `find.show` | `{ query? }` | Open CM6 search; Cmd-F routes here. |

### A.2 — V1.1 additions

**Preview channel — JS → Swift** (separate WebView for CSV/JSON/HTML preview):

| `type` | `payload` | Purpose |
|---|---|---|
| `preview.ready` | `{ format }` | Preview WebView booted; Swift may send `preview.render`. |
| `preview.cellClicked` | `{ rowIndex, columnIndex, headerName? }` | CSV cell click — Swift may open comment composer scoped to the cell. |
| `preview.nodeClicked` | `{ pointer, valueHash }` | JSON tree node click. |
| `preview.commentClicked` | `{ id }` | User clicked a comment indicator in the preview view. |

**Editor channel additions — JS → Swift:**

| `type` | `payload` | Purpose |
|---|---|---|
| `mentions.autocomplete` | `{ prefix }` | User typed `@<prefix>` in composer; Swift replies with author/agent suggestions. |
| `tags.autocomplete` | `{ prefix }` | User typed `#<prefix>`; Swift replies with tag suggestions. |
| `slash.menuRequested` | `{ line }` | User typed `/` at column 0; Swift returns the slash-menu items. |
| `block.dragStarted` | `{ blockRange: { from, to } }` | User started dragging a block handle. |
| `block.dragEnded` | `{ targetLine }` | Drop completed; Swift computes the source-range move. |
| `history.requestList` | `{}` | User opened the History panel; Swift returns the NSFileVersion list. |
| `history.requestDiff` | `{ versionA, versionB }` | Swift renders both versions and replies with diff HTML. |

**Editor channel additions — Swift → JS:**

| `type` | `payload` | Purpose |
|---|---|---|
| `doc.load` | `{ text, language: "markdown"\|"plain"\|"csv"\|"json"\|"html", readOnly }` | (extended) Source-mode load for any text format. |
| `preview.render` | `{ format: "md"\|"csv"\|"json"\|"jsonl"\|"html", text, options? }` | Render in the preview WebView. |
| `preview.commentsOverlay` | `{ comments: [{ id, selector, status }] }` | Draw comment indicators in the preview (CSV gutter, JSON tree badges). |
| `slash.menuShow` | `{ items: [...] }` | Open the slash-menu picker at the current cursor. |
| `mentions.suggestions` / `tags.suggestions` | `{ suggestions: [...] }` | Reply payloads for the autocomplete requests. |
| `block.dragHandles.set` | `{ blocks: [{ range, kind }] }` | Mount drag handles in the gutter for the current viewport. |

### Error handling

Unknown reply `id` → logged and dropped. JS exception → `{ type: "reply", id, error: { message, stack } }`. Both sides time out replies at 5 s.

### Why this design

- One handler per channel, one transport, one schema.
- `id`-based correlation avoids per-call handler names.
- UTF-16 offsets everywhere — same units as the anchor schema, no conversions.
- `version` on `doc.changed` dedupes stale events when an edit lands mid-flight.
- Replaceable: the editor surface knows nothing about comments or anchors. Swap CM6 for STTextView, only the JS half changes; Swift keeps the same protocol.
- V1.0 ships only the A.1 subset; A.2 messages aren't sent or handled until V1.1 — keeps the V1.0 surface small enough for one engineer.
