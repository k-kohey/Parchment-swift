// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(
            name: "Parchment",
            targets: ["Parchment"]
        ),
        .library(
            name: "ParchmentDefault",
            targets: ["ParchmentDefault"]
        ),
    ],
    dependencies: [
        // The following PRs will be merged into the main branch and replaced with t and the official
        // https://github.com/realm/SwiftLint/pull/4176
        .package(url: "https://github.com/usami-k/SwiftLintPlugin", branch: "main"),
    ],
    targets: [
        .target(
            name: "Parchment",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLintPlugin"),
            ]
        ),
        .target(
            name: "ParchmentDefault",
            dependencies: [.target(name: "Parchment")],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLintPlugin"),
            ]
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment"]
        ),
        .testTarget(
            name: "ParchmentDefaultTests",
            dependencies: ["ParchmentDefault"]
        ),
    ]
)
