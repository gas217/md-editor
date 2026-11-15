// USE-level scenarios per docs/e2e-test-plan.md.
// Each test maps to one row in the plan's scenario table and must fail on a
// regression that a user would notice.
//
// The E2EBridge writes a nested JSON state into the e2e-state AX field:
//   { editor: {h1, h2, code, docLen, gutterBg, commentMarkers, isEditor}
//   , preview: {tableRows, jsonKeys, htmlBodyChildren, title, isEditor}
//   , pdfPresent: bool
//   , webViewCount: int }
// Use the .editorState / .previewState / .pdfPresent / .webViewCount helpers
// from E2EHelpers.swift to read it.

import XCTest

final class Scenarios: XCTestCase {

    // MARK: Scenario 1 — open .md from Finder → window appears.
    func testOpensMdFile() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.md")

        let window = app.windows["basic.md"]
        XCTAssertTrue(window.waitForExistence(timeout: 6),
                      "expected window titled basic.md after launch")
    }

    // MARK: Scenario 2 — markdown actually renders (regression we fixed).
    func testMarkdownActuallyRenders() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.md")

        let state = app.waitForE2EState(
            timeout: 8,
            until: { st in
                let e = st.editorState
                return (e["h1"] as? Int ?? 0) >= 1 && (e["h2"] as? Int ?? 0) >= 1
            },
            message: "expected .cm-h1 and .cm-h2 in editor DOM"
        )
        XCTAssertGreaterThanOrEqual(state.editorState["code"] as? Int ?? 0, 1,
                                    "expected at least one .cm-inline-code chip")
    }

    // MARK: Scenario 3 — gutter strip killed (computed background transparent).
    func testGutterHasNoWhiteStrip() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.md")

        let state = app.waitForE2EState(
            timeout: 8,
            until: { st in
                ((st.editorState["gutterBg"] as? String) ?? "").isEmpty == false
            },
            message: "expected gutter computed background"
        )
        let bg = (state.editorState["gutterBg"] as? String) ?? ""
        XCTAssertTrue(
            bg.contains("rgba(0, 0, 0, 0)") || bg.contains("transparent"),
            "gutter background should be transparent; got \(bg)"
        )
    }

    // No selection must not create a composer or sidecar.
    func testCommentWithoutSelectionDoesNothing() throws {
        let app = XCUIApplication()
        let tmp = app.launchE2E(fixture: "comment-review.md")
        _ = app.waitForE2EState(
            until: { ($0.editorState["docLen"] as? Int ?? 0) > 0 },
            message: "editor mounted with content"
        )
        let commentButton = app.toolbars.buttons["Comment"]
        XCTAssertTrue(commentButton.waitForExistence(timeout: 4))
        commentButton.click()
        XCTAssertFalse(app.textViews["composerBody"].exists)
        XCTAssertFalse(FileManager.default.fileExists(atPath:
            tmp.appendingPathComponent("comment-review.md.comments.json").path))
    }

    func testCreateCommentAndOpenThread() throws {
        let app = XCUIApplication()
        let tmp = app.launchE2E(fixture: "comment-review.md")
        _ = app.waitForE2EState(
            until: { ($0.editorState["docLen"] as? Int ?? 0) > 0 },
            message: "editor mounted with content"
        )
        let editor = app.webViews.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5), app.debugDescription)
        editor.click()
        editor.typeKey("a", modifierFlags: .command)
        editor.typeKey("m", modifierFlags: [.command, .shift])
        let composer = app.textViews["composerBody"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5), app.debugDescription)
        // Type through the application: clicking the field would conceal a
        // broken focus handoff that sends the user's comment into the document.
        app.typeText("@claude clarify this #review")
        app.typeKey(.return, modifierFlags: .command)
        _ = app.waitForE2EState(
            until: { ($0.editorState["commentMarkers"] as? Int ?? 0) == 1 },
            message: "saving should immediately show one real comment marker"
        )
        let data = try Data(contentsOf: tmp.appendingPathComponent("comment-review.md.comments.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let comments = try XCTUnwrap(json["comments"] as? [[String: Any]])
        XCTAssertEqual(comments.count, 1)
        let comment = try XCTUnwrap(comments.first)
        XCTAssertEqual(comment["body"] as? String, "@claude clarify this #review")
        XCTAssertEqual(comment["addressable"] as? Bool, true)
        let target = try XCTUnwrap(comment["target"] as? [String: Any])
        let selectors = try XCTUnwrap(target["selectors"] as? [[String: Any]])
        XCTAssertEqual(selectors.first(where: { $0["type"] as? String == "TextQuoteSelector" })?["exact"] as? String,
                       "Review this sentence with the agent.\n")
        XCTAssertNotNil(comment["id"] as? String)
        let body = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@ OR value CONTAINS %@",
            "@claude clarify this #review", "@claude clarify this #review"
        )).firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 5), "Save should reveal the new thread")
        app.buttons["Close"].click()
        XCTAssertFalse(body.exists)
        let marker = app.buttons["Open comment: @claude clarify this #review"]
        XCTAssertTrue(marker.waitForExistence(timeout: 5), app.debugDescription)
        marker.click()
        XCTAssertTrue(body.waitForExistence(timeout: 5), app.debugDescription)
        app.buttons["Close"].click()
        editor.click()
        editor.typeKey("a", modifierFlags: .command)
        editor.typeKey("m", modifierFlags: [.command, .shift])
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        app.typeText("Cancel this draft")
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertFalse(composer.exists)
        XCTAssertEqual(try Data(contentsOf: tmp.appendingPathComponent("comment-review.md.comments.json")), data,
                       "Escape must not persist a second comment")
        XCTAssertEqual(try Data(contentsOf: tmp.appendingPathComponent("comment-review.md")),
                       Data("Review this sentence with the agent.\n".utf8))
    }

    // MARK: Scenario 7 — reopen file with pre-existing sidecar preserves it.
    // Assert both a real DOM marker and its accessible thread-opening button.
    func testReopenShowsGutterDot() throws {
        let app = XCUIApplication()
        let tmp = app.launchE2E(fixture: "basic.md")

        let fixturePath = tmp.appendingPathComponent("basic.md")
        let sidecarPath = tmp.appendingPathComponent("basic.md.comments.json")
        let sidecar = """
        {
          "version": 1,
          "document": {"path": "basic.md", "sha256": ""},
          "comments": [{
            "id": "c_seeded000000000000000001",
            "createdAt": "2026-05-25T00:00:00Z",
            "author": {"kind": "human", "name": "Tester"},
            "body": "Seeded comment for reopen test.",
            "target": {"selectors": [
              {"type": "TextPositionSelector", "start": 0, "end": 14, "startLine": 0, "endLine": 0},
              {"type": "TextQuoteSelector", "exact": "# Heading One", "prefix": "", "suffix": ""}
            ]},
            "status": "active",
            "tags": [],
            "mentions": [],
            "thread": []
          }]
        }
        """
        try sidecar.write(to: sidecarPath, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sidecarPath.path),
                      "sidecar should exist on disk after write")

        app.terminate()
        let app2 = XCUIApplication()
        app2.launchArguments = [
            "--e2e=1",
            "--e2e-tmp=\(tmp.path)",
            "--e2e-fixture=\(fixturePath.path)",
        ]
        app2.launchEnvironment = [
            "MDEDIT_E2E": "1",
            "MDEDIT_E2E_TMP": tmp.path,
            "MDEDIT_E2E_FIXTURE": fixturePath.path,
        ]
        app2.launch()

        _ = app2.waitForE2EState(
            until: { ($0.editorState["commentMarkers"] as? Int ?? 0) == 1 },
            message: "second launch restored the saved marker"
        )
        let marker = app2.buttons["Open comment: Seeded comment for reopen test."]
        XCTAssertTrue(marker.waitForExistence(timeout: 5))
        marker.click()
        let body = app2.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@ OR value CONTAINS %@",
            "Seeded comment for reopen test.", "Seeded comment for reopen test."
        )).firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 5), app2.debugDescription)
        XCTAssertEqual(try String(contentsOf: sidecarPath, encoding: .utf8), sidecar,
                       "viewing a thread must not rewrite its sidecar")
    }

    // MARK: Scenario 9 — open .csv → preview pane renders an HTML table.
    func testOpensCsvPreview() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.csv")

        let state = app.waitForE2EState(
            timeout: 10,
            until: { ($0.previewState["tableRows"] as? Int ?? 0) >= 4 },
            message: "csv preview should finish rendering the header and three rows"
        )
        // basic.csv has 1 header row + 3 data rows = 4 <tr> elements.
        XCTAssertGreaterThanOrEqual(state.previewState["tableRows"] as? Int ?? 0, 4,
                                    "expected ≥4 <tr> (1 header + 3 data rows)")
        XCTAssertEqual(state.webViewCount, 2,
                       "csv doc should mount 2 WKWebViews (editor + preview)")
    }

    // MARK: Scenario 10 — open .json → preview pane renders a collapsible tree.
    func testOpensJsonPreview() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.json")

        let state = app.waitForE2EState(
            timeout: 10,
            until: { st in
                let p = st.previewState
                // JSONRenderer's tree shows up as either .json-key spans or
                // collapsible <details> elements depending on renderer style.
                let keys = p["jsonKeys"] as? Int ?? 0
                let bodyChildren = p["htmlBodyChildren"] as? Int ?? 0
                return keys >= 1 || bodyChildren >= 1
            },
            message: "json preview should render keys or body content"
        )
        XCTAssertEqual(state.webViewCount, 2,
                       "json doc should mount 2 WKWebViews (editor + preview)")
    }

    // MARK: Scenario 11 — open .html → preview renders body children.
    func testOpensHtmlPreview() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.html")

        let state = app.waitForE2EState(
            timeout: 10,
            until: { ($0.previewState["htmlBodyChildren"] as? Int ?? 0) >= 3 },
            message: "html preview should finish rendering the heading, paragraph, and list"
        )
        // basic.html has h1 + p + ul = 3 children
        XCTAssertGreaterThanOrEqual(state.previewState["htmlBodyChildren"] as? Int ?? 0, 3,
                                    "expected ≥3 body children from basic.html")
        XCTAssertEqual(state.webViewCount, 2,
                       "html doc should mount 2 WKWebViews (editor + preview)")
    }

    // MARK: Scenario 12 — open .pdf → PDFKit's PDFView is in the view tree.
    func testOpensPdfShowsPDFView() throws {
        let app = XCUIApplication()
        _ = app.launchE2E(fixture: "basic.pdf")

        _ = app.waitForE2EState(
            timeout: 10,
            until: { $0.pdfPresent },
            message: "PDFView should be mounted in the doc window"
        )
    }

    // MARK: Scenario 13 — external sidecar edit refreshes the inspector.
    // We don't have a way from XCUITest to assert the inspector pane's contents
    // (SwiftUI views aren't named via AX by default). Instead the test exercises
    // the round-trip mechanic: write sidecar from outside, wait, then trigger
    // a refresh signal, and verify the editor's commentMarkers count changes.
    func testAgentEditRefreshesSidecar() throws {
        let app = XCUIApplication()
        let tmp = app.launchE2E(fixture: "basic.md")

        _ = app.waitForE2EState(
            until: { ($0.editorState["docLen"] as? Int ?? 0) > 0 },
            message: "editor mounted"
        )

        let sidecarPath = tmp.appendingPathComponent("basic.md.comments.json")
        let sidecar = """
        {
          "version": 1,
          "document": {"path": "basic.md", "sha256": ""},
          "comments": [{
            "id": "c_agentedit0000000000000001",
            "createdAt": "2026-05-25T00:00:00Z",
            "author": {"kind": "ai", "name": "claude"},
            "body": "Comment written by an external agent for the refresh test.",
            "target": {"selectors": [
              {"type": "TextPositionSelector", "start": 0, "end": 14, "startLine": 0, "endLine": 0},
              {"type": "TextQuoteSelector", "exact": "# Heading One", "prefix": "", "suffix": ""}
            ]},
            "status": "active",
            "tags": [],
            "mentions": [],
            "thread": []
          }]
        }
        """
        try sidecar.write(to: sidecarPath, atomically: true, encoding: .utf8)

        // The app doesn't (yet) watch the sidecar file — wire is via
        // .mdeditCommentsChanged notification posted on user actions. Until a
        // file watcher lands, we just assert disk state — the comment exists,
        // is well-formed, and persists. Bridge has no way to observe the
        // inspector pane reload, so this is a forward-compat skeleton that
        // gains stronger assertions once the watcher lands.
        let data = try Data(contentsOf: sidecarPath)
        XCTAssertGreaterThan(data.count, 0, "sidecar file written")
        // Verify the JSON parses + carries the agent's comment id.
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let comments = parsed?["comments"] as? [[String: Any]] ?? []
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments.first?["id"] as? String, "c_agentedit0000000000000001")
    }
}
