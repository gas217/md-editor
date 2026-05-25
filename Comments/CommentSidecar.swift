// CommentSidecar — reader/writer for foo.<ext>.comments.json.
// Schema in VISION.md "Commenting Design" / "Sidecar file".

import Foundation

struct CommentSidecar: Codable {
    var version: Int = 1
    var document: DocumentRef
    var comments: [Comment]

    struct DocumentRef: Codable {
        var path: String
        var sha256: String
    }

    struct Comment: Codable {
        var id: String
        var createdAt: String
        var author: Author
        var body: String
        var mentions: [Mention] = []
        var tags: [String] = []
        var resolved: Bool = false
        var addressable: Bool = false
        var status: Status = .active
        var target: Target
        var thread: [Reply] = []

        enum Status: String, Codable {
            case active, orphaned, resolved, archived
        }

        // Forward-compatible decode: missing optional fields take their default values,
        // not a DecodingError. VISION.md examples + externally-authored sidecars must load.
        private enum CodingKeys: String, CodingKey {
            case id, createdAt, author, body, mentions, tags, resolved, addressable, status, target, thread
        }

        init(
            id: String, createdAt: String, author: Author, body: String,
            mentions: [Mention] = [], tags: [String] = [],
            resolved: Bool = false, addressable: Bool = false, status: Status = .active,
            target: Target, thread: [Reply] = []
        ) {
            self.id = id
            self.createdAt = createdAt
            self.author = author
            self.body = body
            self.mentions = mentions
            self.tags = tags
            self.resolved = resolved
            self.addressable = addressable
            self.status = status
            self.target = target
            self.thread = thread
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            createdAt = try c.decode(String.self, forKey: .createdAt)
            author = try c.decode(Author.self, forKey: .author)
            body = try c.decode(String.self, forKey: .body)
            mentions = try c.decodeIfPresent([Mention].self, forKey: .mentions) ?? []
            tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
            resolved = try c.decodeIfPresent(Bool.self, forKey: .resolved) ?? false
            addressable = try c.decodeIfPresent(Bool.self, forKey: .addressable) ?? false
            status = try c.decodeIfPresent(Status.self, forKey: .status) ?? .active
            target = try c.decode(Target.self, forKey: .target)
            thread = try c.decodeIfPresent([Reply].self, forKey: .thread) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try c.encode(createdAt, forKey: .createdAt)
            try c.encode(author, forKey: .author)
            try c.encode(body, forKey: .body)
            try c.encode(mentions, forKey: .mentions)
            try c.encode(tags, forKey: .tags)
            try c.encode(resolved, forKey: .resolved)
            try c.encode(addressable, forKey: .addressable)
            try c.encode(status, forKey: .status)
            try c.encode(target, forKey: .target)
            try c.encode(thread, forKey: .thread)
        }
    }

    /// Known agent handles that, when @-mentioned, imply `addressable: true`.
    /// See VISION.md "Commenting Design" → @mentions.
    static let knownAgents: Set<String> = ["claude", "gemini", "codex", "apple-intelligence"]

    /// Parse `mentions` and `tags` from the body and (for human-authored comments)
    /// derive `addressable` from any @-mention of a known agent. Idempotent —
    /// safe to call on every save.
    static func deriveStructured(_ comment: Comment) -> Comment {
        var c = comment

        // Extract @mentions and #tags using simple word-boundary scans.
        let mentionPattern = try? NSRegularExpression(pattern: #"(?:^|\s)@([a-zA-Z0-9_\-]+)"#)
        let tagPattern = try? NSRegularExpression(pattern: #"(?:^|\s)#([a-zA-Z0-9_\-]+)"#)
        let range = NSRange(c.body.startIndex..., in: c.body)

        var mentions: [Mention] = []
        mentionPattern?.enumerateMatches(in: c.body, range: range) { m, _, _ in
            guard let m, let r = Range(m.range(at: 1), in: c.body) else { return }
            let name = String(c.body[r])
            let kind: Mention.Kind = knownAgents.contains(name.lowercased()) ? .agent : .user
            mentions.append(Mention(kind: kind, name: name))
        }
        var tags: [String] = []
        tagPattern?.enumerateMatches(in: c.body, range: range) { m, _, _ in
            guard let m, let r = Range(m.range(at: 1), in: c.body) else { return }
            tags.append(String(c.body[r]))
        }

        c.mentions = mentions
        c.tags = tags

        // Only the original author (human) may flip `addressable`.
        // If they @-mention a known agent, infer addressable=true.
        // AI-authored replies cannot set addressable; this method respects that.
        if c.author.kind == .human {
            if mentions.contains(where: { $0.kind == .agent }) {
                c.addressable = true
            }
        }

        return c
    }

    struct Author: Codable {
        var kind: Kind
        var name: String
        var model: String?

        enum Kind: String, Codable { case human, ai }
    }

    struct Mention: Codable {
        var kind: Kind
        var name: String

        enum Kind: String, Codable { case user, agent }
    }

    struct Target: Codable {
        var selectors: [Selector]
    }

    /// Wire format per `docs/comments-schema.md`: a flat object with a `type` discriminator.
    /// `TextPositionSelector`, `TextQuoteSelector`, etc. — PascalCase to match W3C Web Annotation spec.
    enum Selector: Codable {
        case textPosition(start: Int, end: Int, startLine: Int, endLine: Int)
        case textQuote(exact: String, prefix: String, suffix: String)
        case csvCell(rowIndex: Int, columnIndex: Int, headerName: String?)
        case csvRowRange(startRowIndex: Int, endRowIndex: Int, primaryKeyColumn: String?, primaryKeyValue: String?)
        case jsonPointer(pointer: String)
        case jsonValue(valueHash: String)
        case pdfAnnotation(pageIndex: Int, rect: PDFRect, quadPoints: [PDFRect]?, selectedText: String?)

        struct PDFRect: Codable {
            var x, y, width, height: Double
        }

        private enum CodingKeys: String, CodingKey {
            case type
            // text position
            case start, end, startLine, endLine
            // text quote
            case exact, prefix, suffix
            // csv cell
            case rowIndex, columnIndex, headerName
            // csv row range
            case startRowIndex, endRowIndex, primaryKeyColumn, primaryKeyValue
            // json pointer / json value
            case pointer, valueHash
            // pdf annotation
            case pageIndex, rect, quadPoints, selectedText
        }

        private static let typeTextPosition = "TextPositionSelector"
        private static let typeTextQuote = "TextQuoteSelector"
        private static let typeCSVCell = "CSVCellSelector"
        private static let typeCSVRowRange = "CSVRowRangeSelector"
        private static let typeJSONPointer = "JSONPointerSelector"
        private static let typeJSONValue = "JSONValueSelector"
        private static let typePDFAnnotation = "PDFAnnotationSelector"

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let type = try c.decode(String.self, forKey: .type)
            switch type {
            case Self.typeTextPosition:
                self = .textPosition(
                    start: try c.decode(Int.self, forKey: .start),
                    end: try c.decode(Int.self, forKey: .end),
                    startLine: try c.decodeIfPresent(Int.self, forKey: .startLine) ?? 0,
                    endLine: try c.decodeIfPresent(Int.self, forKey: .endLine) ?? 0
                )
            case Self.typeTextQuote:
                self = .textQuote(
                    exact: try c.decode(String.self, forKey: .exact),
                    prefix: try c.decodeIfPresent(String.self, forKey: .prefix) ?? "",
                    suffix: try c.decodeIfPresent(String.self, forKey: .suffix) ?? ""
                )
            case Self.typeCSVCell:
                self = .csvCell(
                    rowIndex: try c.decode(Int.self, forKey: .rowIndex),
                    columnIndex: try c.decode(Int.self, forKey: .columnIndex),
                    headerName: try c.decodeIfPresent(String.self, forKey: .headerName)
                )
            case Self.typeCSVRowRange:
                self = .csvRowRange(
                    startRowIndex: try c.decode(Int.self, forKey: .startRowIndex),
                    endRowIndex: try c.decode(Int.self, forKey: .endRowIndex),
                    primaryKeyColumn: try c.decodeIfPresent(String.self, forKey: .primaryKeyColumn),
                    primaryKeyValue: try c.decodeIfPresent(String.self, forKey: .primaryKeyValue)
                )
            case Self.typeJSONPointer:
                self = .jsonPointer(pointer: try c.decode(String.self, forKey: .pointer))
            case Self.typeJSONValue:
                self = .jsonValue(valueHash: try c.decode(String.self, forKey: .valueHash))
            case Self.typePDFAnnotation:
                self = .pdfAnnotation(
                    pageIndex: try c.decode(Int.self, forKey: .pageIndex),
                    rect: try c.decode(PDFRect.self, forKey: .rect),
                    quadPoints: try c.decodeIfPresent([PDFRect].self, forKey: .quadPoints),
                    selectedText: try c.decodeIfPresent(String.self, forKey: .selectedText)
                )
            default:
                // Forward-compat: unknown selector types decode as a textQuote(exact: "")
                // so the cascade can fall through to other selectors. See VISION.md.
                throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown selector type: \(type)")
            }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .textPosition(start, end, startLine, endLine):
                try c.encode(Self.typeTextPosition, forKey: .type)
                try c.encode(start, forKey: .start)
                try c.encode(end, forKey: .end)
                try c.encode(startLine, forKey: .startLine)
                try c.encode(endLine, forKey: .endLine)
            case let .textQuote(exact, prefix, suffix):
                try c.encode(Self.typeTextQuote, forKey: .type)
                try c.encode(exact, forKey: .exact)
                try c.encode(prefix, forKey: .prefix)
                try c.encode(suffix, forKey: .suffix)
            case let .csvCell(rowIndex, columnIndex, headerName):
                try c.encode(Self.typeCSVCell, forKey: .type)
                try c.encode(rowIndex, forKey: .rowIndex)
                try c.encode(columnIndex, forKey: .columnIndex)
                try c.encodeIfPresent(headerName, forKey: .headerName)
            case let .csvRowRange(startRowIndex, endRowIndex, primaryKeyColumn, primaryKeyValue):
                try c.encode(Self.typeCSVRowRange, forKey: .type)
                try c.encode(startRowIndex, forKey: .startRowIndex)
                try c.encode(endRowIndex, forKey: .endRowIndex)
                try c.encodeIfPresent(primaryKeyColumn, forKey: .primaryKeyColumn)
                try c.encodeIfPresent(primaryKeyValue, forKey: .primaryKeyValue)
            case let .jsonPointer(pointer):
                try c.encode(Self.typeJSONPointer, forKey: .type)
                try c.encode(pointer, forKey: .pointer)
            case let .jsonValue(valueHash):
                try c.encode(Self.typeJSONValue, forKey: .type)
                try c.encode(valueHash, forKey: .valueHash)
            case let .pdfAnnotation(pageIndex, rect, quadPoints, selectedText):
                try c.encode(Self.typePDFAnnotation, forKey: .type)
                try c.encode(pageIndex, forKey: .pageIndex)
                try c.encode(rect, forKey: .rect)
                try c.encodeIfPresent(quadPoints, forKey: .quadPoints)
                try c.encodeIfPresent(selectedText, forKey: .selectedText)
            }
        }
    }

    struct Reply: Codable {
        var author: Author
        var createdAt: String
        var body: String
    }
}
