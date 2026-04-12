# MD Editor — Product Vision

A native macOS markdown editor built for the AI era. Three use cases, one app, shared core.

## Thesis

Markdown files are becoming the default artifact of AI-assisted work — Claude Code outputs plans, specs, and memory as .md files. But the human side of the workflow (reviewing, commenting, organizing, capturing) has no native home. VS Code is a code editor. Obsidian is pre-AI. Google Docs isn't markdown. The gap is a native tool that treats markdown as a first-class document format with collaboration primitives.

## Use Cases

### 1. Claude Plan Reviewer

Review and comment on AI-generated plans (e.g., `docs/superpowers/plans/*.md`). Inline comments that are AI-readable — Claude can see feedback and iterate.

- Open a plan file, read it with rich rendering
- Select text, add a comment (stored as sidecar, not inline)
- Comments feed back into AI context on next session
- Track which plans are reviewed, which have open comments

**Competitor gap:** VS Code has no native markdown commenting. You either edit the file directly or use a separate tool.

### 2. Obsidian Competitor

Beautiful markdown editing with vault/folder management, wiki-links, and a knowledge graph. But native macOS (not Electron), local-first, git-friendly, and AI-aware.

- Vault browser sidebar (folder tree)
- Wiki-links (`[[page]]`) with backlink tracking
- Rich editing: tables, mermaid diagrams, math, frontmatter
- Native macOS performance and design language
- Git-based sync (not proprietary cloud)

**Competitor gap:** Obsidian is Electron (heavy), sync is paid/painful, plugin ecosystem is fragile, and it predates the AI-native workflow. No built-in understanding that an AI agent might be reading/writing these files.

### 3. Quick Capture for Membrain

Fast note-taking that drops markdown files to disk, complementing the membrain personal memory system.

- Global hotkey → capture window
- Write markdown, hit Enter, file lands in a configurable directory
- Frontmatter auto-populated (date, tags, source)
- Files are plain .md on disk — membrain/Claude can index them
- Optional: capture from clipboard, screenshot, URL

**Competitor gap:** Apple Notes isn't markdown. Drafts is iOS-first. Bear is subscription. None of them produce plain .md files that integrate with a file-based AI memory system.

## Shared Core

All three use cases share:

1. **Native macOS markdown editor** — rich editing with live preview (split pane or WYSIWYG)
2. **Commenting/annotation layer** — sidecar JSON files (`file.md.comments.json`), non-invasive, git-friendly, AI-readable
3. **File sidebar** — folder/vault browser with search
4. **Rendering engine** — extracted from PreviewMD (GFM, mermaid, syntax highlighting, frontmatter, dark mode)

## Architecture (Preliminary)

```
md-editor/
├── Shared/          — rendering engine (extracted from PreviewMD as Swift package)
├── Editor/          — text editing (CodeMirror in WKWebView? Native NSTextView?)
├── Comments/        — sidecar comment storage + UI overlay
├── Sidebar/         — file browser, vault management
├── Capture/         — global hotkey quick-capture window
└── App/             — SwiftUI app shell, window management
```

### Key Technical Decision: Editor Component

| Option | Pros | Cons |
|--------|------|------|
| CodeMirror 6 in WKWebView | Mature, extensible, markdown mode exists, syntax highlighting built-in | WebView latency, bridging complexity, not truly native |
| Monaco (VS Code editor) in WKWebView | Feature-rich, familiar | Heavy (~5MB), overkill for markdown |
| Native NSTextView + TextKit 2 | Truly native, fast, no bridge overhead | Markdown syntax highlighting from scratch, less ecosystem |
| SwiftUI TextEditor | Simple, native | Limited customization, no syntax highlighting |

**Recommendation:** CodeMirror 6 in WKWebView. It's what Obsidian uses under the hood (via Electron), but we'd use it in a native macOS WKWebView — lighter, faster, and the markdown editing mode is battle-tested. The rendering engine stays separate (PreviewMD's HTML pipeline) for the preview pane.

### Comment Storage Format

```json
// file: my-plan.md.comments.json
{
  "version": 1,
  "comments": [
    {
      "id": "c1",
      "author": "ag",
      "timestamp": "2026-04-12T15:30:00Z",
      "anchor": {
        "startLine": 15,
        "endLine": 17,
        "text": "the original selected text for drift detection"
      },
      "body": "This section needs more detail on error handling",
      "resolved": false
    }
  ]
}
```

Sidecar files are:
- Git-friendly (separate diff from content changes)
- AI-readable (Claude can parse JSON, see comments, address them)
- Non-invasive (the .md file itself is unchanged)
- Optional (no sidecar = no comments, file still works everywhere)

## Differentiation vs. Competitors

| Feature | MD Editor | Obsidian | Typora | VS Code |
|---------|-----------|----------|--------|---------|
| Native macOS | Yes | No (Electron) | Yes | No (Electron) |
| Inline commenting | Yes (sidecar) | No | No | No (on .md) |
| AI-native (reads/writes .md) | Yes | Partial | No | Partial |
| Mermaid diagrams | Yes (local) | Plugin | Yes | Plugin |
| Git-based sync | Yes (plain files) | Paid/plugin | No | Yes |
| Quick capture hotkey | Yes | No | No | No |
| Price | TBD | $50 (sync) / free (local) | $15 | Free |

## V1 Scope (MVP)

The smallest thing that's useful:

1. Open and edit .md files with syntax-highlighted editing (CodeMirror)
2. Live preview pane (PreviewMD rendering engine)
3. Select text → add comment (sidecar JSON)
4. File sidebar (single folder, no vault linking yet)
5. Dark mode

**Not in V1:** Wiki-links, graph view, quick capture hotkey, AI integration, multi-vault, sync, export, search across files.

## Relationship to PreviewMD

PreviewMD continues as the free Quick Look extension. The rendering engine (`Shared/`) is extracted into a Swift package that both projects depend on. MD Editor is a separate paid product.

## Open Questions

- Pricing: one-time ($15-25 like Typora) or subscription?
- Name: "MD Editor" is placeholder — needs a real name
- Distribution: App Store (discovery) or direct (freedom)?
- When to start: after PreviewMD ships LaTeX, or now?
