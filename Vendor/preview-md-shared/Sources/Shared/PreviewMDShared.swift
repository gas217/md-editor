// PreviewMDShared — top-level facade for the markdown rendering engine.
// Consumed by both md-editor (the app) and preview-md (the Quick Look extension).

import Foundation

public enum PreviewMDShared {
    public static let version = "0.2.0"

    /// Render markdown source to a full HTML document.
    /// Wraps the pipeline: FrontmatterParser → HTMLConverter (via swift-markdown) → HTMLTemplate.
    public static func render(_ source: String) -> String {
        MarkdownRenderer.render(source)
    }

    /// Render a markdown file at a given URL.
    public static func render(fileAt url: URL) throws -> String {
        try MarkdownRenderer.render(fileAt: url)
    }
}
