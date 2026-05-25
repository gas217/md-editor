// CommentRoundTripTests — V1.0 Story 4 (Comment).
// Codable round-trip + addressable/tags/mentions derivation.

import XCTest
@testable import MDEditor

final class CommentRoundTripTests: XCTestCase {
    func testEmptySidecarRoundTrip() throws {
        let sidecar = CommentSidecar(
            version: 1,
            document: .init(path: "foo.md", sha256: "abc"),
            comments: []
        )
        let encoded = try JSONEncoder().encode(sidecar)
        let decoded = try JSONDecoder().decode(CommentSidecar.self, from: encoded)
        XCTAssertEqual(decoded.version, 1)
        XCTAssertEqual(decoded.document.path, "foo.md")
        XCTAssertEqual(decoded.document.sha256, "abc")
        XCTAssertTrue(decoded.comments.isEmpty)
    }

    func testCommentWithBasicSelector() throws {
        let comment = CommentSidecar.Comment(
            id: "c_01HXYZ",
            createdAt: "2026-05-24T12:00:00Z",
            author: .init(kind: .human, name: "ag"),
            body: "rethink this paragraph",
            target: .init(selectors: [
                .textPosition(start: 100, end: 200, startLine: 5, endLine: 7)
            ])
        )
        let encoded = try JSONEncoder().encode(comment)
        let decoded = try JSONDecoder().decode(CommentSidecar.Comment.self, from: encoded)
        XCTAssertEqual(decoded.id, comment.id)
        XCTAssertEqual(decoded.body, comment.body)
        XCTAssertEqual(decoded.author.name, "ag")
    }

    func testDeriveStructuredExtractsMentions() {
        var comment = CommentSidecar.Comment(
            id: "c_01",
            createdAt: "2026-05-24T12:00:00Z",
            author: .init(kind: .human, name: "ag"),
            body: "@claude please rewrite this section",
            target: .init(selectors: [.textPosition(start: 0, end: 10, startLine: 1, endLine: 1)])
        )
        comment = CommentSidecar.deriveStructured(comment)
        XCTAssertEqual(comment.mentions.count, 1)
        XCTAssertEqual(comment.mentions.first?.name, "claude")
        XCTAssertEqual(comment.mentions.first?.kind, .agent)
        XCTAssertTrue(comment.addressable, "@claude should imply addressable=true")
    }

    func testDeriveStructuredExtractsTags() {
        var comment = CommentSidecar.Comment(
            id: "c_02",
            createdAt: "2026-05-24T12:00:00Z",
            author: .init(kind: .human, name: "ag"),
            body: "this is broken #bug #urgent",
            target: .init(selectors: [.textPosition(start: 0, end: 10, startLine: 1, endLine: 1)])
        )
        comment = CommentSidecar.deriveStructured(comment)
        XCTAssertEqual(Set(comment.tags), ["bug", "urgent"])
    }

    func testDeriveStructuredHandlesNonAgentMention() {
        var comment = CommentSidecar.Comment(
            id: "c_03",
            createdAt: "2026-05-24T12:00:00Z",
            author: .init(kind: .human, name: "ag"),
            body: "@alice can you check this?",
            target: .init(selectors: [.textPosition(start: 0, end: 10, startLine: 1, endLine: 1)])
        )
        comment = CommentSidecar.deriveStructured(comment)
        XCTAssertEqual(comment.mentions.first?.kind, .user)
        XCTAssertFalse(comment.addressable, "Non-agent mention should not flip addressable")
    }

    func testDeriveStructuredIsIdempotent() {
        var comment = CommentSidecar.Comment(
            id: "c_04",
            createdAt: "2026-05-24T12:00:00Z",
            author: .init(kind: .human, name: "ag"),
            body: "@claude check #bug",
            target: .init(selectors: [.textPosition(start: 0, end: 10, startLine: 1, endLine: 1)])
        )
        comment = CommentSidecar.deriveStructured(comment)
        let onceMentions = comment.mentions.count
        let onceTags = comment.tags
        comment = CommentSidecar.deriveStructured(comment)
        XCTAssertEqual(comment.mentions.count, onceMentions)
        XCTAssertEqual(comment.tags, onceTags)
    }
}
