// MemoryBudgetTests — V1.1 trigger for the iframe-fallback decision.
// See VISION.md "WKWebView process model & memory budget reconciliation".
// If loaded RSS exceeds 170 MB (85% of 200 MB ceiling) on M-series,
// V1.1 ships with one WebView + two iframes instead of two WebViews.

import XCTest

final class MemoryBudgetTests: XCTestCase {
    func test_MemoryBudget_NotYetImplemented() throws {
        try XCTSkipIf(true, "MemoryBudget V1.1 trigger not yet implemented — see VISION.md")
    }
}
