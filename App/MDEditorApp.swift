// MDEditorApp — SwiftUI app shell + AppKit NSDocument bridge.
// See VISION.md "Tech Stack & Architecture" for the AppKit/SwiftUI split.

import SwiftUI
import AppKit
import os.log

/// Dogfood subsystem — `scripts/dogfood-report.sh` queries this via `log show`
/// to compute qualifying-day count for the V1.0 → V1.1 gate.
/// See VISION.md "V1.0 → V1.1 transition gate".
let dogfoodLogger = Logger(subsystem: "com.mdedit.dogfood", category: "session")

@main
struct MDEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // NSDocument-based windows are managed by NSDocumentController, not
        // SwiftUI DocumentGroup — see VISION.md "App lifecycle" decision.
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var sessionStart: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Preload editor WebView process to shave 150-250 ms off cold launch.
        // See VISION.md "WKWebView process model & memory budget reconciliation".
        WebViewPreloader.shared.warmUp()

        // Install crash logger (opt-in transmission is in CrashReporter).
        CrashReporter.install()

        // Check for updates (no-op until Sparkle is wired up).
        Updater.checkOnLaunch()

        // Begin dogfood session.
        sessionStart = Date()
        dogfoodLogger.info("event=launch")

        // Add Help → Check for Updates… menu item (Sparkle does auto-check on its own).
        AppMenu.installCheckForUpdatesItem()
        // Add Edit → Add Comment on Selection (⌘⇧M) so the shortcut is discoverable.
        AppMenu.installAddCommentItem()

        // Welcome window if no document was opened from launch arguments.
        DispatchQueue.main.async {
            WelcomeWindowController.shared.showIfNeeded()
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Show welcome, don't auto-create an Untitled document.
        WelcomeWindowController.shared.showIfNeeded()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Emit session_secs so `scripts/dogfood-report.sh` can tell what was a
        // qualifying day (≥5 min wall-clock + ≥1 save/comment_created/comment_resolved).
        let secs = Int(Date().timeIntervalSince(sessionStart ?? Date()))
        dogfoodLogger.info("event=quit session_secs=\(secs, privacy: .public)")
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        NSLog("[mdedit] application(_:open:) called with %d urls", urls.count)
        for url in urls {
            NSLog("[mdedit] opening: %@", url.path)
            NSDocumentController.shared.openDocument(
                withContentsOf: url,
                display: true,
                completionHandler: { doc, alreadyOpen, error in
                    if let error {
                        NSLog("[mdedit] openDocument FAILED for %@: %@", url.path, "\(error)")
                    } else if doc != nil {
                        NSLog("[mdedit] openDocument OK for %@", url.path)
                        WelcomeWindowController.shared.window?.orderOut(nil)
                    } else {
                        NSLog("[mdedit] openDocument returned nil with no error for %@", url.path)
                    }
                }
            )
        }
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings").font(.title2)
            Button("Check for Updates…") {
                Updater.checkManually()
            }
            Text("MD Editor checks for updates automatically. Use this to force an immediate check.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 380, height: 220)
    }
}
