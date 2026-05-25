// Editor entry point — boots CodeMirror 6 inside the WKWebView and wires up
// the bridge to Swift. See VISION.md Appendix A.1 for the wire protocol.

import { EditorState, RangeSetBuilder, Compartment } from "@codemirror/state";
import { EditorView, keymap, Decoration, DecorationSet, gutter, GutterMarker, ViewPlugin, ViewUpdate } from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { markdown } from "@codemirror/lang-markdown";
import { json } from "@codemirror/lang-json";
import { html } from "@codemirror/lang-html";
import { search, searchKeymap, openSearchPanel } from "@codemirror/search";
import { syntaxTree, foldGutter, foldKeymap, indentOnInput, bracketMatching,
         HighlightStyle, syntaxHighlighting, defaultHighlightStyle } from "@codemirror/language";
import { tags as t } from "@lezer/highlight";
import { StateField, StateEffect } from "@codemirror/state";
import { vim } from "@replit/codemirror-vim";

declare global {
    interface Window {
        bridge: BridgeAPI;
        webkit: {
            messageHandlers: {
                bridge: { postMessage(msg: unknown): void };
            };
        };
    }
}

interface BridgeAPI {
    handle(msg: { id: string; type: string; payload: unknown }): void;
}

type Pending = { resolve: (v: unknown) => void; reject: (e: Error) => void };
const pending = new Map<string, Pending>();

function send(type: string, payload: unknown, replyTimeoutMs = 5000): Promise<unknown> | void {
    const id = crypto.randomUUID();
    const msg = { id, type, payload };
    window.webkit.messageHandlers.bridge.postMessage(msg);
    if (replyTimeoutMs > 0) {
        return new Promise((resolve, reject) => {
            pending.set(id, { resolve, reject });
            setTimeout(() => {
                if (pending.has(id)) {
                    pending.delete(id);
                    reject(new Error(`bridge: timeout on ${type}`));
                }
            }, replyTimeoutMs);
        });
    }
}

let view: EditorView | null = null;

// Comment state — driven by Swift sending `comments.set` whenever the sidecar changes.
interface CommentMarker {
    id: string;
    from: number;
    to: number;
    status: "active" | "orphaned" | "resolved" | "archived";
}
const setComments = StateEffect.define<CommentMarker[]>();
const commentField = StateField.define<CommentMarker[]>({
    create() { return []; },
    update(value, tr) {
        for (const e of tr.effects) {
            if (e.is(setComments)) return e.value;
        }
        return value;
    },
});

// Gutter marker: filled dot for active, ring for orphaned, check for resolved.
class CommentGutterMarker extends GutterMarker {
    constructor(private readonly status: CommentMarker["status"]) { super(); }
    toDOM() {
        const el = document.createElement("span");
        el.className = `cm-comment-marker cm-comment-${this.status}`;
        el.textContent = this.status === "resolved" ? "✓" : this.status === "orphaned" ? "○" : "●";
        return el;
    }
}

const commentGutter = gutter({
    class: "cm-comments-gutter",
    lineMarker(view, line) {
        const comments = view.state.field(commentField, false) ?? [];
        for (const c of comments) {
            if (c.from <= line.from && line.from <= c.to) {
                return new CommentGutterMarker(c.status);
            }
        }
        return null;
    },
    initialSpacer: () => new CommentGutterMarker("active"),
});

const commentHighlight = ViewPlugin.fromClass(class {
    decorations: DecorationSet;
    constructor(view: EditorView) {
        this.decorations = this.buildDecorations(view);
    }
    update(update: ViewUpdate) {
        if (update.docChanged || update.viewportChanged ||
            update.state.field(commentField, false) !== update.startState.field(commentField, false)) {
            this.decorations = this.buildDecorations(update.view);
        }
    }
    private buildDecorations(view: EditorView): DecorationSet {
        const b = new RangeSetBuilder<Decoration>();
        const comments = view.state.field(commentField, false) ?? [];
        for (const c of comments) {
            if (c.status === "active" || c.status === "orphaned") {
                const from = Math.max(0, Math.min(c.from, view.state.doc.length));
                const to = Math.max(from, Math.min(c.to, view.state.doc.length));
                if (to > from) {
                    b.add(from, to, Decoration.mark({ class: `cm-comment-mark cm-comment-${c.status}` }));
                }
            }
        }
        return b.finish();
    }
}, { decorations: v => v.decorations });

// EditorView.theme is HIGHER priority than baseTheme — needed so the
// gutter background loses its default cream strip and the editor blends
// into the host page's dark background.
const surfaceTheme = EditorView.theme({
    "&": {
        backgroundColor: "transparent",
        color: "inherit",
        height: "100vh",
        // Typography matches preview-md-shared/Sources/Shared/HTMLTemplate.swift so the
        // live-edit view and the Quick Look render of the same file look the same.
        fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif",
        fontSize: "15px",
        lineHeight: "1.6",
    },
    ".cm-content": {
        caretColor: "currentColor",
        padding: "16px 20px",
    },
    ".cm-scroller": {
        // Inherit font from .cm-editor, NOT CM6's default monospace.
        fontFamily: "inherit",
    },
    // Kill the cream/white gutter strip — make it blend with the editor surface.
    ".cm-gutters": {
        backgroundColor: "transparent",
        border: "none",
        color: "rgba(127,127,127,0.5)",
    },
    ".cm-activeLineGutter, .cm-activeLine": {
        backgroundColor: "transparent",
    },
    ".cm-foldGutter .cm-gutterElement": {
        padding: "0 4px",
        color: "rgba(127,127,127,0.45)",
    },
    ".cm-cursor, .cm-dropCursor": {
        borderLeftColor: "currentColor",
    },
    ".cm-selectionBackground, &.cm-focused .cm-selectionBackground, ::selection": {
        backgroundColor: "rgba(100, 150, 255, 0.25)",
    },
}, { dark: true });

const commentTheme = EditorView.baseTheme({
    ".cm-comment-mark.cm-comment-active": { backgroundColor: "rgba(255, 213, 79, 0.28)" },
    ".cm-comment-mark.cm-comment-orphaned": { backgroundColor: "rgba(255, 138, 128, 0.28)" },
    ".cm-comments-gutter": { width: "1.4em", textAlign: "center" },
    ".cm-comment-marker": { cursor: "pointer", fontSize: "0.9em" },
    ".cm-comment-active": { color: "#f9a825" },
    ".cm-comment-orphaned": { color: "#e57373" },
    ".cm-comment-resolved": { color: "#66bb6a" },
    // Hybrid live preview: hide markdown syntax markers on non-active lines.
    ".cm-hidden-marker": { display: "none" },
    // Heading line decorations. Sizes mirror preview-md-shared's HTMLTemplate.swift
    // (h1 2em, h2 1.5em) so the live editor matches the Quick Look render of the
    // same file. Border-bottom on h1/h2 echoes PreviewMD's section dividers.
    ".cm-h1": {
        fontSize: "2em", fontWeight: "700", lineHeight: "1.25",
        padding: "0.5em 0 0.2em",
        borderBottom: "1px solid rgba(127,127,127,0.35)",
    },
    ".cm-h2": {
        fontSize: "1.5em", fontWeight: "700", lineHeight: "1.3",
        padding: "0.4em 0 0.15em",
        borderBottom: "1px solid rgba(127,127,127,0.22)",
    },
    ".cm-h3": { fontSize: "1.25em", fontWeight: "700", padding: "0.3em 0 0.1em" },
    ".cm-h4, .cm-h5, .cm-h6": { fontSize: "1.05em", fontWeight: "700" },
    ".cm-strong": { fontWeight: "700" },
    ".cm-em": { fontStyle: "italic" },
    ".cm-inline-code": {
        fontFamily: "'SF Mono', ui-monospace, 'JetBrains Mono', Menlo, monospace",
        fontSize: "0.92em",
        backgroundColor: "rgba(127,127,127,0.18)",
        padding: "0.1em 0.35em",
        borderRadius: "4px",
    },
});

// HighlightStyle gives every token type a color/weight even when hybridLivePreview
// doesn't decorate it (links, code blocks, blockquotes, lists, HR, etc.).
// Without this CM6 leaves the markdown source completely flat.
const mdHighlight = HighlightStyle.define([
    { tag: t.heading1, fontSize: "2em",   fontWeight: "700", color: "#e6e6e6" },
    { tag: t.heading2, fontSize: "1.5em", fontWeight: "700", color: "#e6e6e6" },
    { tag: t.heading3, fontSize: "1.25em", fontWeight: "700", color: "#e6e6e6" },
    { tag: [t.heading4, t.heading5, t.heading6], fontWeight: "700", color: "#e6e6e6" },
    { tag: t.strong, fontWeight: "700" },
    { tag: t.emphasis, fontStyle: "italic" },
    { tag: t.strikethrough, textDecoration: "line-through" },
    { tag: t.link, color: "#69b7ff", textDecoration: "underline" },
    { tag: t.url, color: "#69b7ff" },
    { tag: [t.monospace, t.literal],
      fontFamily: "'SF Mono', ui-monospace, Menlo, monospace",
      color: "#e6c07b" },
    { tag: t.list, color: "#c39bd3" },
    { tag: t.quote, color: "#9aa6b2", fontStyle: "italic" },
    { tag: t.contentSeparator, color: "rgba(127,127,127,0.5)" },
    // Markdown syntax characters (the `#`, `**`, `` ` ``, `-`, `>`) get a dim color
    // so the raw source on the active line stays legible without shouting.
    { tag: t.processingInstruction, color: "rgba(127,127,127,0.55)" },
    { tag: t.meta, color: "rgba(127,127,127,0.55)" },
]);

// Hybrid live preview: walks the syntax tree, decorates headings/bold/italic/inline-code,
// and hides the marker characters (`#`, `**`, `*`, `` ` ``) for paragraphs whose lines
// are NOT under the cursor. The active line stays raw so the user can edit syntax.
// Obsidian Live Preview model; MarkEdit doesn't ship this.
//
// Uses Decoration.set (auto-sorts) rather than RangeSetBuilder — the old builder
// path threw silently when point + range decorations landed at the same offset,
// which is why the editor was rendering raw markdown source.
const hybridLivePreview = ViewPlugin.fromClass(class {
    decorations: DecorationSet;
    constructor(view: EditorView) {
        this.decorations = this.build(view);
    }
    update(u: ViewUpdate) {
        if (u.docChanged || u.selectionSet || u.viewportChanged) {
            this.decorations = this.build(u.view);
        }
    }
    private build(view: EditorView): DecorationSet {
        try {
            const ranges: { from: number; to: number; deco: Decoration }[] = [];
            const doc = view.state.doc;
            // Active lines: every line touched by any cursor or selection range.
            const activeLines = new Set<number>();
            for (const r of view.state.selection.ranges) {
                const fromLine = doc.lineAt(r.from).number;
                const toLine = doc.lineAt(r.to).number;
                for (let l = fromLine; l <= toLine; l++) activeLines.add(l);
            }
            const tree = syntaxTree(view.state);
            for (const { from, to } of view.visibleRanges) {
                tree.iterate({
                    from,
                    to,
                    enter: (node) => {
                        const lineNum = doc.lineAt(node.from).number;
                        const onActiveLine = activeLines.has(lineNum);

                        // ATX heading: hide the leading `# ` marks on non-active lines, style the line.
                        if (node.name.startsWith("ATXHeading")) {
                            const levelMatch = node.name.match(/(\d)$/);
                            const level = levelMatch ? Number(levelMatch[1]) : 1;
                            const lineFrom = doc.lineAt(node.from).from;
                            const lineTo = doc.lineAt(node.to).to;
                            ranges.push({
                                from: lineFrom, to: lineFrom,
                                deco: Decoration.line({ class: `cm-h${level}` }),
                            });
                            if (!onActiveLine) {
                                const text = doc.sliceString(lineFrom, lineTo);
                                const m = text.match(/^(#+\s+)/);
                                if (m) {
                                    ranges.push({
                                        from: lineFrom, to: lineFrom + m[1].length,
                                        deco: Decoration.mark({ class: "cm-hidden-marker" }),
                                    });
                                }
                            }
                        }
                        if (node.name === "StrongEmphasis") {
                            ranges.push({ from: node.from, to: node.to, deco: Decoration.mark({ class: "cm-strong" }) });
                            if (!onActiveLine) {
                                ranges.push({ from: node.from, to: node.from + 2, deco: Decoration.mark({ class: "cm-hidden-marker" }) });
                                ranges.push({ from: node.to - 2,   to: node.to,   deco: Decoration.mark({ class: "cm-hidden-marker" }) });
                            }
                        }
                        if (node.name === "Emphasis") {
                            ranges.push({ from: node.from, to: node.to, deco: Decoration.mark({ class: "cm-em" }) });
                            if (!onActiveLine) {
                                ranges.push({ from: node.from, to: node.from + 1, deco: Decoration.mark({ class: "cm-hidden-marker" }) });
                                ranges.push({ from: node.to - 1,   to: node.to,   deco: Decoration.mark({ class: "cm-hidden-marker" }) });
                            }
                        }
                        if (node.name === "InlineCode") {
                            ranges.push({ from: node.from, to: node.to, deco: Decoration.mark({ class: "cm-inline-code" }) });
                            if (!onActiveLine) {
                                ranges.push({ from: node.from, to: node.from + 1, deco: Decoration.mark({ class: "cm-hidden-marker" }) });
                                ranges.push({ from: node.to - 1,   to: node.to,   deco: Decoration.mark({ class: "cm-hidden-marker" }) });
                            }
                        }
                    },
                });
            }
            // Decoration.set sorts and de-overlaps automatically. Filter zero-or-negative-length
            // mark decorations (line decorations are point, from == to, which IS valid).
            const valid = ranges
                .filter(r => r.to >= r.from)
                .map(r => r.deco.range(r.from, r.to));
            return Decoration.set(valid, /*sort=*/ true);
        } catch (e) {
            // If this ever throws, surface it to Swift via the bridge log instead
            // of silently producing an empty decoration set (the old bug mode).
            send("log", { level: "error", message: `hybridLivePreview build failed: ${e}` }, 0);
            return Decoration.none;
        }
    }
}, { decorations: v => v.decorations });

// Mode compartment: lets Swift toggle vim-mode on/off without rebuilding the doc.
const vimCompartment = new Compartment();
let vimEnabled = false;

function setVimMode(view: EditorView, enabled: boolean) {
    vimEnabled = enabled;
    view.dispatch({ effects: vimCompartment.reconfigure(enabled ? vim() : []) });
}

// Status bar: word/char/line count + cursor line. Sent to Swift via `status.changed`.
function emitStatus(state: EditorState) {
    const text = state.doc.toString();
    const words = (text.match(/\S+/g) || []).length;
    const chars = state.doc.length;
    const lines = state.doc.lines;
    const cursor = state.selection.main.head;
    const lineNum = state.doc.lineAt(cursor).number;
    send("status.changed", { words, chars, lines, cursorLine: lineNum, vim: vimEnabled }, 0);
}

// Cmd-Shift-M: request a new comment on the current selection.
function requestComment(view: EditorView): boolean {
    const sel = view.state.selection.main;
    if (sel.empty) return false;
    const doc = view.state.doc;
    const from = sel.from, to = sel.to;
    const exact = doc.sliceString(from, to);
    const prefix = doc.sliceString(Math.max(0, from - 32), from);
    const suffix = doc.sliceString(to, Math.min(doc.length, to + 32));
    send("comment.requested", { from, to, exact, prefix, suffix }, 0);
    return true;
}

// Cmd-Shift-O: emit a document outline (headings) to Swift, which renders a picker.
// MarkEdit doesn't ship this; ours does as a markdown-specific differentiator.
function emitOutline(view: EditorView): boolean {
    const doc = view.state.doc;
    const tree = syntaxTree(view.state);
    const items: { level: number; text: string; from: number; line: number }[] = [];
    tree.iterate({
        enter: (node) => {
            const m = node.name.match(/^ATXHeading(\d)$/);
            if (m) {
                const lineFrom = doc.lineAt(node.from).from;
                const lineTo = doc.lineAt(node.to).to;
                const raw = doc.sliceString(lineFrom, lineTo);
                const text = raw.replace(/^#+\s+/, "").trim();
                items.push({
                    level: Number(m[1]),
                    text,
                    from: lineFrom,
                    line: doc.lineAt(lineFrom).number,
                });
            }
        },
    });
    send("outline.show", { items }, 0);
    return true;
}

// Cmd-Shift-P: command palette via a Swift-rendered picker fed with available actions.
function openCommandPalette(_view: EditorView): boolean {
    send("palette.show", {
        commands: [
            { id: "comment.add",  title: "Add Comment on Selection",        shortcut: "⌘⇧M" },
            { id: "outline.show", title: "Show Outline",                    shortcut: "⌘⇧O" },
            { id: "find.show",    title: "Find…",                            shortcut: "⌘F" },
            { id: "vim.toggle",   title: "Toggle Vim Mode",                  shortcut: "" },
            { id: "save",         title: "Save",                             shortcut: "⌘S" },
        ],
    }, 0);
    return true;
}

// Swift can dispatch back via the palette.invoke message.
function paletteInvoke(view: EditorView, id: string) {
    switch (id) {
    case "comment.add":  requestComment(view); break;
    case "outline.show": emitOutline(view); break;
    case "find.show":    openSearchPanel(view); break;
    case "vim.toggle":   setVimMode(view, !vimEnabled); break;
    case "save":         send("save.requested", {}, 0); break;
    }
}

window.bridge = {
    handle(msg) {
        // Swift → JS messages. Dispatch by `type`.
        if (msg.type === "reply") {
            const p = pending.get(msg.id);
            if (p) {
                pending.delete(msg.id);
                p.resolve((msg.payload as { result?: unknown })?.result);
            }
            return;
        }
        switch (msg.type) {
            case "doc.load":
                doDocLoad(msg.payload as { text: string; language: string; readOnly: boolean });
                break;
            case "doc.applyEdit":
                // V1.0 Story 7 — agent-side programmatic edit
                break;
            case "comments.set":
                if (view) {
                    const list = (msg.payload as { comments: CommentMarker[] })?.comments ?? [];
                    view.dispatch({ effects: setComments.of(list) });
                }
                break;
            case "theme.set":
                // V1.0 — track system appearance
                break;
            case "find.show":
                if (view) openSearchPanel(view);
                break;
            case "vim.toggle":
                if (view) setVimMode(view, !vimEnabled);
                break;
            case "vim.set":
                if (view) {
                    const p = msg.payload as { enabled: boolean };
                    setVimMode(view, !!p?.enabled);
                }
                break;
            case "outline.scrollTo":
                if (view) {
                    const p = msg.payload as { from: number };
                    view.dispatch({
                        selection: { anchor: p.from },
                        effects: EditorView.scrollIntoView(p.from, { y: "start" }),
                    });
                }
                break;
            case "palette.invoke":
                if (view) {
                    const p = msg.payload as { id: string };
                    paletteInvoke(view, p.id);
                }
                break;
            default:
                send("log", { level: "warn", message: `unknown swift→js type: ${msg.type}` }, 0);
        }
    },
};

function languageFor(lang: string) {
    switch (lang) {
        case "markdown": return markdown();
        case "json": return json();
        case "html": return html();
        default: return [];
    }
}

function doDocLoad(payload: { text: string; language: string; readOnly: boolean }) {
    const isMarkdown = payload.language === "markdown";
    const state = EditorState.create({
        doc: payload.text,
        extensions: [
            surfaceTheme,
            // Markdown gets its own highlight style; other languages use CM6's default.
            syntaxHighlighting(isMarkdown ? mdHighlight : defaultHighlightStyle, { fallback: true }),
            EditorView.lineWrapping,
            vimCompartment.of(vimEnabled ? vim() : []),
            history(),
            search({ top: true }),
            indentOnInput(),
            bracketMatching(),
            foldGutter(),
            keymap.of([
                ...defaultKeymap,
                ...historyKeymap,
                ...searchKeymap,
                ...foldKeymap,
                // Cmd-Shift-M: request a new comment on the selection.
                { key: "Mod-Shift-m", run: requestComment },
                // Cmd-Shift-O: show markdown outline picker.
                { key: "Mod-Shift-o", run: emitOutline },
                // Cmd-Shift-P: command palette.
                { key: "Mod-Shift-p", run: openCommandPalette },
                // Cmd-F: open search panel.
                { key: "Mod-f", run: openSearchPanel },
            ]),
            languageFor(payload.language),
            commentField,
            commentGutter,
            commentHighlight,
            commentTheme,
            // Hybrid live preview is markdown-only (depends on the markdown syntax tree).
            ...(isMarkdown ? [hybridLivePreview] : []),
            EditorView.contentAttributes.of({
                contenteditable: payload.readOnly ? "false" : "true",
                // Opt into macOS Writing Tools (Proofread / Rewrite / Summarize via right-click)
                // and the system spell-checker. WKWebView passes these through to the OS
                // text input client. Apple Intelligence light up automatically on supported HW.
                writingsuggestions: "true",
                autocorrect: "on",
                autocapitalize: "off",
                spellcheck: "true",
            }),
            EditorView.updateListener.of((u) => {
                if (u.docChanged) {
                    // Send the full text on every change so Swift can keep MDDocument.text in sync.
                    // Cheap for typical files (<1 MB); for large files we may add a transactional
                    // diff protocol later — but correctness first.
                    send("doc.changed", {
                        length: u.state.doc.length,
                        version: u.state.doc.length,
                        text: u.state.doc.toString(),
                    }, 0);
                    emitStatus(u.state);
                }
                if (u.selectionSet) {
                    const r = u.state.selection.main;
                    const line = u.state.doc.lineAt(r.head);
                    send("selection.changed", { from: r.from, to: r.to, line: line.number, ch: r.head - line.from }, 0);
                    emitStatus(u.state);
                }
            }),
        ],
    });
    if (view) view.destroy();
    view = new EditorView({ state, parent: document.body });
    emitStatus(state);
    send("editor.ready", {}, 0);
}

// Signal ready immediately (Swift may send doc.load after this)
send("editor.ready", {}, 0);
