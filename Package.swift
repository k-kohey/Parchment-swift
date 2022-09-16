// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(
            name: "Parchment",
            targets: ["Parchment"]),
        .library(
            name: "ParchmentDefault",
            targets: ["ParchmentDefault"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/technocidal/SwiftLint",
            branch: "technocidal/swift-package-build-tool-plugin"
        )
    ],
    targets: [
        .target(
            name: "Parchment",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLintPlugin")
            ]
        ),
        .target(
            name: "ParchmentDefault",
            dependencies: [.target(name: "Parchment")],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLintPlugin")
            ]
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment"]),
        .testTarget(
            name: "ParchmentDefaultTests",
            dependencies: ["ParchmentDefault"])
    ]
)
