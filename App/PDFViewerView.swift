// PDFViewerView — V2 PDF support, PDFKit-rendered.
// VISION.md spec: view + comment only, no editing of the PDF itself.
// The PDF stays binary on disk; comments live in the sidecar JSON (foo.pdf.comments.json)
// anchored via PDFAnnotationSelector (pageIndex + rect + selectedText).

import SwiftUI
import PDFKit
import AppKit

struct PDFViewerView: NSViewRepresentable {
    let document: MDDocument

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .underPageBackgroundColor
        view.pageShadowsEnabled = true
        load(into: view)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        load(into: view)
    }

    private func load(into view: PDFView) {
        if let data = document.rawData, let pdf = PDFDocument(data: data) {
            view.document = pdf
        } else if let url = document.fileURL, let pdf = PDFDocument(url: url) {
            view.document = pdf
        }
    }
}
