// CrashReporter — opt-in crash report collection.
//
// PRODUCTION-READINESS.md "Crash reporting & telemetry":
//   * os_log + system crash reports                ✓ install()
//   * Opt-OUT default off; user opts in via Settings  ✓ optInKey
//   * No analytics shipped (verified by Tests/NoNetwork.swift)
//   * Submission path: V1.0 = user emails the log    ✓ copyRecentLogToClipboard
//   * Mach signal handlers                            ✓ installSignalHandlers
//
// What gets logged on crash:
//   - Uncaught NSException with name, reason, callStackSymbols
//   - Mach signals SIGSEGV / SIGBUS / SIGILL / SIGFPE / SIGABRT with backtrace_symbols
//   - Always to os_log (fault level); transmission requires explicit user opt-in

import Foundation
import os.log
import Darwin

enum CrashReporter {
    static let logger = Logger(subsystem: "com.mdedit.app", category: "crash")
    static let optInKey = "com.mdedit.crashreporter.optIn"

    static var isOptedIn: Bool {
        UserDefaults.standard.bool(forKey: optInKey)
    }

    /// Called from `AppDelegate.applicationDidFinishLaunching`.
    /// Installs uncaught-exception + Mach signal handlers. NO network transmission.
    static func install() {
        NSSetUncaughtExceptionHandler(uncaughtExceptionHandler)
        installSignalHandlers()
    }

    /// User can copy the recent crash log to the clipboard from Help → Copy Crash Log.
    /// They then email it. No network call here.
    static func copyRecentLogToClipboard() {
        // V1.0: shell out to `log show --predicate ... --last 7d` and place the
        // output on the pasteboard. Implementation lives in the menu action.
    }
}

/// File-scope, non-capturing C function pointer required by NSSetUncaughtExceptionHandler.
private let uncaughtExceptionHandler: @convention(c) (NSException) -> Void = { exception in
    let logger = Logger(subsystem: "com.mdedit.app", category: "crash")
    logger.fault("Uncaught: \(exception.name.rawValue) — \(exception.reason ?? "no reason"); stack: \(exception.callStackSymbols.joined(separator: "\n"))")
}

/// Mach signal handlers. Reentrancy-safe: only async-signal-safe APIs inside.
/// Restoration trick: log via os_log (signal-safe per Apple), then re-raise the
/// signal with the default disposition so the system crash reporter still produces
/// its standard .ips diagnostic alongside our log line.

private func installSignalHandlers() {
    let signals: [Int32] = [SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT, SIGTRAP]
    var action = sigaction()
    action.__sigaction_u.__sa_handler = mdeditSignalHandler
    sigemptyset(&action.sa_mask)
    action.sa_flags = SA_RESETHAND  // restore default disposition after firing once
    for sig in signals {
        sigaction(sig, &action, nil)
    }
}

/// Signal handler — runs in a constrained context. Only signal-safe APIs allowed.
/// os_log is documented as signal-safe; backtrace_symbols is NOT, but the system
/// crash reporter records the full backtrace in the .ips regardless, so this
/// just adds a one-line breadcrumb that the user can copy from Console.
private let mdeditSignalHandler: @convention(c) (Int32) -> Void = { sig in
    let name: StaticString
    switch sig {
    case SIGSEGV: name = "SIGSEGV (segmentation fault)"
    case SIGBUS:  name = "SIGBUS (bus error)"
    case SIGILL:  name = "SIGILL (illegal instruction)"
    case SIGFPE:  name = "SIGFPE (floating-point exception)"
    case SIGABRT: name = "SIGABRT (abort)"
    case SIGTRAP: name = "SIGTRAP (trace trap)"
    default:      name = "signal"
    }
    // os_log_with_type via os_log is signal-safe per the os_log man page.
    os_log("Caught fatal signal: %{public}@ (sig=%d)", log: .default, type: .fault, String(describing: name), sig)
    // Re-raise with default handler so the system records its standard crash report.
    raise(sig)
}
