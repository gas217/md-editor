// WelcomeWindow — TextEdit-style start screen shown when no document is open.
// Standard macOS pattern: Open File / New / drag-here / recent files.
// MarkEdit has this; ours needs it too for parity on first-launch experience.

import AppKit
import SwiftUI

final class WelcomeWindowController: NSWindowController {
    static let shared = WelcomeWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 340),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        super.init(window: window)
        window.contentViewController = NSHostingController(rootView: WelcomeView())
        window.title = "MD Editor"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func showIfNeeded() {
        // Only show if no document windows are open.
        let docs = NSDocumentController.shared.documents
        guard docs.isEmpty else { return }
        showWindow(nil)
    }
}

private struct WelcomeView: View {
    @State private var recents: [URL] = []

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.tint)
                    .padding(.top, 32)
                Text("MD Editor")
                    .font(.title.weight(.semibold))
                Text("Lightweight viewer + light-editor for the files AI agents produce.\nDouble-click an .md, .csv, .json, or .html — see it rendered.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 12) {
                Button {
                    NSDocumentController.shared.openDocument(nil)
                } label: {
                    Label("Open File…", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .accessibilityLabel("Open File")
                .accessibilityHint("Open a markdown, plain text, CSV, JSON, or HTML file from disk")

                Button {
                    // Explicitly create a markdown document — without specifying the
                    // type, NSDocumentController fails with "No document could be created"
                    // because multiple readable types are declared.
                    do {
                        let doc = try NSDocumentController.shared.makeUntitledDocument(ofType: "net.daringfireball.markdown")
                        NSDocumentController.shared.addDocument(doc)
                        doc.makeWindowControllers()
                        doc.showWindows()
                    } catch {
                        NSLog("[mdedit.welcome] New Document failed: \(error)")
                    }
                } label: {
                    Label("New Document", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .accessibilityLabel("New Document")
                .accessibilityHint("Create a new untitled markdown document")
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            if !recents.isEmpty {
                Divider().padding(.vertical, 16)
                Text("Recent").font(.caption).foregroundStyle(.secondary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recents.prefix(5), id: \.self) { url in
                            Button {
                                NSDocumentController.shared.openDocument(
                                    withContentsOf: url,
                                    display: true,
                                    completionHandler: { _, _, _ in }
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "doc")
                                    Text(url.lastPathComponent)
                                    Spacer()
                                    Text(url.deletingLastPathComponent().path)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .truncationMode(.middle)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open \(url.lastPathComponent)")
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            Text("Drag a file here, or use Cmd-O")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 12)
        }
        .frame(width: 500, height: 340)
        .onAppear {
            recents = NSDocumentController.shared.recentDocumentURLs
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            _ = providers.first?.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    NSDocumentController.shared.openDocument(
                        withContentsOf: url,
                        display: true,
                        completionHandler: { _, _, _ in }
                    )
                }
            }
            return true
        }
    }
}
