import XCTest
@testable import MDEditor

final class CommentPresentationTests: XCTestCase {
    private func sidecar(quote: String = "chosen words", hash: String = "stale",
                         start: Int = 0, end: Int = 12) -> CommentSidecar {
        CommentSidecar(document: .init(path: "review.md", sha256: hash), comments: [
            .init(id: "c_review", createdAt: "2026-11-15T00:00:00Z",
                  author: .init(kind: .human, name: "Reviewer"), body: "Review this",
                  target: .init(selectors: [
                    .textPosition(start: start, end: end, startLine: 0, endLine: 0),
                    .textQuote(exact: quote, prefix: "", suffix: "")
                  ]))
        ])
    }

    func testRestoresMidLineMarkerAfterInsertionWithUTF16Offsets() {
        let markers = CommentPresentation.markers(in: sidecar(), text: "😀 before chosen words after")
        XCTAssertEqual(markers.count, 1)
        XCTAssertEqual(markers.first?["from"] as? Int, 10)
        XCTAssertEqual(markers.first?["to"] as? Int, 22)
        XCTAssertEqual(markers.first?["id"] as? String, "c_review")
    }

    func testAmbiguousDeletedAndFuzzyQuotesNeverMarkUnrelatedText() {
        for text in ["chosen words / chosen words", "totally unrelated", "chosen wordz", ""] {
            XCTAssertTrue(CommentPresentation.markers(in: sidecar(), text: text).isEmpty, text)
        }
    }

    func testRejectsInvalidPositionEvenWithMatchingHash() {
        let text = "chosen words"
        for (start, end) in [(-1, 12), (0, 999), (12, 0)] {
            let data = sidecar(hash: TextCanon.documentHash(text), start: start, end: end)
            XCTAssertTrue(CommentPresentation.markers(in: data, text: text).isEmpty)
        }
    }

    func testNormalizedOffsetCannotPointAtDifferentDisplayedText() {
        XCTAssertTrue(CommentPresentation.markers(in: sidecar(), text: "e\u{301} chosen words").isEmpty)
    }

    func testResolvedAndArchivedPresentationDoesNotMutateSidecar() throws {
        var data = sidecar()
        data.comments[0].resolved = true
        let before = try JSONEncoder().encode(data)
        XCTAssertEqual(CommentPresentation.markers(in: data, text: "chosen words").first?["status"] as? String, "resolved")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        XCTAssertEqual(try encoder.encode(data), try encoder.encode(JSONDecoder().decode(CommentSidecar.self, from: before)))
        data.comments[0].status = .archived
        XCTAssertTrue(CommentPresentation.markers(in: data, text: "chosen words").isEmpty)
    }

    @MainActor
    func testThreadNotificationOnlyChangesItsDocument() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let first = MDDocument(), second = MDDocument()
        first.fileURL = dir.appendingPathComponent("one.md")
        second.fileURL = dir.appendingPathComponent("two.md")
        try CommentStore.save(sidecar(), for: XCTUnwrap(first.fileURL))
        try CommentStore.save(sidecar(), for: XCTUnwrap(second.fileURL))
        let one = CommentInspectorModel(document: first), two = CommentInspectorModel(document: second)
        NotificationCenter.default.post(name: .mdeditCommentClicked, object: nil,
                                        userInfo: ["id": "c_review", "documentURL": try XCTUnwrap(first.fileURL)])
        XCTAssertEqual(one.activeThread?.id, "c_review")
        XCTAssertNil(two.activeThread)
    }
}
