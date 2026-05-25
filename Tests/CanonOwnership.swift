// CanonOwnershipTests — Story 0c.
// Asserts only App/TextCanon.swift calls the forbidden canonicalization APIs.
// V1.0 uses a string-grep implementation; Story 0c follow-on swaps to SwiftSyntax AST walk.

import XCTest

final class CanonOwnershipTests: XCTestCase {
    private static let forbiddenPatterns: [String] = [
        ".precomposedStringWithCanonicalMapping",
        ".utf16.count",
        ".utf16.distance",
    ]

    private static let allowlist: Set<String> = [
        "App/TextCanon.swift",
        "Tests/CanonFuzz.swift",
        "Tests/CanonOwnership.swift",
        "Tests/AnchorBitap.swift",
        "Tests/AnchorDrift.swift",
        // AnchorResolver operates on UTF-16 (CM6's native cursor unit) — Bitap and
        // Levenshtein math require direct array access. PR review-justified.
        "Comments/AnchorResolver.swift",
    ]

    func testNoForbiddenCallsOutsideTextCanon() throws {
        let repoRoot = Self.repoRoot()
        let swiftFiles = Self.findSwiftFiles(under: repoRoot)
        XCTAssertGreaterThan(swiftFiles.count, 0, "should find some swift files to scan")

        var offenders: [String] = []
        for file in swiftFiles {
            let relative = file.replacingOccurrences(of: repoRoot + "/", with: "")
            if Self.allowlist.contains(relative) { continue }
            if relative.contains("build/") || relative.contains(".build/") || relative.contains("DerivedData/") {
                continue
            }
            guard let contents = try? String(contentsOfFile: file, encoding: .utf8) else { continue }
            for pattern in Self.forbiddenPatterns where contents.contains(pattern) {
                offenders.append("\(relative): contains forbidden `\(pattern)`")
            }
        }

        if !offenders.isEmpty {
            XCTFail("TextCanon ownership violated. Move CRLF/NFC/UTF-16 calls into App/TextCanon.swift or add the file to allowlist with PR justification:\n - " + offenders.joined(separator: "\n - "))
        }
    }

    private static func repoRoot() -> String {
        var url = URL(fileURLWithPath: #file).deletingLastPathComponent()
        for _ in 0..<5 {
            let marker = url.appendingPathComponent("project.yml")
            if FileManager.default.fileExists(atPath: marker.path) {
                return url.path
            }
            url = url.deletingLastPathComponent()
        }
        return FileManager.default.currentDirectoryPath
    }

    private static func findSwiftFiles(under root: String) -> [String] {
        var results: [String] = []
        guard let enumerator = FileManager.default.enumerator(atPath: root) else { return results }
        for case let path as String in enumerator {
            if path.hasSuffix(".swift") {
                results.append(root + "/" + path)
            }
        }
        return results
    }
}
