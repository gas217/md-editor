// AppMenu — app-level menu wiring (Help → Check for Updates…, Edit → Add Comment…).
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

    /// Install "Add Comment on Selection" into the Edit menu so the keyboard
    /// shortcut (⌘⇧M) is discoverable. Hidden shortcuts are anti-UX — every
    /// keystroke we expect users to learn needs a menu entry.
    static func installAddCommentItem() {
        guard let mainMenu = NSApp.mainMenu else { return }
        // Edit menu is typically the 4th top-level item (App, File, Edit, …).
        // Find it by name so reordering doesn't break us.
        guard let editMenu = mainMenu.items.first(where: { $0.title == "Edit" })?.submenu else { return }

        let title = "Add Comment on Selection"
        if editMenu.items.contains(where: { $0.title == title }) { return }

        editMenu.addItem(.separator())
        let item = NSMenuItem(
            title: title,
            action: #selector(MenuActions.addComment(_:)),
            keyEquivalent: "m"
        )
        item.keyEquivalentModifierMask = [.command, .shift]
        item.target = MenuActions.shared
        editMenu.addItem(item)
    }
}

@MainActor
@objc final class MenuActions: NSObject {
    static let shared = MenuActions()

    @objc func checkForUpdates(_ sender: Any?) {
        Updater.checkManually()
    }

    /// Forward the Edit-menu "Add Comment on Selection" item to the focused
    /// document's editor. The CM6 keybinding handles ⌘⇧M natively, but the
    /// menu item gives users a visible affordance + makes it work even when
    /// the WebView isn't first responder.
    @objc func addComment(_ sender: Any?) {
        NotificationCenter.default.post(name: .mdeditAddCommentMenuFired, object: nil)
    }

    /// Toolbar "Comments" button — toggle the right-side inspector pane.
    @objc func toggleInspector(_ sender: Any?) {
        NotificationCenter.default.post(name: .mdeditToggleInspectorFired, object: nil)
    }
}

extension Notification.Name {
    static let mdeditAddCommentMenuFired = Notification.Name("com.mdedit.addCommentMenuFired")
    static let mdeditToggleInspectorFired = Notification.Name("com.mdedit.toggleInspectorFired")
}
