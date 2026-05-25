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

final class DocumentWindowController: NSWindowController {
    init(document: MDDocument) {
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = document.displayName ?? "Untitled"
        super.init(window: window)
        window.contentViewController = DocumentSplitViewController(document: document)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

/// Editor on the left + (optional) preview on the right + status bar at the bottom.
/// CSV/JSON/HTML auto-open the preview pane; markdown uses inline hybrid live preview.
final class DocumentSplitViewController: NSSplitViewController {
    private let document: MDDocument
    private let statusBar = StatusBarController()

    init(document: MDDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)

        // PDF takes the entire window (no CM6 editor — PDF is binary, view-only).
        // Inspector still sits on the right so comments work.
        if document.format.usesPDFKitFullPane {
            let pdfVC = NSHostingController(rootView: PDFViewerView(document: document))
            addSplitViewItem(NSSplitViewItem(viewController: pdfVC))
            let inspectorVC = NSHostingController(rootView: CommentInspectorContainer(document: document))
            let inspectorItem = NSSplitViewItem(viewController: inspectorVC)
            inspectorItem.canCollapse = true
            inspectorItem.minimumThickness = 280
            addSplitViewItem(inspectorItem)
            return
        }

        let editorVC = EditorHostViewController(document: document)
        addSplitViewItem(NSSplitViewItem(viewController: editorVC))

        // Side preview for CSV/JSON/HTML; comment inspector for .md/.txt.
        let rightVC: NSViewController
        if document.format.wantsPreviewPane {
            rightVC = NSHostingController(rootView: FormatPreviewView(document: document))
        } else {
            rightVC = NSHostingController(rootView: CommentInspectorContainer(document: document))
        }
        let rightItem = NSSplitViewItem(viewController: rightVC)
        rightItem.canCollapse = true
        rightItem.isCollapsed = false
        rightItem.minimumThickness = 280
        addSplitViewItem(rightItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Wire the status bar.
        view.addSubview(statusBar.view)
        statusBar.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusBar.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBar.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBar.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusBar.view.heightAnchor.constraint(equalToConstant: 22),
        ])
        statusBar.observe()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
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
