// AppMenu — Help → Check for Updates… menu item wiring.
// Sparkle ships its own automatic-check schedule; this is the manual fallback
// per Apple HIG (apps with auto-update should still expose a manual check).

import AppKit

@MainActor
enum AppMenu {
    /// Append "Check for Updates…" to the application menu. Called from
    /// `AppDelegate.applicationDidFinishLaunching` so the menu bar reflects it.
    static func installCheckForUpdatesItem() {
        guard let mainMenu = NSApp.mainMenu,
              let appMenuItem = mainMenu.items.first,
              let appMenu = appMenuItem.submenu else { return }

        let title = "Check for Updates…"
        if appMenu.items.contains(where: { $0.title == title }) { return }
        let item = NSMenuItem(
            title: title,
            action: #selector(MenuActions.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = MenuActions.shared
        appMenu.insertItem(item, at: 1)
    }
}

@MainActor
@objc final class MenuActions: NSObject {
    static let shared = MenuActions()

    @objc func checkForUpdates(_ sender: Any?) {
        Updater.checkManually()
    }
}
