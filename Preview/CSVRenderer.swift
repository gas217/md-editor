// CSVRenderer — RFC-4180-tolerant CSV parser → virtualized HTML table.
// V1.1 wedge: MarkEdit has no native CSV view; we render to a sortable table.
// See VISION.md "Supported Formats" → `.csv`.

import Foundation

public enum CSVRenderer {
    /// Parse CSV text into rows. RFC-4180-tolerant:
    /// - quoted fields (`"..."`) may contain `,`, `"` (escaped as `""`), `\r`, `\n`
    /// - CRLF, LF, or CR row terminators all accepted
    /// - empty trailing line tolerated
    public static func parse(_ source: String) -> [[String]] {
        // Iterate Unicode scalars so `\r` and `\n` are distinct (Swift's Character
        // groups `\r\n` into one extended grapheme cluster, which breaks the switch).
        var rows: [[String]] = []
        var current: [String] = []
        var field = ""
        var inQuotes = false
        let scalars = Array(source.unicodeScalars)
        var i = 0

        while i < scalars.count {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < scalars.count && scalars[i + 1] == "\"" {
                        field.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    current.append(field)
                    field = ""
                case "\r":
                    current.append(field)
                    field = ""
                    rows.append(current)
                    current = []
                    if i + 1 < scalars.count && scalars[i + 1] == "\n" {
                        i += 2
                        continue
                    }
                case "\n":
                    current.append(field)
                    field = ""
                    rows.append(current)
                    current = []
                default:
                    field.unicodeScalars.append(c)
                }
            }
            i += 1
        }

        if !field.isEmpty || !current.isEmpty {
            current.append(field)
            rows.append(current)
        }
        // Drop a single trailing empty row (the file's terminator).
        if rows.last?.allSatisfy({ $0.isEmpty }) == true, rows.last?.count == 1 {
            rows.removeLast()
        }
        return rows
    }

    /// Render rows to a self-contained HTML document for the preview WebView.
    /// V1.1 implementation: full table (no virtualization yet — the virtualized
    /// list is a follow-on for files above 10k rows; V1.1 ceiling is 50 MB / ~500k
    /// rows, virtualization lands before that ceiling is exercised).
    public static func renderHTML(_ source: String, hasHeader: Bool = true) -> String {
        let rows = parse(source)
        let normalized: [[String]]
        if hasHeader, let first = rows.first {
            normalized = [first] + Array(rows.dropFirst())
        } else {
            normalized = rows
        }
        let header: String
        let body: [[String]]
        if hasHeader, let h = normalized.first {
            header = "<thead><tr>" + h.map { "<th>\(esc($0))</th>" }.joined() + "</tr></thead>"
            body = Array(normalized.dropFirst())
        } else {
            header = ""
            body = normalized
        }
        let bodyHTML = "<tbody>" + body.map { row in
            "<tr>" + row.map { "<td>\(esc($0))</td>" }.joined() + "</tr>"
        }.joined() + "</tbody>"

        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline';">
        <style>
        html, body { margin: 0; padding: 0; font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 12px; }
        @media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #d4d4d4; } th { background: #2d2d2d; } td { border-color: #444; } }
        table { border-collapse: collapse; width: max-content; }
        th, td { border: 1px solid #ddd; padding: 4px 8px; vertical-align: top; white-space: nowrap; }
        th { background: #f5f5f5; position: sticky; top: 0; font-weight: 600; }
        tr:nth-child(even) td { background: rgba(127,127,127,0.06); }
        .row-num { color: #888; user-select: none; text-align: right; }
        </style></head><body><table>\(header)\(bodyHTML)</table></body></html>
        """
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
