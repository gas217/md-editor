// HTMLTemplate — wrap content in a full HTML document with CSS.
// Simplified extraction: the package ships the baseline CSS and skeleton.
// KaTeX and Mermaid resources are documented as "Story 0a follow-on" — adding them
// requires bundling ~3 MB of JS/CSS as SPM Resources, which is a separate PR.
// The render pipeline degrades gracefully — math/mermaid blocks render as plain
// code blocks if the runtime scripts aren't present, matching preview-md's behavior
// when the bundle lookup returns empty.
//
// To add KaTeX/Mermaid resources later:
//   1. Drop the .js/.css files into Sources/Shared/Resources/
//   2. Declare them in Package.swift target `resources: [.copy("Resources/...")]`
//   3. Replace the empty-string defaults below with `Bundle.module.url(...)` reads.

import Foundation

public enum HTMLTemplate {
    public static let katexScript: String = loadResource("katex.min", "js")
    public static let katexAutoRenderScript: String = loadResource("katex-auto-render.min", "js")
    public static let katexCSS: String = loadResource("katex.min", "css")
    public static let mermaidScript: String = loadResource("mermaid.min", "js")

    private static func loadResource(_ name: String, _ ext: String) -> String {
        // Story 0a follow-on: once we add Resources/ to the target, swap to:
        //   Bundle.module.url(forResource: name, withExtension: ext)
        // For now, return empty so the template degrades gracefully (mermaid/math
        // blocks render as plain code rather than failing the build).
        _ = (name, ext)
        return ""
    }

    public static func build(frontmatter: String, content: String, hasMermaid: Bool = false, hasMath: Bool = false) -> String {
        let nonce = generateNonce()
        let mermaidTag: String
        if hasMermaid && !mermaidScript.isEmpty {
            mermaidTag = """
            <script nonce="\(nonce)">
            \(mermaidScript)
            </script>
            <script nonce="\(nonce)">
            \(mermaidInitScript)
            </script>
            """
        } else {
            mermaidTag = ""
        }

        let mathTag: String
        let mathCSS: String
        if hasMath && !katexScript.isEmpty {
            mathCSS = katexCSS
            mathTag = """
            <script nonce="\(nonce)">
            \(katexScript)
            </script>
            <script nonce="\(nonce)">
            \(katexAutoRenderScript)
            </script>
            <script nonce="\(nonce)">
            \(katexInitScript)
            </script>
            """
        } else {
            mathCSS = ""
            mathTag = ""
        }

        let fontSrc = hasMath ? " font-src data:;" : ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-\(nonce)'; img-src file: data:;\(fontSrc)">
        <style>
        \(baseCSS)
        \(mathCSS)
        </style>
        </head>
        <body>
        \(frontmatter)
        <article class="markdown-body">
        \(content)
        </article>
        \(mermaidTag)
        \(mathTag)
        </body>
        </html>
        """
    }

    private static func generateNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    // Minimal baseline CSS — preview-md ships ~10× this with full theming.
    // Story 0a follow-on: bring the full stylesheet across once we have a place
    // to put the resource (Sources/Shared/Resources/styles.css).
    private static let baseCSS = """
    :root { color-scheme: light dark; }
    html, body { margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif; line-height: 1.6; }
    body { padding: 24px 32px; max-width: 760px; margin: 0 auto; }
    @media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #d4d4d4; } a { color: #69b7ff; } }
    h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin-top: 1.4em; }
    h1 { font-size: 2em; border-bottom: 1px solid currentColor; padding-bottom: 0.2em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #ddd; padding-bottom: 0.2em; }
    p { margin: 0.8em 0; }
    a { color: #0366d6; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code { font-family: ui-monospace, "SF Mono", Menlo, monospace; background: rgba(127,127,127,0.15); padding: 0.1em 0.3em; border-radius: 3px; font-size: 0.92em; }
    pre { background: rgba(127,127,127,0.1); padding: 12px; border-radius: 6px; overflow-x: auto; }
    pre code { background: transparent; padding: 0; }
    blockquote { border-left: 3px solid #ddd; padding-left: 1em; color: #666; margin: 1em 0; }
    .adm-note { border-left-color: #2196f3; }
    .adm-warning { border-left-color: #ff9800; }
    .adm-caution, .adm-important { border-left-color: #f44336; }
    .adm-tip { border-left-color: #4caf50; }
    table { border-collapse: collapse; width: 100%; }
    .table-wrap { overflow-x: auto; }
    th, td { border: 1px solid #ddd; padding: 6px 10px; }
    th { background: rgba(127,127,127,0.1); }
    hr { border: none; border-top: 1px solid #ddd; margin: 1.5em 0; }
    img { max-width: 100%; height: auto; }
    .task-list-item { list-style: none; margin-left: -1.5em; }
    .task-list-item.done { opacity: 0.7; }
    .frontmatter { padding: 12px 16px; border: 1px solid #ddd; border-radius: 8px; background: rgba(127,127,127,0.05); margin-bottom: 1.5em; }
    .fm-title { margin: 0 0 0.5em 0; border: none; padding: 0; }
    .fm-meta { font-size: 0.92em; color: #666; }
    .fm-badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 0.85em; margin-right: 6px; background: #888; color: white; }
    .badge-green { background: #4caf50; }
    .badge-blue { background: #2196f3; }
    .badge-red { background: #f44336; }
    .badge-orange { background: #ff9800; }
    .badge-yellow { background: #f9a825; }
    .badge-gray { background: #888; }
    .fm-tag { display: inline-block; padding: 2px 8px; border-radius: 4px; background: rgba(127,127,127,0.2); font-size: 0.85em; margin-right: 4px; }
    .fm-date { margin-right: 12px; }
    .fm-fields { margin: 0.8em 0 0 0; font-size: 0.9em; display: grid; grid-template-columns: max-content 1fr; gap: 4px 12px; }
    .fm-fields dt { font-weight: 600; color: #666; }
    .fm-fields dd { margin: 0; }
    .mermaid-block { text-align: center; margin: 1em 0; }
    .mermaid-error { color: #c00; }
    """

    private static let mermaidInitScript = """
    (function() {
        if (typeof mermaid === 'undefined') return;
        function esc(s) { return s.replace(/[&<>]/g, function(c){ return ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]); }); }
        mermaid.initialize({ startOnLoad: false, securityLevel: 'strict' });
        var blocks = document.querySelectorAll('.mermaid-block[data-mermaid-src]');
        blocks.forEach(function(el, i) {
            var src = el.dataset.mermaidSrc;
            var id = 'mermaid-svg-' + i;
            try {
                mermaid.render(id, src).then(function(result) {
                    el.innerHTML = result.svg;
                    el.removeAttribute('data-mermaid-src');
                }).catch(function(err) {
                    el.removeAttribute('data-mermaid-src');
                    el.innerHTML = '<div class="mermaid-error"><strong>Mermaid error:</strong> ' +
                        esc(err && err.message ? err.message : String(err)) + '</div>';
                });
            } catch (err) {
                el.removeAttribute('data-mermaid-src');
                el.innerHTML = '<div class="mermaid-error"><strong>Error:</strong> ' + esc(String(err)) + '</div>';
            }
        });
    })();
    """

    private static let katexInitScript = """
    (function() {
        if (typeof renderMathInElement === 'undefined') return;
        renderMathInElement(document.body, {
            delimiters: [
                {left: '$$', right: '$$', display: true},
                {left: '\\\\[', right: '\\\\]', display: true},
                {left: '\\\\(', right: '\\\\)', display: false},
                {left: '$', right: '$', display: false}
            ],
            throwOnError: false
        });
    })();
    """
}
