// CSVParseTests — V1.1 Story 8 (CSV round-trip + RFC-4180 parsing).

import XCTest
@testable import MDEditor

final class CSVParseTests: XCTestCase {
    func testSimpleCSV() {
        let rows = CSVRenderer.parse("a,b,c\n1,2,3\n4,5,6\n")
        XCTAssertEqual(rows, [["a","b","c"], ["1","2","3"], ["4","5","6"]])
    }

    func testQuotedFields() {
        let rows = CSVRenderer.parse("\"a,b\",c\n\"line1\nline2\",d\n")
        XCTAssertEqual(rows, [["a,b","c"], ["line1\nline2","d"]])
    }

    func testEscapedQuotes() {
        let rows = CSVRenderer.parse("\"say \"\"hi\"\"\",x\n")
        XCTAssertEqual(rows, [["say \"hi\"", "x"]])
    }

    func testCRLFTerminator() {
        let rows = CSVRenderer.parse("a,b\r\n1,2\r\n")
        XCTAssertEqual(rows, [["a","b"], ["1","2"]])
    }

    func testNoTrailingNewline() {
        let rows = CSVRenderer.parse("a,b\n1,2")
        XCTAssertEqual(rows, [["a","b"], ["1","2"]])
    }

    func testRendersHTMLTable() {
        let html = CSVRenderer.renderHTML("name,age\nAlice,30\nBob,25\n", hasHeader: true)
        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("<th>name</th>"))
        XCTAssertTrue(html.contains("<td>Alice</td>"))
        XCTAssertTrue(html.contains("<td>30</td>"))
    }

    func testHTMLEscaping() {
        let html = CSVRenderer.renderHTML("a\n<script>alert('x')</script>\n", hasHeader: false)
        XCTAssertFalse(html.contains("<script>alert"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }
}
