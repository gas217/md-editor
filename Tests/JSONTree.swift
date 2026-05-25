// JSONTreeTests — V1.1 Story 9 (JSON tree rendering).

import XCTest
@testable import MDEditor

final class JSONTreeTests: XCTestCase {
    func testRendersObject() {
        let html = JSONRenderer.renderHTML("{\"name\": \"Alice\", \"age\": 30}")
        XCTAssertTrue(html.contains("<details"))
        XCTAssertTrue(html.contains("name"))
        XCTAssertTrue(html.contains("Alice"))
        XCTAssertTrue(html.contains("30"))
    }

    func testRendersArray() {
        let html = JSONRenderer.renderHTML("[1, 2, 3]")
        XCTAssertTrue(html.contains("3 items"))
        XCTAssertTrue(html.contains(">1<"))
    }

    func testRendersNested() {
        let html = JSONRenderer.renderHTML("{\"users\": [{\"name\": \"Bob\"}]}")
        XCTAssertTrue(html.contains("users"))
        XCTAssertTrue(html.contains("Bob"))
    }

    func testInvalidJSONSurfacesError() {
        let html = JSONRenderer.renderHTML("{not valid}")
        XCTAssertTrue(html.contains("Couldn't parse"))
    }

    func testEscapesValueText() {
        let html = JSONRenderer.renderHTML("{\"x\": \"<script>\"}")
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }
}
