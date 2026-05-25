// AnchorDriftTests — V1.0 Story 5 acceptance.
// EditGenerator + drift report against a corpus of mutations.
// Pass bar (per VISION.md): ≥95% re-anchor; ≤5% must orphan; mis-anchor rate must be 0%.

import XCTest
@testable import MDEditor

final class AnchorDriftTests: XCTestCase {
    /// Insert a line above the anchor — text-position breaks; quote selector should win.
    func testInsertLineAbovePreservesAnchor() {
        let edited = "PREPENDED LINE\nThe quick brown fox jumps over the lazy dog."
        let result = AnchorResolver.resolveText(
            in: edited,
            documentHash: "stale",
            position: nil,
            quote: ("brown fox", "quick ", " jumps")
        )
        if case .attached = result {} else { XCTFail("expected attached, got \(result)") }
    }

    /// Delete a line below — anchor should still resolve.
    func testDeleteLineBelowPreservesAnchor() {
        let edited = "The quick brown fox jumps over the lazy dog."
        let result = AnchorResolver.resolveText(
            in: edited,
            documentHash: "stale",
            position: nil,
            quote: ("brown fox", "quick ", " jumps")
        )
        if case .attached = result {} else { XCTFail("expected attached, got \(result)") }
    }

    /// Duplicate the anchored text elsewhere — prefix disambiguates.
    func testDuplicateAnchoredTextDisambiguated() {
        let edited = "before the cat sat. midway the cat sat. end."
        let result = AnchorResolver.resolveText(
            in: edited,
            documentHash: "stale",
            position: nil,
            quote: ("the cat sat", "midway ", ".")
        )
        if case let .attached(start, _, _) = result {
            XCTAssertGreaterThan(start, 20, "should pick the SECOND occurrence (after 'midway ')")
        } else {
            XCTFail("expected attached, got \(result)")
        }
    }

    /// No-match case: orphan, never mis-attach silently.
    func testMisAnchorRateIsZero() {
        let edited = "totally different content here"
        let result = AnchorResolver.resolveText(
            in: edited,
            documentHash: "stale",
            position: nil,
            quote: ("text that does not exist anywhere", "", "")
        )
        guard case .orphaned = result else {
            XCTFail("Mis-anchor: expected orphan, got \(result). MIS-ANCHOR RATE MUST BE 0%.")
            return
        }
    }

    /// Drift report: run a small corpus of edits against AnchorResolver and tally
    /// (passed / orphaned / mis-anchored). Per VISION.md: mis-anchor must be 0;
    /// re-attach ≥95%.
    func testDriftReportPassRate() {
        struct Case { let label: String; let doc: String; let quote: (exact: String, prefix: String, suffix: String) }
        let cases: [Case] = [
            Case(label: "insert-above", doc: "ABOVE\nThe quick brown fox runs.",
                 quote: ("brown fox", "quick ", " runs")),
            Case(label: "delete-below", doc: "The quick brown fox runs.",
                 quote: ("brown fox", "quick ", " runs")),
            Case(label: "prepend-1k",   doc: String(repeating: "x ", count: 500) + "brown fox stays",
                 quote: ("brown fox", " ", " stays")),
            Case(label: "append-1k",    doc: "the brown fox stays " + String(repeating: "x ", count: 500),
                 quote: ("brown fox", "the ", " stays")),
        ]
        var passing = 0
        var orphans = 0
        var misAnchors = 0
        for c in cases {
            let r = AnchorResolver.resolveText(
                in: c.doc,
                documentHash: "stale",
                position: nil,
                quote: c.quote
            )
            switch r {
            case let .attached(start, end, _):
                let docUtf16 = Array(c.doc.utf16)
                if end <= docUtf16.count, start <= end {
                    let slice = String(decoding: docUtf16[start..<end], as: UTF16.self)
                    if slice == c.quote.exact {
                        passing += 1
                    } else {
                        misAnchors += 1
                    }
                } else {
                    misAnchors += 1
                }
            case .orphaned:
                orphans += 1
            }
        }
        XCTAssertEqual(misAnchors, 0, "Mis-anchor rate must be 0%; got \(misAnchors) of \(cases.count) — VISION.md hard rule.")
        let passRate = Double(passing) / Double(cases.count)
        XCTAssertGreaterThanOrEqual(passRate, 0.95, "Re-anchor rate \(passRate * 100)% below the ≥95% pass bar.")
    }
}
