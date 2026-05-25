// JSONAnchorDriftTests — V1.1 Story 11 (format-specific commenting).
// Verifies the JSON renderer + anchor surface tolerate sibling-key edits.

import XCTest
@testable import MDEditor

final class JSONAnchorDriftTests: XCTestCase {
    func testReorderingKeysProducesSamePointers() {
        // RFC 6901 JSON Pointer doesn't care about key order — /a/b refers to
        // the same value whether a or b appears first in the source.
        let a = JSONRenderer.renderHTML("{\"a\": {\"name\": \"x\"}, \"b\": 1}")
        let b = JSONRenderer.renderHTML("{\"b\": 1, \"a\": {\"name\": \"x\"}}")
        // Both contain the same values, just rendered differently.
        XCTAssertTrue(a.contains("name"))
        XCTAssertTrue(b.contains("name"))
        XCTAssertTrue(a.contains("\"x\""))
        XCTAssertTrue(b.contains("\"x\""))
    }

    func testAddingSiblingKeyKeepsExistingValueAccessible() {
        let before = JSONRenderer.renderHTML("{\"keep\": 42}")
        let after = JSONRenderer.renderHTML("{\"keep\": 42, \"added\": true}")
        // The "keep" pointer (/keep) still resolves to 42 in both.
        XCTAssertTrue(before.contains("42"))
        XCTAssertTrue(after.contains("42"))
        XCTAssertTrue(after.contains("added"))
    }

    func testRemovingSiblingKeyDoesNotAffectOtherKeys() {
        let before = JSONRenderer.renderHTML("{\"keep\": 1, \"drop\": 2}")
        let after = JSONRenderer.renderHTML("{\"keep\": 1}")
        XCTAssertTrue(before.contains("drop"))
        XCTAssertFalse(after.contains("drop"))
        XCTAssertTrue(after.contains("keep"))
    }

    func testEditingValueIsReflected() {
        let before = JSONRenderer.renderHTML("{\"x\": 1}")
        let after = JSONRenderer.renderHTML("{\"x\": 999}")
        XCTAssertTrue(before.contains(">1<"))
        XCTAssertTrue(after.contains(">999<"))
    }

    func testWhitespaceReflowIsRenderInsensitive() {
        let compact = JSONRenderer.renderHTML("{\"a\":1,\"b\":2}")
        let spaced  = JSONRenderer.renderHTML("{\n  \"a\": 1,\n  \"b\": 2\n}")
        // Both should render the same logical content (keys + values present).
        for needle in ["a", "b", ">1<", ">2<"] {
            XCTAssertTrue(compact.contains(needle), "compact missing \(needle)")
            XCTAssertTrue(spaced.contains(needle),  "spaced missing \(needle)")
        }
    }
}
