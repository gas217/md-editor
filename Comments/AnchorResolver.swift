// AnchorResolver — W3C-Web-Annotation-style cascade with Bitap fuzzy match.
// See VISION.md "Anchor resolution algorithm" — text-format cascade.

import Foundation

enum AnchorResolver {
    enum Outcome: Equatable {
        case attached(start: Int, end: Int, driftRecovered: Bool)
        case orphaned(reason: String)
    }

    /// Text-format cascade:
    /// 1. If `document.sha256` matches the current document, use TextPositionSelector directly.
    /// 2. Otherwise, search for `exact` text (NFC-normalized).
    ///    - Exactly one match: attach.
    ///    - Multiple matches: pick the one whose 32-char surroundings best match `prefix`+`suffix` (Bitap edit-distance).
    ///    - Zero matches: try Bitap over the full doc with `exact` as the pattern (ed ≤ ceil(len/25)). Unique candidate → driftRecovered=true.
    /// 3. If everything fails, orphan.
    static func resolveText(
        in document: String,
        documentHash: String,
        position: (start: Int, end: Int)?,
        quote: (exact: String, prefix: String, suffix: String)?
    ) -> Outcome {
        let currentHash = TextCanon.documentHash(document)
        if currentHash == documentHash, let p = position {
            return .attached(start: p.start, end: p.end, driftRecovered: false)
        }
        guard let q = quote, !q.exact.isEmpty else {
            return .orphaned(reason: "no quote selector, hash mismatch")
        }

        let normalizedDoc = TextCanon.normalizeUnicode(document)
        let normalizedExact = TextCanon.normalizeUnicode(q.exact)

        // Find all exact occurrences using UTF-16 offsets (CM6-native units).
        let matches = utf16Ranges(of: normalizedExact, in: normalizedDoc)

        if matches.count == 1, let m = matches.first {
            return .attached(start: m.lowerBound, end: m.upperBound, driftRecovered: false)
        }

        if matches.count > 1 {
            // Disambiguate by prefix/suffix match in the surrounding 32 chars.
            if let best = bestSurroundingMatch(matches: matches, doc: normalizedDoc, prefix: q.prefix, suffix: q.suffix) {
                return .attached(start: best.lowerBound, end: best.upperBound, driftRecovered: false)
            }
            return .orphaned(reason: "multiple matches, prefix/suffix ambiguous")
        }

        // Zero exact matches — fall back to Bitap fuzzy search.
        let maxDistance = max(2, normalizedExact.count / 25)
        if let fuzzy = bitapSearch(pattern: normalizedExact, in: normalizedDoc, maxDistance: maxDistance) {
            return .attached(start: fuzzy.lowerBound, end: fuzzy.upperBound, driftRecovered: true)
        }
        return .orphaned(reason: "no fuzzy match")
    }

    // MARK: - Helpers

    /// All UTF-16 ranges in `doc` where `needle` appears.
    private static func utf16Ranges(of needle: String, in doc: String) -> [Range<Int>] {
        guard !needle.isEmpty else { return [] }
        let docUtf16 = Array(doc.utf16)
        let needleUtf16 = Array(needle.utf16)
        var result: [Range<Int>] = []
        var i = 0
        outer: while i <= docUtf16.count - needleUtf16.count {
            for j in 0..<needleUtf16.count where docUtf16[i + j] != needleUtf16[j] {
                i += 1
                continue outer
            }
            result.append(i..<(i + needleUtf16.count))
            i += needleUtf16.count
        }
        return result
    }

    private static func bestSurroundingMatch(
        matches: [Range<Int>],
        doc: String,
        prefix: String,
        suffix: String
    ) -> Range<Int>? {
        let docUtf16 = Array(doc.utf16)
        // Clamp comparison length to the actual prefix/suffix length — comparing
        // against a 32-char doc context when the recorded prefix is only 6 chars
        // adds spurious 26 chars of "distance" and breaks short-context matching.
        let prePart = String(prefix.suffix(32))
        let postPart = String(suffix.prefix(32))
        let preLen = prePart.utf16.count
        let postLen = postPart.utf16.count

        var scored: [(Range<Int>, Int)] = []
        for m in matches {
            let preStart = max(0, m.lowerBound - max(preLen, 1))
            let preSlice = docUtf16[preStart..<m.lowerBound]
            // Right-align: compare the *last* preLen chars of preSlice against prePart.
            let preAligned: String
            if preSlice.count > preLen {
                preAligned = String(decoding: preSlice.suffix(preLen), as: UTF16.self)
            } else {
                preAligned = String(decoding: preSlice, as: UTF16.self)
            }

            let postEnd = min(docUtf16.count, m.upperBound + max(postLen, 1))
            let postSlice = docUtf16[m.upperBound..<postEnd]
            let postAligned: String
            if postSlice.count > postLen {
                postAligned = String(decoding: postSlice.prefix(postLen), as: UTF16.self)
            } else {
                postAligned = String(decoding: postSlice, as: UTF16.self)
            }

            let dist = (preLen > 0 ? levenshtein(preAligned, prePart) : 0)
                     + (postLen > 0 ? levenshtein(postAligned, postPart) : 0)
            scored.append((m, dist))
        }

        scored.sort { $0.1 < $1.1 }
        guard let (range, dist) = scored.first else { return nil }
        // Uniquely best: second-best must have strictly higher distance.
        let secondBest = scored.dropFirst().first?.1 ?? Int.max
        guard secondBest > dist else { return nil }
        // Acceptance: distance ≤ 25% of (preLen + postLen), bounded by 4.
        let denom = max(1, preLen + postLen)
        let ratio = Double(dist) / Double(denom)
        guard ratio <= 0.25 || dist <= 4 else { return nil }
        return range
    }

    /// Bitap fuzzy search returning the best match if edit distance ≤ maxDistance.
    /// O(n × maxDistance) per the standard algorithm.
    private static func bitapSearch(pattern: String, in text: String, maxDistance: Int) -> Range<Int>? {
        let patternChars = Array(pattern.utf16)
        let textChars = Array(text.utf16)
        let m = patternChars.count
        guard m > 0, m <= 63 else {
            // Pattern too long for 64-bit Bitap word — fall back to linear scan.
            return linearFuzzy(pattern: pattern, in: text, maxDistance: maxDistance)
        }

        // Build pattern mask: for each unique char, bitmap of positions where it does NOT occur.
        var mask = [UInt16: UInt64](minimumCapacity: m)
        for (i, c) in patternChars.enumerated() {
            mask[c, default: ~UInt64(0)] &= ~(UInt64(1) << UInt64(i))
        }

        var R = Array(repeating: ~UInt64(0), count: maxDistance + 1)
        let matchBit = UInt64(1) << UInt64(m - 1)

        for (i, c) in textChars.enumerated() {
            var oldRk_1: UInt64 = R[0]
            R[0] = (R[0] << 1) | (mask[c] ?? ~UInt64(0))
            for k in 1...maxDistance {
                let oldRk = R[k]
                let sub = oldRk_1
                let ins = R[k - 1]
                let del = R[k - 1] << 1
                R[k] = ((oldRk << 1) | (mask[c] ?? ~UInt64(0))) & (sub << 1) & ins & del
                oldRk_1 = oldRk
            }
            if (R[maxDistance] & matchBit) == 0 {
                let end = i + 1
                let start = max(0, end - m - maxDistance)
                return start..<end
            }
        }
        return nil
    }

    /// Fallback for patterns >63 chars: naive O(n×m) edit-distance scan.
    private static func linearFuzzy(pattern: String, in text: String, maxDistance: Int) -> Range<Int>? {
        let textChars = Array(text.utf16)
        let patternChars = Array(pattern.utf16)
        let m = patternChars.count
        var best: (Range<Int>, Int)?
        var i = 0
        while i + m / 2 < textChars.count {
            let end = min(textChars.count, i + m + maxDistance)
            let window = String(decoding: textChars[i..<end], as: UTF16.self)
            let dist = levenshtein(window, pattern)
            if dist <= maxDistance {
                if best == nil || dist < best!.1 {
                    best = (i..<end, dist)
                }
            }
            i += 1
        }
        return best?.0
    }

    /// Standard Levenshtein distance on UTF-16 code units.
    static func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a.utf16)
        let bChars = Array(b.utf16)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        var prev = Array(0...bChars.count)
        var curr = Array(repeating: 0, count: bChars.count + 1)

        for i in 1...aChars.count {
            curr[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,        // deletion
                    curr[j - 1] + 1,    // insertion
                    prev[j - 1] + cost  // substitution
                )
            }
            (prev, curr) = (curr, prev)
        }
        return prev[bChars.count]
    }
}

// AnchorResolver is on the CanonOwnership allowlist because it operates on UTF-16
// code units (CodeMirror's native cursor unit) and must do Bitap math directly.
// See Tests/CanonOwnership.swift.
