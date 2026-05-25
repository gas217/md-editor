// HTMLSandboxTests — V1.1 Story 10 (HTML preview, no JS, no network).
// Verifies the CSP / sandboxing claims at the API surface level.
// Full WKWebView load test requires running app; that's V1.0 manual verification.

import XCTest
@testable import MDEditor
import PreviewMDShared

final class HTMLSandboxTests: XCTestCase {
    func testCSVRendererCSPLocksDownAllSources() {
        let html = CSVRenderer.renderHTML("a,b\n1,2\n", hasHeader: true)
        // CSP must declare default-src 'none' (no network, no inline JS by default).
        XCTAssertTrue(html.contains("default-src 'none'"), "CSV renderer CSP missing default-src 'none'")
        XCTAssertTrue(html.contains("style-src 'unsafe-inline'"), "CSV CSP must allow inline styles for the table")
        XCTAssertFalse(html.contains("script-src"), "CSV renderer must not script-src; no JS in this view")
    }

    func testJSONRendererCSPLocksDownAllSources() {
        let html = JSONRenderer.renderHTML("{\"a\":1}")
        XCTAssertTrue(html.contains("default-src 'none'"), "JSON renderer CSP missing default-src 'none'")
        XCTAssertTrue(html.contains("style-src 'unsafe-inline'"), "JSON CSP must allow inline styles for the tree")
        XCTAssertFalse(html.contains("script-src"), "JSON renderer must not script-src; no JS in this view")
    }

    func testMarkdownRendererCSPNonceIsolatesScripts() {
        let html = PreviewMDShared.render("# heading")
        XCTAssertTrue(html.contains("default-src 'none'"), "Markdown renderer CSP missing default-src 'none'")
        // Markdown DOES script-src 'nonce-XXX' for the mermaid/highlight runtime
        // (Story 0a follow-on bundles them); the nonce isolates inline scripts.
        XCTAssertTrue(html.contains("nonce-"), "Markdown CSP missing nonce binding for runtime scripts")
    }

    func testRenderersEscapeAngleBrackets() {
        let csv = CSVRenderer.renderHTML("<script>", hasHeader: false)
        XCTAssertFalse(csv.contains("<script>alert"), "CSV must escape script tags")
        let json = JSONRenderer.renderHTML("{\"x\":\"<iframe>\"}")
        XCTAssertFalse(json.contains("<iframe>"), "JSON must escape angle brackets in values")
    }
}
