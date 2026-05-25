// CanonFuzzTests — Story 0c acceptance.
// Round-trip canonicalize→hash→re-normalize with random Unicode strings;
// zero mismatches expected.

import XCTest
@testable import MDEditor

final class CanonFuzzTests: XCTestCase {
    /// Hash is stable: same input ⇒ same hash.
    func testHashIsStable() {
        for _ in 0..<1000 {
            let s = Self.randomString()
            XCTAssertEqual(TextCanon.documentHash(s), TextCanon.documentHash(s))
        }
    }

    /// Hash is LF-insensitive: clean-LF input ⇒ same hash as the CRLF representation
    /// of the same content. We strip stray `\r` from the LF input first because
    /// `"\r"` and `"\r\n"` aren't interchangeable text — a file that contains both
    /// represents different content than one that contains only one of them.
    func testHashIsLFNormalized() {
        for _ in 0..<500 {
            let raw = Self.randomString()
            // Strip stray \r so the input has only \n line breaks (canonical LF form).
            let lf = raw.replacingOccurrences(of: "\r", with: "")
            let crlf = lf.replacingOccurrences(of: "\n", with: "\r\n")
            XCTAssertEqual(
                TextCanon.documentHash(lf),
                TextCanon.documentHash(crlf),
                "LF/CRLF hashes diverge for: \(lf.debugDescription) (crlf: \(crlf.debugDescription))"
            )
        }
    }

    /// NFC normalization is idempotent.
    func testNFCIsIdempotent() {
        for _ in 0..<1000 {
            let s = Self.randomString()
            let once = TextCanon.normalizeUnicode(s)
            let twice = TextCanon.normalizeUnicode(once)
            XCTAssertEqual(once, twice)
        }
    }

    /// CRLF → LF normalization handles all line-ending styles + is idempotent.
    func testLineEndingsNormalization() {
        XCTAssertEqual(TextCanon.normalizeLineEndings("a\r\nb"), "a\nb")
        XCTAssertEqual(TextCanon.normalizeLineEndings("a\rb"), "a\nb")
        XCTAssertEqual(TextCanon.normalizeLineEndings("a\nb"), "a\nb")
        let mixed = "line1\r\nline2\rline3\nline4"
        let normalized = TextCanon.normalizeLineEndings(mixed)
        XCTAssertEqual(TextCanon.normalizeLineEndings(normalized), normalized)
    }

    /// 10k random strings — every one round-trips canonicalize→hash without divergence.
    func testTenThousandRoundTrips() {
        for i in 0..<10_000 {
            let s = Self.randomString(seed: i)
            let h1 = TextCanon.documentHash(s)
            let h2 = TextCanon.documentHash(TextCanon.normalizeLineEndings(s))
            XCTAssertEqual(h1, h2, "Fuzz iteration \(i): hash diverged on re-normalize")
        }
    }

    // MARK: - Helpers

    private static func randomString(seed: Int? = nil) -> String {
        var rng: any RandomNumberGenerator = seed.map { SeededRNG(seed: UInt64($0)) } ?? SystemRandomNumberGenerator()
        let length = Int.random(in: 0...256, using: &rng)
        var s = ""
        let palette: [Character] = ["a", "b", " ", "\n", "🎉", "é", "\u{0301}", "\r", "中"]
        for _ in 0..<length {
            s.append(palette.randomElement(using: &rng) ?? "a")
        }
        return s
    }
}

/// Tiny deterministic RNG for reproducible fuzz seeds.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed | 1 }
    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        return state
    }
}
