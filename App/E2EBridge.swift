// E2EBridge — test-mode hooks for XCUITest verification.
// Only active when launched with --e2e=1 (or env MDEDIT_E2E=1).
//
// Why this exists: XCUITest drives the app through Accessibility, but
// WKWebView's DOM is opaque to it. The bridge polls the editor for DOM
// state via the existing Swift⇄JS bridge and surfaces JSON to tests
// through an offscreen NSTextField whose accessibilityValue mirrors the
// latest state. Tests read it by AX identifier "e2e-state".
//
// Three knobs:
//   --e2e=1             enable test mode (otherwise this file is a no-op)
//   --e2e-tmp=<path>    use <path> for all sidecar / temp output (prevents
//                       tests from clobbering the user's real ~/Repoes)
//   --e2e-fixture=<p>   open <p> on launch (alternative to passing it
//                       through `open -a`, which fights state restoration)

import AppKit
import WebKit

@MainActor
final class E2EBridge {
    static let shared = E2EBridge()

    private(set) var isEnabled = false
    private(set) var tempDir: URL?
    private(set) var fixtureURL: URL?

    /// Per-window AX state fields. Keyed by window so multi-doc setups stay tidy.
    private var stateFields: [ObjectIdentifier: NSTextField] = [:]
    private var pollTimer: Timer?
    private var windowObserver: NSObjectProtocol?

    /// Parse launch args. Called from AppDelegate.applicationWillFinishLaunching
    /// so test mode is set up BEFORE any document opens.
    func parseLaunchArgs() {
        let args = ProcessInfo.processInfo.arguments
        let env = ProcessInfo.processInfo.environment

        if args.contains("--e2e=1") || env["MDEDIT_E2E"] == "1" {
            isEnabled = true
        }
        guard isEnabled else { return }

        for arg in args {
            if arg.hasPrefix("--e2e-tmp=") {
                let path = String(arg.dropFirst("--e2e-tmp=".count))
                tempDir = URL(fileURLWithPath: path, isDirectory: true)
            } else if arg.hasPrefix("--e2e-fixture=") {
                let path = String(arg.dropFirst("--e2e-fixture=".count))
                fixtureURL = URL(fileURLWithPath: path)
            }
        }
        if tempDir == nil, let env = env["MDEDIT_E2E_TMP"] {
            tempDir = URL(fileURLWithPath: env, isDirectory: true)
        }
        if fixtureURL == nil, let env = env["MDEDIT_E2E_FIXTURE"] {
            fixtureURL = URL(fileURLWithPath: env)
        }
        if let tempDir { try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true) }
        NSLog("[mdedit.e2e] enabled tempDir=%@ fixture=%@",
              tempDir?.path ?? "(none)",
              fixtureURL?.path ?? "(none)")
    }

    /// Begin polling + window injection. Called from
    /// AppDelegate.applicationDidFinishLaunching.
    func attachToActiveApplication() {
        guard isEnabled else { return }

        // Inject an AX state field into every doc window as it appears.
        // Tests find it via `app.windows.firstMatch.staticTexts["e2e-state"]`.
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let window = note.object as? NSWindow else { return }
            Task { @MainActor in self?.injectStateField(into: window) }
        }

        // Poll the focused doc's web view every 200 ms for DOM state.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshState() }
        }

        // Open the requested fixture (deferred until after didFinishLaunching).
        if let fixtureURL {
            NSLog("[mdedit.e2e] scheduling fixture open: %@", fixtureURL.path)
            DispatchQueue.main.async {
                NSLog("[mdedit.e2e] dispatching openDocument now")
                NSDocumentController.shared.openDocument(
                    withContentsOf: fixtureURL, display: true
                ) { doc, alreadyOpen, err in
                    if let err {
                        NSLog("[mdedit.e2e] fixture open FAILED: %@", "\(err)")
                    } else {
                        NSLog("[mdedit.e2e] fixture open OK (alreadyOpen=%d)", alreadyOpen ? 1 : 0)
                    }
                }
            }
        }
    }

    private func injectStateField(into window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard stateFields[id] == nil, let content = window.contentView else { return }
        let field = NSTextField(labelWithString: "{}")
        field.identifier = NSUserInterfaceItemIdentifier("e2e-state")
        field.setAccessibilityIdentifier("e2e-state")
        field.setAccessibilityLabel("E2E state JSON")
        field.setAccessibilityRole(.staticText)
        // Tiny but visible (alpha 1) so XCUITest's accessibility scan doesn't
        // skip it as zero-size/hidden. Top-right corner so it doesn't overlap
        // user content visually — width 1 height 1 makes it imperceptible.
        field.isHidden = false
        field.alphaValue = 1.0
        field.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(field)
        NSLayoutConstraint.activate([
            field.widthAnchor.constraint(equalToConstant: 1),
            field.heightAnchor.constraint(equalToConstant: 1),
            field.topAnchor.constraint(equalTo: content.topAnchor),
            field.trailingAnchor.constraint(equalTo: content.trailingAnchor),
        ])
        stateFields[id] = field
        NSLog("[mdedit.e2e] injected e2e-state into window: %@", window.title)
    }

    /// Walk the focused window's editor + preview surfaces, eval probes, fold
    /// result into the AX field for that window. Surfaces:
    ///
    ///   - editor WKWebView (CodeMirror): h1/h2/code counts, docLen, gutterBg
    ///   - preview WKWebView (CSV/JSON/HTML render): tableRows, jsonKeys, htmlBodyChildren
    ///   - PDFKit view (PDF): pdfHasDocument
    ///
    /// Tests scope to the key window so multi-doc setups stay independent.
    private func refreshState() {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              let field = stateFields[ObjectIdentifier(window)] else { return }

        let allWebViews = findAllWebViews(in: window.contentView)
        let pdfPresent = hasPDFView(in: window.contentView)

        // Identify editor vs preview by presence of `.cm-content` (CodeMirror's text wrapper).
        // Build two probes and combine results.
        let group = DispatchGroup()
        var editorJSON = "{}"
        var previewJSON = "{}"

        for wv in allWebViews {
            group.enter()
            wv.evaluateJavaScript(Self.classifyProbe) { result, _ in
                let str = (result as? String) ?? "{}"
                if str.contains("\"isEditor\":true") {
                    editorJSON = str
                } else if !str.contains("\"isEditor\":true") {
                    previewJSON = str
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Stitch into a single object that tests can read with one AX call.
            let combined = """
            {"editor":\(editorJSON),"preview":\(previewJSON),"pdfPresent":\(pdfPresent ? "true" : "false"),"webViewCount":\(allWebViews.count)}
            """
            field.setAccessibilityValue(combined)
            field.stringValue = combined
        }
    }

    /// Single JS probe used in every WKWebView. Returns `isEditor:true` for the
    /// CodeMirror surface, otherwise treats the body as a rendered preview.
    private static let classifyProbe = """
    (function () {
        try {
            if (document.querySelector('.cm-content')) {
                // Editor surface
                return JSON.stringify({
                    isEditor: true,
                    h1: document.querySelectorAll('.cm-h1').length,
                    h2: document.querySelectorAll('.cm-h2').length,
                    code: document.querySelectorAll('.cm-inline-code').length,
                    docLen: (document.querySelector('.cm-content').textContent || '').length,
                    gutterBg: (function() {
                        const g = document.querySelector('.cm-gutters');
                        return g ? getComputedStyle(g).backgroundColor : '';
                    })(),
                    commentMarkers: document.querySelectorAll('.cm-comment-marker').length,
                });
            }
            // Preview surface — count signals for csv/json/html
            return JSON.stringify({
                isEditor: false,
                tableRows: document.querySelectorAll('table tr').length,
                jsonKeys: document.querySelectorAll('.json-key, details').length,
                htmlBodyChildren: document.body ? document.body.children.length : 0,
                title: document.title || '',
            });
        } catch (e) { return JSON.stringify({err: e.message}); }
    })()
    """

    private func findAllWebViews(in view: NSView?) -> [WKWebView] {
        guard let view else { return [] }
        var out: [WKWebView] = []
        if let wv = view as? WKWebView { out.append(wv) }
        for sub in view.subviews { out.append(contentsOf: findAllWebViews(in: sub)) }
        return out
    }

    private func hasPDFView(in view: NSView?) -> Bool {
        guard let view else { return false }
        // Detect by class name string so we don't have to link PDFKit here.
        if String(describing: type(of: view)).contains("PDFView") { return true }
        for sub in view.subviews where hasPDFView(in: sub) { return true }
        return false
    }
}

// (sidecar redirect helper lives in CommentStore.swift — see e2eSidecarDir().)

