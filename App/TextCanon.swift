// TextCanon — the *only* file in the repo that owns:
//   * CRLF→LF line-ending normalization
//   * NFC Unicode normalization
//   * UTF-16 code-unit offset arithmetic
//
// Enforced by Tests/CanonOwnership.swift (SwiftSyntax AST walk).
// Forbidden outside this file:
//   .precomposedStringWithCanonicalMapping
//   .utf16.count / .utf16.distance(...)
//   .replacingOccurrences(of: "\r\n", ...)
//   raw "\r\n" string literals
//
// See VISION.md "Canonicalization module".

import Foundation
import CryptoKit

enum TextCanon {
    /// Normalize CRLF (and lone CR) to LF.
    static func normalizeLineEndings(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "\r\n", with: "\n")
        out = out.replacingOccurrences(of: "\r", with: "\n")
        return out
    }

    /// NFC-normalize.
    static func normalizeUnicode(_ s: String) -> String {
        s.precomposedStringWithCanonicalMapping
    }

    /// UTF-16 code-unit length.
    static func utf16Length(_ s: String) -> Int {
        s.utf16.count
    }

    /// SHA-256 of the LF-normalized UTF-8 bytes.
    /// Stable across machines that flip line endings.
    static func documentHash(_ source: String) -> String {
        let normalized = normalizeLineEndings(source)
        let data = Data(normalized.utf8)
        return data.sha256Hex()
    }
}

private extension Data {
    func sha256Hex() -> String {
        SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}
