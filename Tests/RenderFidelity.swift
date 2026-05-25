// RenderFidelityTests — V1.0 Story 1 (Open and read).
// Asserts the markdown renderer produces stable, well-formed HTML for a corpus
// of inputs. "Fidelity" here = structural correctness, not pixel-perfect output.

import XCTest
@testable import MDEditor
import PreviewMDShared

final class RenderFidelityTests: XCTestCase {
    /// Pure markdown produces an `<article class="markdown-body">` wrapper.
    func testArticleWrapper() {
        let html = PreviewMDShared.render("# hi\nbody")
        XCTAssertTrue(html.contains("<article class=\"markdown-body\">"))
        XCTAssertTrue(html.contains("</article>"))
    }

    /// Output is a valid HTML document (DOCTYPE + html + head + body).
    func testProducesFullHTMLDocument() {
        let html = PreviewMDShared.render("# hi")
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<head>"))
        XCTAssertTrue(html.contains("<body>"))
        XCTAssertTrue(html.contains("</html>"))
    }

    /// Output is byte-stable for identical inputs (modulo per-render CSP nonce).
    func testStableForIdenticalInput() {
        let a = PreviewMDShared.render("# stable\nbody.")
        let b = PreviewMDShared.render("# stable\nbody.")
        // Strip the nonce (it's random per render); the rest must be identical.
        let strip: (String) -> String = { $0.replacingOccurrences(of: #"nonce-[a-f0-9]+"#, with: "nonce-X", options: .regularExpression) }
        XCTAssertEqual(strip(a), strip(b))
    }

    /// Render survives unusual-but-valid markdown without crashing.
    func testHandlesEdgeCaseInputs() {
        let inputs = [
            "",
            "\n\n\n",
            "no markdown here",
            String(repeating: "# header\n", count: 100),
            "a\n\nb\n\nc",
            "[link](https://example.com)",
            "![img](data:image/png;base64,iVBORw0KGgo=)",
            "```python\ndef f(): pass\n```",
        ]
        for input in inputs {
            let html = PreviewMDShared.render(input)
            XCTAssertTrue(html.contains("<!DOCTYPE html>"), "missing DOCTYPE for: \(input.debugDescription)")
            XCTAssertTrue(html.contains("</body>"), "missing closing body for: \(input.debugDescription)")
        }
    }

    /// Frontmatter rendering produces the metadata block before the content article.
    func testFrontmatterPrecedesContent() {
        let md = """
        ---
        title: Test
        status: done
        ---

        body
        """
        let html = PreviewMDShared.render(md)
        let frontmatterIdx = html.range(of: "frontmatter")
        let articleIdx = html.range(of: "<article")
        XCTAssertNotNil(frontmatterIdx, "frontmatter div missing")
        XCTAssertNotNil(articleIdx, "article wrapper missing")
        if let f = frontmatterIdx, let a = articleIdx {
            XCTAssertLessThan(f.lowerBound, a.lowerBound, "frontmatter must precede article body")
        }
    }
}
