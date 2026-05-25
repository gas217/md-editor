// AnchorBitapTests — V1.0 Story 5 (Anchor drift).
// Validates the W3C cascade + Bitap fuzzy match in AnchorResolver.

import XCTest
@testable import MDEditor

final class AnchorBitapTests: XCTestCase {

    // MARK: - Hash-match fast path

    func testHashMatchAttachesByPosition() {
        let doc = "hello world"
        let hash = TextCanon.documentHash(doc)
        let result = AnchorResolver.resolveText(
            in: doc,
            documentHash: hash,
            position: (start: 6, end: 11),
            quote: ("world", "hello ", "")
        )
        XCTAssertEqual(result, .attached(start: 6, end: 11, driftRecovered: false))
    }

    // MARK: - Quote-only path (hash mismatch)

    func testUniqueQuoteMatch() {
        let result = AnchorResolver.resolveText(
            in: "Here is some content with a unique phrase in it.",
            documentHash: "different-hash",
            position: nil,
            quote: ("unique phrase", "with a ", " in it")
        )
        if case let .attached(start, end, drift) = result {
            XCTAssertEqual(end - start, "unique phrase".utf16.count)
            XCTAssertFalse(drift)
        } else {
            XCTFail("expected attached, got \(result)")
        }
    }

    func testMultipleQuoteMatchesDisambiguatedByPrefix() {
        let doc = "alpha foo bar gamma foo bar"
        // Two occurrences of "foo bar"; disambiguate via prefix "gamma ".
        let result = AnchorResolver.resolveText(
            in: doc,
            documentHash: "different",
            position: nil,
            quote: ("foo bar", "gamma ", "")
        )
        if case let .attached(start, end, _) = result {
            // Expect the SECOND occurrence (after "gamma "), which is at index 20.
            XCTAssertEqual(start, 20)
            XCTAssertEqual(end, 27)
        } else {
            XCTFail("expected attached, got \(result)")
        }
    }

    func testBitapRecoversAfterSmallEdit() {
        let doc = "Step 1: rebuild the cache on every wrte"  // typo "wrte"
        let result = AnchorResolver.resolveText(
            in: doc,
            documentHash: "different",
            position: nil,
            quote: ("rebuild the cache on every write", "Step 1: ", "")
        )
        if case let .attached(_, _, drift) = result {
            XCTAssertTrue(drift, "small-edit recovery should set driftRecovered=true")
        } else {
            XCTFail("Bitap should have recovered from a 1-char edit, got \(result)")
        }
    }

    func testOrphansWhenNoMatch() {
        let result = AnchorResolver.resolveText(
            in: "completely different content",
            documentHash: "different",
            position: nil,
            quote: ("this phrase does not appear", "", "")
        )
        if case .orphaned = result {
            // pass
        } else {
            XCTFail("expected orphan, got \(result)")
        }
    }

    func testNoQuoteAndHashMismatchOrphans() {
        let result = AnchorResolver.resolveText(
            in: "doc",
            documentHash: "different",
            position: (start: 0, end: 3),
            quote: nil
        )
        if case .orphaned = result {
            // pass
        } else {
            XCTFail("expected orphan, got \(result)")
        }
    }

    // MARK: - Levenshtein sanity

    func testLevenshteinBasics() {
        XCTAssertEqual(AnchorResolver.levenshtein("", ""), 0)
        XCTAssertEqual(AnchorResolver.levenshtein("kitten", "sitting"), 3)
        XCTAssertEqual(AnchorResolver.levenshtein("flaw", "lawn"), 2)
        XCTAssertEqual(AnchorResolver.levenshtein("abc", "abc"), 0)
        XCTAssertEqual(AnchorResolver.levenshtein("a", ""), 1)
    }
}
