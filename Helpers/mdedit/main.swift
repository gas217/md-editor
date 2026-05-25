// mdedit CLI helper — non-sandboxed, ships at MDEditor.app/Contents/Helpers/mdedit.
// See docs/cli.md for the full command surface.
//
// Subcommands handled in-process (stdin/stdout natively, no sandbox proxy):
//   mdedit comments <file> --unresolved --addressable
//   mdedit comments <file> --resolve <id> --reply <text>
//   mdedit merge-comments <file>.comments.json
//
// Subcommands that hand off to the GUI:
//   mdedit                 (launch the app)
//   mdedit <file>          (NSWorkspace.open into the GUI)

import Foundation
import AppKit

let version = "0.2.0"

enum ExitCode: Int32 {
    case success = 0
    case badArgs = 1
    case fileNotFound = 2
    case sidecarParseError = 3
    case commentIdNotFound = 4
    case mergeConflictUnresolved = 5
}

func usage() {
    let text = """
    mdedit \(version) — MD Editor CLI helper

    USAGE:
      mdedit                                                  launch the app
      mdedit <file>                                           open file in the app
      mdedit comments <file> --unresolved [--addressable]    list matching comments as JSON
      mdedit comments <file> --resolve <id> --reply <text>   resolve a comment with a reply
      mdedit merge-comments <file>.comments.json             3-way merge resolution
      mdedit --version | --help

    Full docs: docs/cli.md
    """
    FileHandle.standardOutput.write(Data((text + "\n").utf8))
}

func launchApp(with url: URL? = nil) -> Int32 {
    if let url {
        NSWorkspace.shared.open(url)
    } else {
        let cfg = NSWorkspace.OpenConfiguration()
        let appURL = URL(fileURLWithPath: "/Applications/MDEditor.app")
        NSWorkspace.shared.openApplication(at: appURL, configuration: cfg, completionHandler: nil)
    }
    return ExitCode.success.rawValue
}

private func sidecarURL(for documentPath: String) -> URL {
    let docURL = URL(fileURLWithPath: documentPath).standardizedFileURL
    let parent = docURL.deletingLastPathComponent()
    return parent.appendingPathComponent(docURL.lastPathComponent + ".comments.json")
}

private func loadSidecar(at path: String) throws -> CommentSidecar {
    let url = sidecarURL(for: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
        let docURL = URL(fileURLWithPath: path)
        return CommentSidecar(
            version: 1,
            document: .init(path: docURL.lastPathComponent, sha256: ""),
            comments: []
        )
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(CommentSidecar.self, from: data)
}

private func writeSidecar(_ sidecar: CommentSidecar, for documentPath: String) throws {
    let url = sidecarURL(for: documentPath)
    var s = sidecar
    s.comments = s.comments.map(CommentSidecar.deriveStructured)
    s.comments.sort { $0.id < $1.id }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(s)
    try data.write(to: url, options: [.atomic])
}

func commentsCommand(_ args: [String]) -> Int32 {
    guard let file = args.first else {
        FileHandle.standardError.write(Data("error: mdedit comments requires <file>\n".utf8))
        return ExitCode.badArgs.rawValue
    }

    let sidecar: CommentSidecar
    do {
        sidecar = try loadSidecar(at: file)
    } catch {
        FileHandle.standardError.write(Data("error: \(error)\n".utf8))
        return ExitCode.sidecarParseError.rawValue
    }

    let flags = Set(args.dropFirst())

    // --resolve <id> --reply <text>
    if let resolveIdx = args.firstIndex(of: "--resolve"), resolveIdx + 1 < args.count {
        let id = args[resolveIdx + 1]
        let replyText: String
        if let replyIdx = args.firstIndex(of: "--reply"), replyIdx + 1 < args.count {
            replyText = args[replyIdx + 1]
        } else {
            replyText = ""
        }
        var s = sidecar
        guard let idx = s.comments.firstIndex(where: { $0.id == id }) else {
            FileHandle.standardError.write(Data("error: comment id not found: \(id)\n".utf8))
            return ExitCode.commentIdNotFound.rawValue
        }
        let reply = CommentSidecar.Reply(
            author: .init(kind: .ai, name: "claude", model: "claude-opus-4-7"),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            body: replyText
        )
        s.comments[idx].thread.append(reply)
        s.comments[idx].resolved = true
        s.comments[idx].status = .resolved
        do {
            try writeSidecar(s, for: file)
        } catch {
            FileHandle.standardError.write(Data("error: write failed: \(error)\n".utf8))
            return ExitCode.sidecarParseError.rawValue
        }
        return ExitCode.success.rawValue
    }

    // --unresolved [--addressable]
    var filtered = sidecar.comments
    if flags.contains("--unresolved") {
        filtered = filtered.filter { !$0.resolved }
    }
    if flags.contains("--addressable") {
        filtered = filtered.filter { $0.addressable }
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
        let data = try encoder.encode(filtered)
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    } catch {
        FileHandle.standardError.write(Data("error: encode failed: \(error)\n".utf8))
        return ExitCode.sidecarParseError.rawValue
    }
    return ExitCode.success.rawValue
}

func mergeCommentsCommand(_ args: [String]) -> Int32 {
    // V1.0: stub — opens a 3-way picker. Full implementation lands in the V1.0 UI pass.
    FileHandle.standardError.write(Data("mdedit merge-comments: 3-way picker UI not yet implemented — V1.0 work\n".utf8))
    return ExitCode.mergeConflictUnresolved.rawValue
}

// MARK: - argv dispatch

let argv = CommandLine.arguments
let progName = (argv.first as NSString?)?.lastPathComponent ?? "mdedit"

if argv.count == 1 {
    exit(launchApp())
}

switch argv[1] {
case "--help", "-h":
    usage()
    exit(ExitCode.success.rawValue)

case "--version", "-V":
    FileHandle.standardOutput.write(Data("\(progName) \(version)\n".utf8))
    exit(ExitCode.success.rawValue)

case "comments":
    let rest = Array(argv.dropFirst(2))
    exit(commentsCommand(rest))

case "merge-comments":
    let rest = Array(argv.dropFirst(2))
    exit(mergeCommentsCommand(rest))

default:
    let path = argv[1]
    let url = URL(fileURLWithPath: path).standardizedFileURL
    if !FileManager.default.fileExists(atPath: url.path) {
        FileHandle.standardError.write(Data("error: file not found: \(path)\n".utf8))
        exit(ExitCode.fileNotFound.rawValue)
    }
    exit(launchApp(with: url))
}
