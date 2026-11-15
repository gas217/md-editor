// CommentInspector — right-edge sliding panel for comments.
// Replaces the V1.0 NSAlert composer with the spec'd UX from VISION.md:
// "Click the indicator to reveal the thread in a right-edge inspector panel that
//  slides in over the editor (not a popover — popovers steal focus and break dictation)."
//
// Features:
// - New-comment composer with live @mention and #tag highlighting + an affordance tip
// - Existing thread view with replies
// - Cmd-Enter to save; Esc to dismiss
// - Wired to CommentStore.addComment / resolveComment

import SwiftUI

/// Owns the inspector's state across SwiftUI view recreations. Critical fix:
/// the inspector's NSHostingController is collapsed by default on .md/.txt, so
/// its SwiftUI view is NOT in the hierarchy when the user fires ⌘⇧M. If the
/// `.onReceive` subscription lived inside the SwiftUI view, the notification
/// would arrive BEFORE the view subscribed and the comment would silently
/// vanish. By owning the observers here and storing state across reveals, the
/// SwiftUI view just renders whatever's in the model on mount.
final class CommentInspectorModel: ObservableObject {
    @Published var composer: ComposerContext?
    @Published var activeThread: CommentSidecar.Comment?

    let document: MDDocument
    private var observers: [NSObjectProtocol] = []

    init(document: MDDocument) {
        self.document = document
        observers.append(NotificationCenter.default.addObserver(
            forName: .mdeditCommentRequested, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let from = info["from"] as? Int,
                  let to = info["to"] as? Int,
                  let url = info["documentURL"] as? URL,
                  // Notifications are app-wide; filter to this document's URL.
                  url == self.document.fileURL else { return }
            self.activeThread = nil
            self.composer = ComposerContext(
                from: from, to: to,
                exact: info["exact"] as? String ?? "",
                prefix: info["prefix"] as? String ?? "",
                suffix: info["suffix"] as? String ?? "",
                documentURL: url
            )
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: .mdeditCommentClicked, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let id = info["id"] as? String,
                  let url = info["documentURL"] as? URL,
                  url == self.document.fileURL else { return }
            self.composer = nil
            do {
                let sidecar = try CommentStore.load(for: url)
                if let match = sidecar.comments.first(where: { $0.id == id }) {
                    self.activeThread = match
                }
            } catch {
                NSLog("[mdedit.inspector] load failed: \(error)")
            }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: .mdeditCommentsChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self,
                  let active = self.activeThread,
                  let url = document.fileURL else { return }
            if let sidecar = try? CommentStore.load(for: url),
               let updated = sidecar.comments.first(where: { $0.id == active.id }) {
                self.activeThread = updated
            }
        })
    }

    deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

    func dismissComposer() { composer = nil }
    func dismissThread() { activeThread = nil }
}

struct CommentInspectorContainer: View {
    @ObservedObject var model: CommentInspectorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if let composer = model.composer {
                ComposerView(context: composer, document: model.document) {
                    model.dismissComposer()
                }
            } else if let activeThread = model.activeThread {
                ThreadView(comment: activeThread, document: model.document) {
                    model.dismissThread()
                }
            } else {
                EmptyStateView()
            }
        }
        .frame(minWidth: 280, idealWidth: 340)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Image(systemName: "bubble.left.and.bubble.right")
            Text("Comments")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityIdentifier("inspectorHeader")
    }
}

struct ComposerContext: Identifiable {
    let id = UUID()
    let from: Int
    let to: Int
    let exact: String
    let prefix: String
    let suffix: String
    let documentURL: URL
}

struct ComposerView: View {
    let context: ComposerContext
    let document: MDDocument
    let onDismiss: () -> Void
    @State private var commentBody: String = ""
    @FocusState private var focused: Bool

    private var detectedMentions: [String] {
        let pattern = try! NSRegularExpression(pattern: #"(?:^|\s)@([a-zA-Z0-9_\-]+)"#)
        let range = NSRange(commentBody.startIndex..., in: commentBody)
        return pattern.matches(in: commentBody, range: range).compactMap { m in
            guard let r = Range(m.range(at: 1), in: commentBody) else { return nil }
            return String(commentBody[r])
        }
    }
    private var detectedTags: [String] {
        let pattern = try! NSRegularExpression(pattern: #"(?:^|\s)#([a-zA-Z0-9_\-]+)"#)
        let range = NSRange(commentBody.startIndex..., in: commentBody)
        return pattern.matches(in: commentBody, range: range).compactMap { m in
            guard let r = Range(m.range(at: 1), in: commentBody) else { return nil }
            return String(commentBody[r])
        }
    }
    private var willAddressAgent: String? {
        let agents: Set<String> = ["claude", "gemini", "codex", "apple-intelligence"]
        return detectedMentions.first(where: { agents.contains($0.lowercased()) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !context.exact.isEmpty {
                Text("On: " + String(context.exact.prefix(120)) + (context.exact.count > 120 ? "…" : ""))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            TextEditor(text: $commentBody)
                .focused($focused)
                .font(.body)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .accessibilityLabel("Comment body")
                .accessibilityIdentifier("composerBody")
                .accessibilityHint("Type your comment. Mention @claude to route to Claude. Use #tags to triage.")

            if !detectedMentions.isEmpty || !detectedTags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(detectedMentions, id: \.self) { name in
                        Label(name, systemImage: "at")
                            .font(.caption.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.18), in: Capsule())
                    }
                    ForEach(detectedTags, id: \.self) { tag in
                        Label(tag, systemImage: "number")
                            .font(.caption.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.18), in: Capsule())
                    }
                    Spacer()
                }
            }

            if let agent = willAddressAgent {
                Label("Will route to \(agent) for action", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.tint)
            } else {
                Text("Tip: type @claude to address with Claude. #tags to triage.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                Button("Cancel", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("composerCancel")
                Spacer()
                Button("Save", action: save)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(commentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("composerSave")
            }
        }
        .padding(14)
        .onAppear { focused = true }
    }

    private func save() {
        let comment = CommentSidecar.Comment(
            id: "c_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(24).description,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            author: .init(kind: .human, name: NSFullUserName()),
            body: commentBody,
            target: .init(selectors: [
                .textPosition(start: context.from, end: context.to, startLine: 0, endLine: 0),
                .textQuote(exact: context.exact, prefix: context.prefix, suffix: context.suffix),
            ])
        )
        do {
            try CommentStore.addComment(comment, to: context.documentURL)
            NotificationCenter.default.post(name: .mdeditCommentsChanged, object: nil)
            onDismiss()
        } catch {
            NSLog("[mdedit.inspector] addComment failed: \(error)")
        }
    }
}

struct ThreadView: View {
    let comment: CommentSidecar.Comment
    let document: MDDocument
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Label(comment.resolved ? "Resolved" : "Open", systemImage: comment.resolved ? "checkmark.circle" : "bubble.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(comment.author.name)
                    .font(.caption.weight(.semibold))
                Text(comment.body)
                    .font(.body)
                    .textSelection(.enabled)
                ForEach(comment.thread.indices, id: \.self) { idx in
                    let reply = comment.thread[idx]
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(reply.author.kind.rawValue): \(reply.author.name)")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(reply.body).font(.callout)
                    }
                    .padding(.leading, 10)
                    .overlay(Rectangle().frame(width: 2).foregroundStyle(Color.accentColor.opacity(0.5)), alignment: .leading)
                }
                Button("Close", action: onDismiss)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(14)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.middle.bottom")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No comment selected")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Select text and press ⌘⇧M to add one.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
