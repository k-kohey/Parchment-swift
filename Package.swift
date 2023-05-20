// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [.iOS(.v14), .macOS(.v11)],
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
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1")
    ],
    targets: [
        .target(
            name: "Parchment",
            swiftSettings: [
                .unsafeFlags([
                    "-strict-concurrency=complete"
                ])
            ]
        ),
        .target(
            name: "ParchmentDefault",
            dependencies: [
                .target(name: "Parchment"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-strict-concurrency=complete"
                ])
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
