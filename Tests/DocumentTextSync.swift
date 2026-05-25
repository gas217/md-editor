// DocumentTextSyncTests — V1.0 Story 3 (Save) extension:
// asserts MDDocument.applyEditorText propagates from the bridge → document.text
// → atomic save would write the new content.
//
// Without this, Cmd-S would persist the originally-loaded text, not what the user typed.

import XCTest
@testable import MDEditor

final class DocumentTextSyncTests: XCTestCase {
    func testApplyEditorTextUpdatesTextAndMarksDirty() {
        let doc = MDDocument()
        // Read in initial text via the document's read path.
        try? doc.read(from: Data("original\n".utf8), ofType: "public.plain-text")
        XCTAssertEqual(doc.text, "original\n")
        XCTAssertFalse(doc.isDocumentEdited)

        doc.applyEditorText("edited!\n")
        XCTAssertEqual(doc.text, "edited!\n")
        XCTAssertTrue(doc.isDocumentEdited, "applyEditorText should flip the change count")
    }

    func testApplyEditorTextNoopOnIdenticalContent() {
        let doc = MDDocument()
        try? doc.read(from: Data("same\n".utf8), ofType: "public.plain-text")
        XCTAssertFalse(doc.isDocumentEdited)
        doc.applyEditorText("same\n")
        XCTAssertFalse(doc.isDocumentEdited, "identical text shouldn't dirty the document")
    }

    func testSerializeMatchesAppliedText() throws {
        let doc = MDDocument()
        try doc.read(from: Data("orig\n".utf8), ofType: "public.plain-text")
        doc.applyEditorText("# Hello\nworld\n")
        let data = try doc.data(ofType: "net.daringfireball.markdown")
        XCTAssertEqual(String(data: data, encoding: .utf8), "# Hello\nworld\n")
    }
}
