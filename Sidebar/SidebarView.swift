// SidebarView — single-folder file browser.
// V1.0: filters to .md/.txt; V1.1 expands to all supported formats.
// See VISION.md Story 6.

import SwiftUI

struct SidebarView: View {
    @State private var folderURL: URL?
    @State private var files: [URL] = []

    var body: some View {
        List(files, id: \.self) { url in
            Text(url.lastPathComponent)
                .onTapGesture {
                    NSDocumentController.shared.openDocument(
                        withContentsOf: url,
                        display: true,
                        completionHandler: { _, _, _ in }
                    )
                }
                .accessibilityLabel(url.lastPathComponent)
                .accessibilityHint("Open this file in the editor")
                .accessibilityAddTraits(.isButton)
        }
        .accessibilityLabel("Files in folder")
    }
}
