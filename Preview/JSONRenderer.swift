// JSONRenderer — pretty-printed collapsible JSON tree.
// V1.1 wedge: MarkEdit has no native JSON tree; we render type-colored values.
// See VISION.md "Supported Formats" → `.json`.

import Foundation

public enum JSONRenderer {
    /// Render JSON source to a self-contained HTML document for the preview WebView.
    /// Parse errors surface inline with a "couldn't parse" banner.
    public static func renderHTML(_ source: String) -> String {
        let data = Data(source.utf8)
        let inner: String
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            inner = renderValue(obj, indent: 0)
        } catch {
            inner = "<div class=\"err\">Couldn't parse JSON: \(esc("\(error)"))</div><pre>\(esc(source))</pre>"
        }

        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline';">
        <style>
        html, body { margin: 0; padding: 12px 16px; font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 12px; line-height: 1.55; }
        @media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #d4d4d4; } .k { color: #9cdcfe; } .s { color: #ce9178; } .n { color: #b5cea8; } .b { color: #569cd6; } .nil { color: #888; font-style: italic; } }
        @media (prefers-color-scheme: light) { .k { color: #0451a5; } .s { color: #a31515; } .n { color: #098658; } .b { color: #0000ff; } .nil { color: #888; font-style: italic; } }
        details { padding-left: 1em; }
        summary { cursor: pointer; outline: none; }
        .err { background: rgba(255,99,71,0.15); padding: 6px 10px; border-radius: 4px; margin-bottom: 8px; font-family: -apple-system; }
        .nested { padding-left: 1em; border-left: 1px dashed rgba(127,127,127,0.3); }
        </style></head><body>\(inner)</body></html>
        """
    }

    private static func renderValue(_ value: Any, indent: Int) -> String {
        if value is NSNull {
            return "<span class=\"nil\">null</span>"
        }
        if let n = value as? NSNumber {
            // Bool is a special-case NSNumber subtype.
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                return "<span class=\"b\">\(n.boolValue)</span>"
            }
            return "<span class=\"n\">\(n)</span>"
        }
        if let s = value as? String {
            return "<span class=\"s\">\"\(esc(s))\"</span>"
        }
        if let arr = value as? [Any] {
            if arr.isEmpty { return "[]" }
            let items = arr.enumerated().map { (i, v) in
                "<div class=\"nested\">[\(i)]: \(renderValue(v, indent: indent + 1))</div>"
            }.joined()
            return "<details open><summary>[\(arr.count) items]</summary>\(items)</details>"
        }
        if let dict = value as? [String: Any] {
            if dict.isEmpty { return "{}" }
            let items = dict.keys.sorted().map { k in
                "<div class=\"nested\"><span class=\"k\">\"\(esc(k))\"</span>: \(renderValue(dict[k]!, indent: indent + 1))</div>"
            }.joined()
            return "<details open><summary>{\(dict.count) keys}</summary>\(items)</details>"
        }
        return "<span>\(esc("\(value)"))</span>"
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
