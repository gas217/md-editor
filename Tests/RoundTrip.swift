// RoundTripTests — V1.0 Story 3 (Save).
// LF normalization on read + LF-preserving save = byte-identical round trip.

import XCTest
@testable import MDEditor

final class RoundTripTests: XCTestCase {
    /// Pure-LF input round-trips byte-identically through TextCanon normalization.
    func testLFRoundTrip() {
        let corpus = [
            "Plain text.\n",
            "# Heading\n\nParagraph.\n",
            "---\ntitle: Foo\n---\n\nBody.\n",
            "",
            "no trailing newline",
            "tabs\tand    spaces\n",
            "unicode 你好 emoji 🎉\n",
        ]
        for input in corpus {
            let normalized = TextCanon.normalizeLineEndings(input)
            XCTAssertEqual(normalized, input, "LF input mutated: \(input.debugDescription)")
        }
    }

    /// CRLF input round-trips to LF (one-time normalization on read).
    func testCRLFNormalizedOnRead() {
        let crlf = "line1\r\nline2\r\nline3\r\n"
        let lf = "line1\nline2\nline3\n"
        XCTAssertEqual(TextCanon.normalizeLineEndings(crlf), lf)
    }

    /// Hash is stable across CRLF↔LF representations of the same content.
    func testHashStableAfterNormalize() {
        let crlf = "a\r\nb\r\nc\r\n"
        let lf = "a\nb\nc\n"
        XCTAssertEqual(TextCanon.documentHash(crlf), TextCanon.documentHash(lf))
    }

    /// Frontmatter is preserved byte-for-byte (no YAML reformat on round-trip).
    func testFrontmatterPreserved() {
        let input = """
        ---
        title: My doc
        status: active
        tags: [a, b]
        ---

        # Body

        Content goes here.
        """
        let normalized = TextCanon.normalizeLineEndings(input)
        XCTAssertEqual(normalized, input)
        XCTAssertTrue(normalized.hasPrefix("---\ntitle: My doc"))
    }
}
