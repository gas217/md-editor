// Updater — Sparkle 2 integration.
//
// PRODUCTION-READINESS.md "Update mechanism":
//   * Sparkle 2 integration               ✓ this file
//   * Appcast XML hosted at stable URL    ✓ scripts/generate-appcast.sh
//   * EdDSA signature on every update     ✓ scripts/setup-release.sh step 2
//   * "Check for Updates…" menu item      ✓ wired via AppDelegate / menu builder
//   * Rollback path documented            ✓ docs/rollback.md
//
// Setup before this is functional:
//   1. ./scripts/setup-release.sh   (mints the Sparkle EdDSA keypair into Keychain)
//   2. Copy the printed SUPublicEDKey into project.yml Info.plist properties
//   3. Generate appcast via ./scripts/generate-appcast.sh after `make release`

import Foundation
#if canImport(Sparkle)
import Sparkle
#endif

@MainActor
final class Updater: NSObject {
    static let shared = Updater()

    static let appcastURL = URL(string: "https://github.com/gas217/md-editor/releases/download/appcast/appcast.xml")!

    #if canImport(Sparkle)
    private let controller: SPUStandardUpdaterController

    override init() {
        // SPUStandardUpdaterController wires up the default delegate and user driver.
        // startingUpdater: true → automatically checks per the user's preference (default: weekly).
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    /// Called from `AppDelegate.applicationDidFinishLaunching`.
    /// Sparkle's automatic check fires on its own schedule; this hook is here so
    /// the symbol exists and can be customized (force-check-after-N-days, etc).
    static func checkOnLaunch() {
        _ = Updater.shared
    }

    /// Called from the "Check for Updates…" menu item — wired in AppDelegate menu builder.
    static func checkManually() {
        Updater.shared.controller.checkForUpdates(nil)
    }
    #else
    // Sparkle not linked (shouldn't happen in shipped builds; here for SourceKit
    // happiness when reading individual files without the SPM resolved).
    override init() { super.init() }
    static func checkOnLaunch() {}
    static func checkManually() {}
    #endif
}
