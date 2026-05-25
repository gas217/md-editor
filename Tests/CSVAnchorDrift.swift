// CSVAnchorDriftTests — V1.1 Story 11 (format-specific commenting).
// Verifies the CSV parser tolerates the edits that anchor drift relies on.

import XCTest
@testable import MDEditor

final class CSVAnchorDriftTests: XCTestCase {
    func testRowCountStableAcrossInsertion() {
        let original = "a,b,c\n1,2,3\n4,5,6\n"
        let edited = "a,b,c\nNEW,ROW,HERE\n1,2,3\n4,5,6\n"
        XCTAssertEqual(CSVRenderer.parse(original).count, 3)
        XCTAssertEqual(CSVRenderer.parse(edited).count, 4)
    }

    func testCellAccessibleByRowAndColumn() {
        let rows = CSVRenderer.parse("name,age\nAlice,30\nBob,25\n")
        XCTAssertEqual(rows[1][0], "Alice")
        XCTAssertEqual(rows[1][1], "30")
        XCTAssertEqual(rows[2][0], "Bob")
    }

    func testHeaderNameSurvivesColumnReorder() {
        // The CSVCellSelector spec stores headerName so anchors survive column reordering.
        // This test demonstrates the data round-trips; the actual re-anchor logic
        // lives in CommentSidecar.deriveStructured + downstream resolver work.
        let original = CSVRenderer.parse("id,name,age\n1,Alice,30\n")
        let reordered = CSVRenderer.parse("name,age,id\nAlice,30,1\n")
        XCTAssertEqual(original[0][1], "name")
        XCTAssertEqual(reordered[0][0], "name")
        // headerName "name" lets the anchor find the value regardless of which
        // column index it now sits at — this would be resolver logic in V1.1 Story 11.
    }

    func testQuotedCellWithEmbeddedNewline() {
        let rows = CSVRenderer.parse("a,b\n\"line1\nline2\",x\n")
        XCTAssertEqual(rows[1][0], "line1\nline2")
        XCTAssertEqual(rows[1][1], "x")
    }
}
