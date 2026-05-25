// CommentStore — read/write a sidecar with derive-on-save.
// Single entry point for all comment mutations so derivation can't be forgotten.
// See VISION.md "Commenting Design" and the @mentions/tags/addressable spec.

import Foundation
import os.log

private let storeLogger = Logger(subsystem: "com.mdedit.dogfood", category: "session")

enum CommentStore {
    /// Load a sidecar; missing returns an empty CommentSidecar.
    static func load(for documentURL: URL) throws -> CommentSidecar {
        let sidecarURL = sidecarURL(for: documentURL)
        guard FileManager.default.fileExists(atPath: sidecarURL.path) else {
            return CommentSidecar(
                version: 1,
                document: .init(path: documentURL.lastPathComponent, sha256: ""),
                comments: []
            )
        }
        let data = try Data(contentsOf: sidecarURL)
        let decoder = JSONDecoder()
        return try decoder.decode(CommentSidecar.self, from: data)
    }

    /// Save the sidecar; runs `deriveStructured` on every comment first so
    /// `mentions`, `tags`, and `addressable` stay in sync with the body.
    static func save(_ sidecar: CommentSidecar, for documentURL: URL) throws {
        var s = sidecar
        s.comments = s.comments.map(CommentSidecar.deriveStructured)
        s.comments.sort { $0.id < $1.id }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(s)

        let sidecarURL = sidecarURL(for: documentURL)
        // NSFileCoordinator-mediated write — keeps NSFileVersion happy for the sidecar too.
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordError: NSError?
        var writeError: Error?
        coordinator.coordinate(writingItemAt: sidecarURL, options: [.forReplacing], error: &coordError) { url in
            do {
                try data.write(to: url, options: [.atomic])
            } catch {
                writeError = error
            }
        }
        if let writeError { throw writeError }
        if let coordError { throw coordError }
    }

    /// Add a new comment; emits the dogfood signpost the V1.0 gate needs.
    static func addComment(_ comment: CommentSidecar.Comment, to documentURL: URL) throws {
        var sidecar = try load(for: documentURL)
        sidecar.comments.append(comment)
        try save(sidecar, for: documentURL)
        storeLogger.info("event=comment_created")
    }

    /// Resolve a comment; emits the dogfood signpost.
    static func resolveComment(id: String, replyBody: String, by author: CommentSidecar.Author, in documentURL: URL) throws {
        var sidecar = try load(for: documentURL)
        guard let idx = sidecar.comments.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "mdedit.comments", code: 4, userInfo: [NSLocalizedDescriptionKey: "comment id not found: \(id)"])
        }
        let reply = CommentSidecar.Reply(
            author: author,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            body: replyBody
        )
        sidecar.comments[idx].thread.append(reply)
        sidecar.comments[idx].resolved = true
        sidecar.comments[idx].status = .resolved
        try save(sidecar, for: documentURL)
        storeLogger.info("event=comment_resolved")
    }

    private static func sidecarURL(for documentURL: URL) -> URL {
        // foo.md → foo.md.comments.json (sibling, same basename + .comments.json)
        let parent = documentURL.deletingLastPathComponent()
        let name = documentURL.lastPathComponent + ".comments.json"
        return parent.appendingPathComponent(name)
    }
}
