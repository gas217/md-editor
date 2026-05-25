// DocumentFormatDetectionTests — V1.1: extension-based format detection
// drives which renderer and CM6 language mode each document uses.

import XCTest
@testable import MDEditor

final class DocumentFormatDetectionTests: XCTestCase {
    func testMarkdownExtensions() {
        for ext in ["md", "markdown", "mdown", "mkd", "mkdn"] {
            let url = URL(fileURLWithPath: "/tmp/file.\(ext)")
            XCTAssertEqual(DocumentFormat.from(url: url), .markdown, ".\(ext) should be markdown")
        }
    }

    func testCSVAndTSV() {
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/data.csv")), .csv)
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/data.tsv")), .csv)
    }

    func testJSONAndJSONL() {
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/x.json")), .json)
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/x.jsonl")), .jsonl)
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/x.ndjson")), .jsonl)
    }

    func testHTML() {
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/page.html")), .html)
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/page.htm")), .html)
    }

    func testPlainAndUnknown() {
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/notes.txt")), .plain)
        XCTAssertEqual(DocumentFormat.from(url: URL(fileURLWithPath: "/tmp/random.xyz")), .plain)
        XCTAssertEqual(DocumentFormat.from(url: nil), .plain)
    }

    func testBridgeLanguageMap() {
        XCTAssertEqual(DocumentFormat.markdown.bridgeLanguage, "markdown")
        XCTAssertEqual(DocumentFormat.csv.bridgeLanguage, "plain")
        XCTAssertEqual(DocumentFormat.json.bridgeLanguage, "json")
        XCTAssertEqual(DocumentFormat.jsonl.bridgeLanguage, "json")
        XCTAssertEqual(DocumentFormat.html.bridgeLanguage, "html")
        XCTAssertEqual(DocumentFormat.plain.bridgeLanguage, "plain")
    }

    func testWantsPreviewPane() {
        XCTAssertTrue(DocumentFormat.csv.wantsPreviewPane)
        XCTAssertTrue(DocumentFormat.json.wantsPreviewPane)
        XCTAssertTrue(DocumentFormat.html.wantsPreviewPane)
        XCTAssertFalse(DocumentFormat.markdown.wantsPreviewPane)
        XCTAssertFalse(DocumentFormat.plain.wantsPreviewPane)
    }
}
