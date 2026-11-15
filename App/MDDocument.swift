// MDDocument — NSDocument subclass owning the file URL and atomic save path.
// All writes go through NSFileCoordinator to keep NSFileVersion happy.
// See VISION.md "Save path" decision.

import AppKit
import SwiftUI
import os.log
import PreviewMDShared

/// Detect the document's logical format from its filename extension.
/// V1.1: drives which preview renderer + which CM6 language mode we use.
enum DocumentFormat: String {
    case markdown, plain, csv, json, jsonl, html, pdf

    static func from(url: URL?) -> DocumentFormat {
        let ext = (url?.pathExtension ?? "").lowercased()
        switch ext {
        case "md", "markdown", "mdown", "mkd", "mkdn": return .markdown
        case "csv", "tsv": return .csv
        case "json": return .json
        case "jsonl", "ndjson": return .jsonl
        case "html", "htm": return .html
        case "pdf": return .pdf
        case "txt", "text", "": return .plain
        default: return .plain
        }
    }

    /// Language string for `doc.load` bridge payload (CM6 lang-* picks this up).
    var bridgeLanguage: String {
        switch self {
        case .markdown: return "markdown"
        case .json, .jsonl: return "json"
        case .html: return "html"
        case .csv, .plain, .pdf: return "plain"
        }
    }

    /// Whether to spawn the preview WebView. .md uses inline hybrid live preview;
    /// other formats benefit from a side-by-side rendered view.
    var wantsPreviewPane: Bool {
        switch self {
        case .csv, .json, .jsonl, .html: return true
        case .markdown, .plain, .pdf: return false
        }
    }

    /// PDF replaces the editor surface entirely with PDFKit (no source mode — PDF is binary).
    var usesPDFKitFullPane: Bool {
        self == .pdf
    }
}

final class MDDocument: NSDocument {
    private(set) var text: String = ""
    private(set) var rawData: Data?  // for binary formats (PDF) — not decoded as text
    var format: DocumentFormat { DocumentFormat.from(url: fileURL) }

    override class var autosavesInPlace: Bool { true }
    override class var readableTypes: [String] {
        // Declared in Info.plist via project.yml CFBundleDocumentTypes.
        // Listing them here lets NSDocumentController accept arbitrary file types
        // via Open dialog instead of refusing with "MD Editor cannot open files in
        // the 'X document' format."
        [
            "net.daringfireball.markdown", "public.plain-text",
            "public.comma-separated-values-text", "public.tab-separated-values-text",
            "public.json", "public.html", "com.adobe.pdf",
        ]
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // PDF is binary — store the raw bytes and let PDFKit render from them.
        if format == .pdf {
            rawData = data
            text = ""
            return
        }
        // Other formats are text — including JSON, HTML, CSV in source mode.
        guard let raw = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // CRLF→LF normalization via TextCanon — see VISION.md.
        text = TextCanon.normalizeLineEndings(raw)
    }

    override func data(ofType typeName: String) throws -> Data {
        // PDF round-trips its original bytes — we don't edit PDFs.
        if format == .pdf, let raw = rawData {
            return raw
        }
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }

    /// Explicit user save (Cmd-S / File → Save). NOT autosave-in-place.
    override func save(_ sender: Any?) {
        super.save(sender)
        dogfoodLogger.info("event=save")
    }

    /// Apply text from the CM6 editor surface. Marks the document dirty so Cmd-S
    /// (or autosave-in-place) writes the new content. Same path as user typing
    /// into NSTextView would take.
    func applyEditorText(_ newText: String) {
        guard newText != text else { return }
        text = newText
        updateChangeCount(.changeDone)
    }

    override func makeWindowControllers() {
        let controller = DocumentWindowController(document: self)
        addWindowController(controller)
    }
}

final class DocumentWindowController: NSWindowController, NSToolbarDelegate {
    init(document: MDDocument) {
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = document.displayName ?? "Untitled"
        window.minSize = NSSize(width: 560, height: 360)
        super.init(window: window)
        window.contentViewController = DocumentSplitViewController(document: document)
        installToolbar()
    }

    override func showWindow(_ sender: Any?) {
        // Apply our sizing rule before the window is shown, so state-restoration
        // can't overwrite us (it runs after init but before showWindow).
        if let window { applyInitialFrame(window) }
        super.showWindow(sender)
    }

    /// Open full screen-height, 1/3-width on wide displays (≥2500 px), 1/2-width
    /// on narrower ones. Centered horizontally. The user's later resizes are
    /// what they live with — we don't keep overriding them.
    private func applyInitialFrame(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let isWide = visible.width >= 2500
        let width = (isWide ? visible.width / 3 : visible.width / 2).rounded()
        let height = visible.height
        let x = visible.minX + ((visible.width - width) / 2).rounded()
        let y = visible.minY
        window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: NSToolbar — visible affordance for ⌘⇧M.
    // Installed in windowDidLoad so the window is fully realised by the time the
    // delegate callbacks fire (installing in init left the toolbar empty on macOS 15).

    private static let addCommentItemId = NSToolbarItem.Identifier("MDEditor.addComment")
    private static let toggleInspectorId = NSToolbarItem.Identifier("MDEditor.toggleInspector")

    private func installToolbar() {
        guard let window else { return }
        let toolbar = NSToolbar(identifier: "MDEditor.DocumentToolbar.v3")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        window.toolbarStyle = .unified
        window.toolbar = toolbar
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case Self.addCommentItemId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Comment"
            item.paletteLabel = "Add Comment"
            item.toolTip = "Add a comment on the selected text (⌘⇧M)"
            item.image = NSImage(systemSymbolName: "bubble.left",
                                 accessibilityDescription: "Add comment")
            item.target = MenuActions.shared
            item.action = #selector(MenuActions.addComment(_:))
            item.isBordered = true
            item.view?.setAccessibilityIdentifier("addCommentButton")
            return item
        case Self.toggleInspectorId:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Comments"
            item.paletteLabel = "Toggle Comments Panel"
            item.toolTip = "Show or hide the Comments panel"
            item.image = NSImage(systemSymbolName: "sidebar.right",
                                 accessibilityDescription: "Toggle comments panel")
            item.target = MenuActions.shared
            item.action = #selector(MenuActions.toggleInspector(_:))
            item.isBordered = true
            item.view?.setAccessibilityIdentifier("toggleInspectorButton")
            return item
        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.addCommentItemId, Self.toggleInspectorId]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.addCommentItemId, Self.toggleInspectorId, .flexibleSpace, .space]
    }
}

/// Top: NSSplitView (editor + lazy right pane). Bottom: status bar.
/// Inspector pane is COLLAPSED by default on .md/.txt — it auto-expands when
/// the user fires Cmd-Shift-M or clicks a gutter dot.
final class DocumentSplitViewController: NSViewController {
    private let document: MDDocument
    private let commentInspectorModel: CommentInspectorModel
    private let statusBar = StatusBarController()
    private var splitVC: NSSplitViewController!
    private var inspectorItem: NSSplitViewItem?
    private var observers: [NSObjectProtocol] = []

    init(document: MDDocument) {
        self.document = document
        // Subscribe before the collapsed SwiftUI inspector ever mounts.
        commentInspectorModel = CommentInspectorModel(document: document)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1100, height: 720))
        view.autoresizingMask = [.width, .height]

        splitVC = NSSplitViewController()
        splitVC.splitView.dividerStyle = .thin
        configureSplit()
        addChild(splitVC)

        view.addSubview(splitVC.view)
        view.addSubview(statusBar.view)
        splitVC.view.translatesAutoresizingMaskIntoConstraints = false
        statusBar.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Split view fills the top, stops at the status bar.
            splitVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            splitVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitVC.view.bottomAnchor.constraint(equalTo: statusBar.view.topAnchor),

            // Status bar pinned to the bottom.
            statusBar.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusBar.view.heightAnchor.constraint(equalToConstant: 22),
        ])
        statusBar.observe()

        // Auto-expand inspector when user wants to add or view a comment.
        // The inspector is hidden by default for .md/.txt — only the editor shows
        // on first open. Cmd-Shift-M or clicking a gutter dot reveals it.
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .mdeditCommentRequested, object: nil, queue: .main
            ) { [weak self] note in
                guard let self, note.userInfo?["documentURL"] as? URL == self.document.fileURL else { return }
                self.revealInspector()
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .mdeditCommentClicked, object: nil, queue: .main
            ) { [weak self] note in
                guard let self, note.userInfo?["documentURL"] as? URL == self.document.fileURL else { return }
                self.revealInspector()
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: .mdeditToggleInspectorFired, object: nil, queue: .main
            ) { [weak self] _ in
                // Only the key window's split should toggle.
                guard let self, self.view.window?.isKeyWindow == true else { return }
                self.toggleInspector()
            }
        )
    }

    private func configureSplit() {
        // PDF: full-pane PDFKit on the left, inspector on the right (hidden by default).
        if document.format.usesPDFKitFullPane {
            let pdfVC = NSHostingController(rootView: PDFViewerView(document: document))
            let mainItem = NSSplitViewItem(viewController: pdfVC)
            mainItem.minimumThickness = 320
            mainItem.holdingPriority = .defaultLow + 1  // keep the doc, not the inspector
            splitVC.addSplitViewItem(mainItem)

            let inspectorVC = NSHostingController(rootView: CommentInspectorContainer(model: commentInspectorModel))
            let item = NSSplitViewItem(viewController: inspectorVC)
            item.canCollapse = true
            item.isCollapsed = true            // hidden by default
            item.minimumThickness = 280
            item.maximumThickness = 420
            item.holdingPriority = .defaultLow  // inspector yields width to PDF
            splitVC.addSplitViewItem(item)
            inspectorItem = item
            return
        }

        // .md/.txt: editor pane is primary; inspector hidden by default.
        // .csv/.json/.html: editor + format-specific preview, preview visible by default.
        let editorVC = EditorHostViewController(document: document)
        let editorItem = NSSplitViewItem(viewController: editorVC)
        editorItem.minimumThickness = 320
        editorItem.holdingPriority = .defaultLow + 1  // editor keeps its width
        splitVC.addSplitViewItem(editorItem)

        let rightVC: NSViewController
        let collapsedByDefault: Bool
        if document.format.wantsPreviewPane {
            rightVC = NSHostingController(rootView: FormatPreviewView(document: document))
            collapsedByDefault = false  // preview is the point for csv/json/html
        } else {
            rightVC = NSHostingController(rootView: CommentInspectorContainer(model: commentInspectorModel))
            collapsedByDefault = true   // inspector is on-demand for .md/.txt
        }
        let rightItem = NSSplitViewItem(viewController: rightVC)
        rightItem.canCollapse = true
        rightItem.isCollapsed = collapsedByDefault
        rightItem.minimumThickness = 280
        rightItem.maximumThickness = 480
        rightItem.holdingPriority = .defaultLow
        splitVC.addSplitViewItem(rightItem)
        inspectorItem = rightItem
    }

    private func revealInspector() {
        guard let item = inspectorItem, item.isCollapsed else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.allowsImplicitAnimation = true
            item.animator().isCollapsed = false
        }
    }

    /// Public toggle so the toolbar button can show/hide the panel.
    func toggleInspector() {
        guard let item = inspectorItem else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.allowsImplicitAnimation = true
            item.animator().isCollapsed.toggle()
        }
    }
}

/// Lazy preview renderer. Picks CSV / JSON / Markdown renderer based on document format.
struct FormatPreviewView: NSViewRepresentable {
    let document: MDDocument

    func makeNSView(context: Context) -> WKWebViewWrapper {
        WKWebViewWrapper()
    }

    func updateNSView(_ wrapper: WKWebViewWrapper, context: Context) {
        let html: String
        switch document.format {
        case .csv:
            html = CSVRenderer.renderHTML(document.text, hasHeader: true)
        case .json, .jsonl:
            html = JSONRenderer.renderHTML(document.text)
        case .markdown:
            html = PreviewMDShared.render(document.text)
        case .html:
            html = document.text
        case .plain:
            html = "<pre>\(document.text.replacingOccurrences(of: "<", with: "&lt;"))</pre>"
        case .pdf:
            // PDF doesn't use this preview surface — DocumentSplitViewController
            // routes PDFs to PDFViewerView (full pane). This branch is unreachable
            // in practice but the switch must be exhaustive.
            html = ""
        }
        wrapper.loadHTML(html)
    }
}

import WebKit

final class WKWebViewWrapper: NSView {
    let webView: WKWebView

    override init(frame: NSRect) {
        let cfg = WKWebViewConfiguration()
        self.webView = WKWebView(frame: frame, configuration: cfg)
        super.init(frame: frame)
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func loadHTML(_ html: String) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

/// Bottom-of-window status bar showing word/char/line counts + cursor position + vim indicator.
/// Updated via `status.changed` bridge events from CM6.
final class StatusBarController {
    let view: NSView
    private let label: NSTextField

    init() {
        view = NSVisualEffectView(frame: .zero)
        (view as? NSVisualEffectView)?.material = .titlebar
        (view as? NSVisualEffectView)?.blendingMode = .behindWindow
        label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = NSColor.secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func observe() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(handle(_:)),
            name: .mdeditStatusChanged, object: nil
        )
    }

    @objc private func handle(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let words = info["words"] as? Int ?? 0
        let chars = info["chars"] as? Int ?? 0
        let lines = info["lines"] as? Int ?? 0
        let cursorLine = info["cursorLine"] as? Int ?? 1
        let vim = info["vim"] as? Bool ?? false
        let vimTag = vim ? " · VIM" : ""
        label.stringValue = "\(words) words · \(chars) chars · ln \(cursorLine) of \(lines)\(vimTag)"
    }
}

extension Notification.Name {
    static let mdeditStatusChanged = Notification.Name("com.mdedit.statusChanged")
}
