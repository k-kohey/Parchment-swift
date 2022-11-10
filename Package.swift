// swift-tools-version:5.7
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
        // TODO: versioning
        .package(url: "https://github.com/realm/SwiftLint", branch: "main"),
    ],
    targets: [
        .target(
            name: "Parchment",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .target(
            name: "ParchmentDefault",
            dependencies: [.target(name: "Parchment")],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
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
