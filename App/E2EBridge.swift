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

    /// Walk the focused window's editor, eval a small probe, fold result into the
    /// AX field for that window so tests scoped to a specific window see the right state.
    private func refreshState() {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              let field = stateFields[ObjectIdentifier(window)] else { return }
        guard let webView = findWebView(in: window.contentView) else {
            field.setAccessibilityValue("{}")
            field.stringValue = "{}"
            return
        }
        // Read straight from the rendered DOM — no dependency on window.view
        // (whose exposure has been fragile across CM6 mount paths). cm-content
        // is CM6's text wrapper; its textContent is the live document buffer.
        let probe = """
        (function () {
            try {
                const h1 = document.querySelectorAll('.cm-h1').length;
                const h2 = document.querySelectorAll('.cm-h2').length;
                const code = document.querySelectorAll('.cm-inline-code').length;
                const content = document.querySelector('.cm-content');
                const docLen = content ? (content.textContent || '').length : 0;
                const gutterBg = (function() {
                    const g = document.querySelector('.cm-gutters');
                    return g ? getComputedStyle(g).backgroundColor : '';
                })();
                return JSON.stringify({
                    h1: h1, h2: h2, code: code,
                    docLen: docLen,
                    gutterBg: gutterBg,
                });
            } catch (e) { return '{"err":"' + e.message + '"}'; }
        })()
        """
        webView.evaluateJavaScript(probe) { result, _ in
            let str = (result as? String) ?? "{}"
            field.setAccessibilityValue(str)
            field.stringValue = str  // also set string so AX value reflects it
        }
    }

    private func findWebView(in view: NSView?) -> WKWebView? {
        guard let view else { return nil }
        if let wv = view as? WKWebView { return wv }
        for sub in view.subviews {
            if let wv = findWebView(in: sub) { return wv }
        }
        return nil
    }
}

// (sidecar redirect helper lives in CommentStore.swift — see e2eSidecarDir().)

