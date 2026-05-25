// NoNetworkTests — asserts MD Editor makes zero outbound network requests during normal use.
//
// PRODUCTION-READINESS.md "Privacy & compliance":
//   * No data collection of any kind by default
//
// VISION.md / non-goals:
//   * No telemetry
//
// V1.0 acceptance: launch the app, open a .md, add a comment, save, quit.
// Assert: zero network requests, zero DNS lookups initiated by the app.

import XCTest

final class NoNetworkTests: XCTestCase {
    func test_NoNetwork_NotYetImplemented() throws {
        // TODO V1.0: spin up a local pcap or NWPathMonitor watcher, run the cold-launch + open + comment
        // scenario, assert zero outbound packets. May also use the macOS NetworkSandbox for stricter assertion.
        try XCTSkipIf(true, "NoNetwork V1.0 not yet implemented — see PRODUCTION-READINESS.md")
    }
}
