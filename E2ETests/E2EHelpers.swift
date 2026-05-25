// Shared helpers for the e2e suite.
// All scenarios launch the app with --e2e=1, a fresh temp dir, and an explicit
// fixture so they're hermetic (no clobbering of the user's real ~/Repoes).

import XCTest

extension XCUIApplication {
    /// Configure & launch the app in e2e mode pointed at a fixture file.
    /// Returns the temp dir used for sidecars so the test can assert on disk.
    @discardableResult
    func launchE2E(fixture fixtureName: String,
                   line: UInt = #line, file: StaticString = #file) -> URL {
        let tmp = makeTempDir(line: line, file: file)
        let fixtureURL = stagedFixture(name: fixtureName, into: tmp)
        launchArguments = [
            "--e2e=1",
            "--e2e-tmp=\(tmp.path)",
            "--e2e-fixture=\(fixtureURL.path)",
        ]
        launchEnvironment = [
            "MDEDIT_E2E": "1",
            "MDEDIT_E2E_TMP": tmp.path,
            "MDEDIT_E2E_FIXTURE": fixtureURL.path,
        ]
        launch()
        return tmp
    }

    /// Pull the JSON state the E2EBridge polls into the AX field, decoded.
    func readE2EState(timeout: TimeInterval = 5,
                      line: UInt = #line, file: StaticString = #file) -> [String: Any] {
        // The field is a child of the status-bar item.
        let predicate = NSPredicate(format: "identifier == 'e2e-state'")
        let element = staticTexts.containing(predicate).firstMatch
        if !element.waitForExistence(timeout: timeout) {
            XCTFail("e2e-state AX field never appeared (E2EBridge not attached?)",
                    file: file, line: line)
            return [:]
        }
        let raw = (element.value as? String) ?? "{}"
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            XCTFail("e2e-state field returned invalid JSON: \(raw)",
                    file: file, line: line)
            return [:]
        }
        return obj
    }

    /// Wait until the JSON state satisfies `predicate` or fail.
    func waitForE2EState(timeout: TimeInterval = 6,
                        until predicate: ([String: Any]) -> Bool,
                        message: String,
                        line: UInt = #line, file: StaticString = #file) -> [String: Any] {
        let deadline = Date().addingTimeInterval(timeout)
        var last: [String: Any] = [:]
        while Date() < deadline {
            last = readE2EState(timeout: 1, line: line, file: file)
            if predicate(last) { return last }
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTFail("Timed out waiting for E2E state: \(message). Last state: \(last)",
                file: file, line: line)
        return last
    }
}

private func makeTempDir(line: UInt, file: StaticString) -> URL {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("mdedit-e2e-\(UUID().uuidString)", isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    } catch {
        XCTFail("Could not create e2e temp dir: \(error)", file: file, line: line)
    }
    return dir
}

private func stagedFixture(name: String, into dir: URL) -> URL {
    // Fixtures bundled with the test target are at Bundle(for: <test>).resourceURL
    // — but XCTest doesn't auto-bundle arbitrary files, so we use the source path.
    let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let src = here.appendingPathComponent("Fixtures").appendingPathComponent(name)
    let dst = dir.appendingPathComponent(name)
    do {
        if FileManager.default.fileExists(atPath: dst.path) {
            try FileManager.default.removeItem(at: dst)
        }
        try FileManager.default.copyItem(at: src, to: dst)
    } catch {
        XCTFail("Could not stage fixture \(name): \(error)")
    }
    return dst
}
