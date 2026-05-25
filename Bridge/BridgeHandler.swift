// BridgeHandler — Swift⇄JS wire format. See VISION.md Appendix A.
// JS→Swift via webkit.messageHandlers.bridge; Swift→JS via WebView.evaluateJavaScript.
// Every message: { id, type, payload }. Replies echo `id` with type="reply".

import Foundation
import WebKit

final class BridgeHandler: NSObject, WKScriptMessageHandler {
    private weak var document: MDDocument?
    private weak var webView: WKWebView?

    /// id → completion. 5-second timeout per VISION.md A.1.
    private var pendingReplies: [String: (Result<Any?, Error>) -> Void] = [:]
    private let timeoutSeconds: TimeInterval = 5

    init(document: MDDocument) {
        self.document = document
    }

    func attach(to webView: WKWebView) {
        self.webView = webView
    }

    // MARK: JS → Swift

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any],
              let id = body["id"] as? String,
              let type = body["type"] as? String else {
            return
        }
        let payload = body["payload"]

        if type == "reply" {
            handleReply(id: id, payload: payload)
            return
        }

        switch type {
        case "editor.ready":
            sendDocLoad()
        case "doc.changed":
            if let p = payload as? [String: Any], let text = p["text"] as? String {
                // Keep MDDocument.text in sync with CM6's authoritative state — without
                // this, Cmd-S would persist the original loaded text, not what the user typed.
                document?.applyEditorText(text)
            }
        case "selection.changed":
            break
        case "comment.requested":
            handleCommentRequested(payload)
        case "comment.clicked":
            handleCommentClicked(payload)
        case "status.changed":
            // Forward to the status bar — see DocumentSplitViewController.StatusBarController.
            if let p = payload as? [String: Any] {
                NotificationCenter.default.post(name: .mdeditStatusChanged, object: nil, userInfo: p)
            }
        case "log":
            if let p = payload as? [String: Any], let level = p["level"] as? String, let msg = p["message"] as? String {
                NSLog("[mdedit.bridge] \(level): \(msg)")
            }
        default:
            NSLog("[mdedit.bridge] warn: unknown JS→Swift type: \(type)")
        }
    }

    // MARK: - Comment handling (wires JS bridge → CommentStore so addressable derivation,
    // tag/mention extraction, and dogfood signposts all fire on real user actions.)

    private func handleCommentRequested(_ payload: Any?) {
        guard let document, let url = document.fileURL,
              let p = payload as? [String: Any],
              let from = p["from"] as? Int,
              let to = p["to"] as? Int else { return }
        let exact = p["exact"] as? String ?? ""
        let prefix = p["prefix"] as? String ?? ""
        let suffix = p["suffix"] as? String ?? ""

        // Post a notification with everything the inspector needs.
        // CommentInspector listens and slides in from the right.
        NotificationCenter.default.post(
            name: .mdeditCommentRequested,
            object: nil,
            userInfo: [
                "from": from, "to": to,
                "exact": exact, "prefix": prefix, "suffix": suffix,
                "documentURL": url,
            ]
        )
    }

    private func handleCommentClicked(_ payload: Any?) {
        // V1.0: scroll the comments overlay (right inspector pane) to the thread.
        // UI overlay wiring lands in V1.0 Story 4 final UI pass.
        guard let p = payload as? [String: Any], let id = p["id"] as? String else { return }
        NotificationCenter.default.post(
            name: .mdeditCommentClicked,
            object: nil,
            userInfo: ["id": id]
        )
    }

    // MARK: Swift → JS

    /// Send a message; optional completion fires when JS replies (≤5 s) or times out.
    func send(type: String, payload: [String: Any], reply: ((Result<Any?, Error>) -> Void)? = nil) {
        guard let webView else { return }
        let id = UUID().uuidString
        let msg: [String: Any] = ["id": id, "type": type, "payload": payload]

        if let reply {
            pendingReplies[id] = reply
            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                if let pending = self?.pendingReplies.removeValue(forKey: id) {
                    pending(.failure(BridgeError.timeout(type: type)))
                }
            }
        }

        guard let data = try? JSONSerialization.data(withJSONObject: msg),
              let json = String(data: data, encoding: .utf8) else {
            reply?(.failure(BridgeError.serializationFailed))
            return
        }

        // Single entry point on the JS side: window.bridge.handle({ id, type, payload }).
        let script = "window.bridge.handle(\(json));"
        webView.evaluateJavaScript(script) { [weak self] _, error in
            // Weak self avoids retain cycle through the pendingReplies closure.
            // If self is gone, the WebView is gone too; nothing to reply to.
            guard let self else { return }
            if let error, let pending = self.pendingReplies.removeValue(forKey: id) {
                pending(.failure(error))
            }
        }
    }

    private func sendDocLoad() {
        guard let document else { return }
        send(type: "doc.load", payload: [
            "text": document.text,
            "language": document.format.bridgeLanguage,
            "readOnly": false,
        ])
    }

    private func handleReply(id: String, payload: Any?) {
        guard let pending = pendingReplies.removeValue(forKey: id) else {
            NSLog("[mdedit.bridge] warn: reply for unknown id \(id)")
            return
        }
        if let dict = payload as? [String: Any], let err = dict["error"] as? [String: Any] {
            let msg = (err["message"] as? String) ?? "JS exception"
            pending(.failure(BridgeError.jsException(message: msg)))
        } else {
            let result = (payload as? [String: Any])?["result"]
            pending(.success(result))
        }
    }
}

enum BridgeError: Error {
    case timeout(type: String)
    case serializationFailed
    case jsException(message: String)
}

extension Notification.Name {
    static let mdeditCommentClicked = Notification.Name("com.mdedit.commentClicked")
    static let mdeditCommentsChanged = Notification.Name("com.mdedit.commentsChanged")
    static let mdeditCommentRequested = Notification.Name("com.mdedit.commentRequested")
}
