// swift-tools-version: 5.10
// preview-md-shared — rendering engine extracted from PreviewMD,
// consumed by both preview-md (Quick Look extension) and md-editor (the app).
// See ../md-editor/VISION.md "V1.0 Story 0" for extraction acceptance criteria.

import PackageDescription

let package = Package(
    name: "preview-md-shared",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PreviewMDShared",
            targets: ["PreviewMDShared"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "PreviewMDShared",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/Shared"
            // Resources (mermaid.min.js, katex.min.js, katex.min.css, katex-auto-render.min.js)
            // are a Story 0a follow-on — see HTMLTemplate.swift comment.
            // To add: drop files into Sources/Shared/Resources/ and declare:
            //   resources: [.copy("Resources/mermaid.min.js"), .copy("Resources/katex.min.js"), ...]
        ),
        .testTarget(
            name: "PreviewMDSharedTests",
            dependencies: ["PreviewMDShared"],
            path: "Tests/SharedTests"
        ),
    ]
)
