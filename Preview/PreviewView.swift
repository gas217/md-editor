// PreviewView — host for the preview WKWebView.
// Markdown uses PreviewMDShared package for rendering.
// CSV/JSON/HTML preview WebView is V1.1.
// See VISION.md "Renderers per format".

import SwiftUI
import WebKit
import PreviewMDShared

struct PreviewView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        // macOS 12+ shares the Web Content process across WKWebViews automatically.
        // No WKProcessPool plumbing needed; the V1.1 memory math (~60-80 MB baseline +
        // 15-25 MB for the second WebView frame) holds via the system default.
        return WKWebView(frame: .zero)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Renders via the shared package (real extraction landed — see preview-md-shared/).
        // Mermaid/KaTeX runtime assets are a Story 0a follow-on (HTMLTemplate.loadResource
        // returns empty until we bundle the JS/CSS — both render as plain code until then).
        let html = PreviewMDShared.render(markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
