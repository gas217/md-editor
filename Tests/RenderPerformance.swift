// RenderPerformanceTests — V1.0 Story 1 perf budget smoke.
// Asserts the markdown renderer stays within wall-clock budgets for representative
// inputs. Strict CI threshold comes from baselines.json; this test uses
// conservative wall-clock bounds that should never tighten on faster hardware.

import XCTest
@testable import MDEditor
import PreviewMDShared

final class RenderPerformanceTests: XCTestCase {
    /// 10 KB markdown should render in <50ms on any reasonable hardware (M-series target <10ms).
    func testRenders10KBUnderBudget() {
        let md = String(repeating: "# Heading\n\nParagraph with **bold** and *italic*.\n\n", count: 200)
        XCTAssertGreaterThan(md.count, 8_000)
        let start = CFAbsoluteTimeGetCurrent()
        _ = PreviewMDShared.render(md)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 0.05, "10 KB markdown rendered in \(elapsed * 1000) ms — over 50 ms budget")
    }

    /// 100 KB markdown should render in <300ms.
    func testRenders100KBUnderBudget() {
        let md = String(repeating: "# Heading\n\nParagraph with **bold** and *italic*.\n\n", count: 2_000)
        XCTAssertGreaterThan(md.count, 80_000)
        let start = CFAbsoluteTimeGetCurrent()
        _ = PreviewMDShared.render(md)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 0.3, "100 KB markdown rendered in \(elapsed * 1000) ms — over 300 ms budget")
    }

    /// CSV parser stays fast on 10k rows.
    func testCSVParse10kRowsUnderBudget() {
        let rows = (0..<10_000).map { "row\($0),value\($0),\($0)" }.joined(separator: "\n")
        let csv = "a,b,c\n" + rows
        let start = CFAbsoluteTimeGetCurrent()
        let parsed = CSVRenderer.parse(csv)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertEqual(parsed.count, 10_001)
        XCTAssertLessThan(elapsed, 0.5, "10k CSV rows parsed in \(elapsed * 1000) ms — over 500 ms budget")
    }

    /// JSON tree render handles 1k-element array.
    func testJSON1KElementUnderBudget() {
        let elements = (0..<1_000).map { "\"item\($0)\"" }.joined(separator: ",")
        let json = "[" + elements + "]"
        let start = CFAbsoluteTimeGetCurrent()
        _ = JSONRenderer.renderHTML(json)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 0.3, "1k JSON elements rendered in \(elapsed * 1000) ms — over 300 ms budget")
    }
}
