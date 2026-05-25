// AccessibilityTests — V1.0 a11y baseline.
//
// PRODUCTION-READINESS.md "Accessibility":
//   * VoiceOver navigates editor, sidebar, comment composer
//   * All controls have accessibility labels
//   * Full keyboard control
//
// Initial coverage: assert every NSControl in the app has a non-empty accessibilityLabel
// and a sensible accessibilityRole. Manual VoiceOver pass tracked in docs/a11y-verified.md.

import XCTest

final class AccessibilityTests: XCTestCase {
    func test_Accessibility_NotYetImplemented() throws {
        try XCTSkipIf(true, "Accessibility V1.0 baseline not yet implemented — see docs/a11y-verified.md")
    }
}
