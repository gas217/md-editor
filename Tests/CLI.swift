// CLITests — V1.0 Story 7 acceptance: agent loop via the mdedit binary.
// Spawns the built CLI as a subprocess against a temp sidecar, asserts
// list → resolve+reply → empty list round-trip.
// Skips if the binary hasn't been built yet (CI builds before testing).

import XCTest

final class CLITests: XCTestCase {
    private static let cliPath: String? = {
        // Locate the built mdedit helper. xcodebuild puts it next to the .app
        // under Products/Debug; the Makefile also copies it into Contents/Helpers.
        let candidates = [
            "build/Build/Products/Debug/mdedit",
            "build/Build/Products/Release/mdedit",
            "build/Build/Products/Debug/MDEditor.app/Contents/Helpers/mdedit",
        ]
        let cwd = FileManager.default.currentDirectoryPath
        for c in candidates {
            let p = cwd + "/" + c
            if FileManager.default.isExecutableFile(atPath: p) { return p }
        }
        // Search upward — xcodebuild test runs in a derived-data path.
        var url = URL(fileURLWithPath: #file).deletingLastPathComponent()
        for _ in 0..<6 {
            for c in candidates {
                let p = url.appendingPathComponent(c).path
                if FileManager.default.isExecutableFile(atPath: p) { return p }
            }
            url = url.deletingLastPathComponent()
        }
        return nil
    }()

    func testVersionFlag() throws {
        try XCTSkipIf(Self.cliPath == nil, "mdedit binary not built; run `make build` first")
        let out = run(Self.cliPath!, args: ["--version"])
        XCTAssertTrue(out.contains("mdedit"), "version output unexpected: \(out)")
    }

    func testHelpFlag() throws {
        try XCTSkipIf(Self.cliPath == nil, "mdedit binary not built")
        let out = run(Self.cliPath!, args: ["--help"])
        XCTAssertTrue(out.contains("USAGE"), "help output unexpected: \(out)")
        XCTAssertTrue(out.contains("comments"))
        XCTAssertTrue(out.contains("--unresolved"))
    }

    func testAgentLoopRoundTrip() throws {
        try XCTSkipIf(Self.cliPath == nil, "mdedit binary not built")
        let tmp = NSTemporaryDirectory() + "mdedit-cli-test-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        let docPath = tmp + "/plan.md"
        let sidecarPath = docPath + ".comments.json"
        try "# Test\nbody\n".write(toFile: docPath, atomically: true, encoding: .utf8)
        let sidecar = """
        {"version":1,"document":{"path":"plan.md","sha256":""},"comments":[
          {"id":"c_test_001","createdAt":"2026-05-24T12:00:00Z","author":{"kind":"human","name":"ag"},
           "body":"@claude please fix","mentions":[{"kind":"agent","name":"claude"}],"tags":[],
           "resolved":false,"addressable":true,"status":"active",
           "target":{"selectors":[{"type":"TextPositionSelector","start":0,"end":1,"startLine":1,"endLine":1}]},
           "thread":[]}
        ]}
        """
        try sidecar.write(toFile: sidecarPath, atomically: true, encoding: .utf8)

        // 1. List unresolved + addressable — should return our comment.
        let list1 = run(Self.cliPath!, args: ["comments", docPath, "--unresolved", "--addressable"])
        XCTAssertTrue(list1.contains("c_test_001"), "list missing comment id: \(list1)")

        // 2. Resolve with a reply.
        let resolveOut = run(Self.cliPath!, args: ["comments", docPath, "--resolve", "c_test_001", "--reply", "fixed in commit abc"])
        XCTAssertFalse(resolveOut.contains("error"), "resolve produced error: \(resolveOut)")

        // 3. List again — should now be empty.
        let list2 = run(Self.cliPath!, args: ["comments", docPath, "--unresolved", "--addressable"])
        XCTAssertFalse(list2.contains("c_test_001"), "comment should be resolved by now: \(list2)")

        // 4. Sidecar should record the reply + resolved=true.
        let updated = try String(contentsOfFile: sidecarPath, encoding: .utf8)
        XCTAssertTrue(updated.contains("\"resolved\" : true") || updated.contains("\"resolved\":true"))
        XCTAssertTrue(updated.contains("fixed in commit abc"))
    }

    // MARK: - Helpers

    private func run(_ cmd: String, args: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: cmd)
        task.arguments = args
        let out = Pipe()
        let err = Pipe()
        task.standardOutput = out
        task.standardError = err
        do {
            try task.run()
            task.waitUntilExit()
            let outStr = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let errStr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return outStr + errStr
        } catch {
            return "RUN ERROR: \(error)"
        }
    }
}
