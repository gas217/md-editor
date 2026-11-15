import Foundation

/// Projects persisted text comments into safe CodeMirror ranges. This is a view
/// of the sidecar: opening a document must never rewrite its comments.
enum CommentPresentation {
    static func markers(in sidecar: CommentSidecar, text: String) -> [[String: Any]] {
        sidecar.comments.compactMap { comment in
            guard comment.status != .archived else { return nil }
            var position: (start: Int, end: Int)?
            var quote: (exact: String, prefix: String, suffix: String)?
            for selector in comment.target.selectors {
                switch selector {
                case let .textPosition(start, end, _, _): position = (start, end)
                case let .textQuote(exact, prefix, suffix): quote = (exact, prefix, suffix)
                default: break
                }
            }
            guard let quote, !quote.exact.isEmpty else { return nil }
            let outcome = AnchorResolver.resolveText(
                in: text, documentHash: sidecar.document.sha256,
                position: position, quote: quote
            )
            guard case let .attached(start, end, _) = outcome,
                  // The resolver uses normalized offsets and may return fuzzy matches.
                  // Only show a marker when the actual displayed range still matches.
                  let actual = TextCanon.substring(text, from: start, to: end),
                  actual == quote.exact else { return nil }
            return ["id": comment.id, "from": start, "to": end,
                    "status": comment.resolved ? "resolved" : comment.status.rawValue]
        }
    }
}
