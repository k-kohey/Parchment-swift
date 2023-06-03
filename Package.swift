// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parchment",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(
            name: "ParchmentCore",
            targets: ["ParchmentCore"]
        ),
        .library(
            name: "Parchment",
            targets: ["Parchment"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1")
    ],
    targets: [
        .target(
            name: "ParchmentCore",
            swiftSettings: [
                .unsafeFlags([
                    "-strict-concurrency=complete"
                ])
            ]
        ),
        .target(
            name: "Parchment",
            dependencies: [
                .target(name: "ParchmentCore"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-strict-concurrency=complete"
                ])
            ]
        ),
        .testTarget(
            name: "ParchmentCoreTests",
            dependencies: ["ParchmentCore", "TestSupport"]
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment", "TestSupport"]
        ),
        .target(
            name: "TestSupport",
            dependencies: ["ParchmentCore"]
        ),
    ]
)
