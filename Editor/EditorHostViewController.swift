// EditorHostViewController — hosts the WKWebView running CodeMirror 6.
// Bridges Swift⇄JS via the protocol in VISION.md Appendix A.

import AppKit
import WebKit

final class EditorHostViewController: NSViewController {
    private let document: MDDocument
    private var webView: WKWebView!
    private var bridge: BridgeHandler?
    private var menuObserver: NSObjectProtocol?

    init(document: MDDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let menuObserver { NotificationCenter.default.removeObserver(menuObserver) }
    }

    override func loadView() {
        let config = WKWebViewConfiguration()
        let bridge = BridgeHandler(document: document)
        config.userContentController.add(bridge, name: "bridge")
        webView = WKWebView(frame: .zero, configuration: config)
        bridge.attach(to: webView)
        self.bridge = bridge
        view = webView

        if let url = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        // Edit → Add Comment menu / toolbar item routes here for the focused doc.
        // We forward to the CM6 side which already knows how to grab the selection
        // and emit comment.requested back through the bridge.
        menuObserver = NotificationCenter.default.addObserver(
            forName: .mdeditAddCommentMenuFired, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self,
                  self.view.window?.isKeyWindow == true else { return }
            self.bridge?.send(type: "palette.invoke", payload: ["id": "comment.add"], reply: nil)
        }
    }
}

final class WebViewPreloader {
    // macOS 12 deprecated WKProcessPool — WKWebViews already share a single Web Content
    // process by default. We only need to *trigger* that process to spin up early,
    // which we do by instantiating one empty WebView at app launch.
    // Saves ~150-250 ms off cold launch of the first real document.
    // See VISION.md "WKWebView process model & memory budget reconciliation".
    static let shared = WebViewPreloader()
    private var warmView: WKWebView?

    func warmUp() {
        let v = WKWebView(frame: .zero)
        v.loadHTMLString("", baseURL: nil)
        warmView = v
    }
}
