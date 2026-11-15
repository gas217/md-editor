// Real tests for the extracted rendering engine. Asserts the pipeline produces
// expected HTML for representative inputs. Validates Story 0a — the extraction
// preserves preview-md's behavior.

import XCTest
@testable import PreviewMDShared

final class PreviewMDSharedTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(PreviewMDShared.version, "0.2.0")
    }

    func testRendersHeading() {
        let html = PreviewMDShared.render("# Hello world")
        XCTAssertTrue(html.contains("<h1"), "expected h1, got: \(html)")
        XCTAssertTrue(html.contains("Hello world"), "expected heading text in: \(html)")
    }

    func testRendersBoldAndItalic() {
        let html = PreviewMDShared.render("**bold** and *italic*")
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>italic</em>"))
    }

    func testRendersCode() {
        let html = PreviewMDShared.render("```swift\nlet x = 1\n```")
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\""))
        XCTAssertTrue(html.contains("let x = 1"))
    }

    func testRendersGFMTable() {
        let md = """
        | a | b |
        |---|---|
        | 1 | 2 |
        """
        let html = PreviewMDShared.render(md)
        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("<th"))
        XCTAssertTrue(html.contains("<td"))
    }

    func testRendersTaskList() {
        let md = """
        - [ ] todo
        - [x] done
        """
        let html = PreviewMDShared.render(md)
        XCTAssertTrue(html.contains("task-list-item"))
        XCTAssertTrue(html.contains("checked"))
    }

    func testRendersAdmonition() {
        let md = """
        > [!NOTE]
        > heads up
        """
        let html = PreviewMDShared.render(md)
        XCTAssertTrue(html.contains("adm-note"))
        XCTAssertTrue(html.contains("Note"))
    }

    func testFrontmatterExtracted() {
        let md = """
        ---
        title: My Doc
        status: done
        tags: [a, b]
        ---

        # Body
        """
        let html = PreviewMDShared.render(md)
        XCTAssertTrue(html.contains("fm-title"))
        XCTAssertTrue(html.contains("My Doc"))
        XCTAssertTrue(html.contains("badge-green")) // status=done → green
        XCTAssertTrue(html.contains("<h1"))
    }

    func testHTMLEscapingPreventsXSS() {
        let md = "Look at <script>alert('x')</script>"
        let html = PreviewMDShared.render(md)
        XCTAssertFalse(html.contains("<script>alert"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testJavascriptURLsBlocked() {
        let md = "[click](javascript:alert('x'))"
        let html = PreviewMDShared.render(md)
        XCTAssertFalse(html.contains("javascript:"))
    }

    func testCSPNonceVaries() {
        let a = PreviewMDShared.render("# a")
        let b = PreviewMDShared.render("# a")
        // Both contain a nonce; nonces differ across renders.
        func nonce(_ s: String) -> String? {
            guard let r = s.range(of: "nonce-([0-9a-f]+)", options: .regularExpression) else { return nil }
            return String(s[r])
        }
        XCTAssertNotEqual(nonce(a), nonce(b))
    }
}
