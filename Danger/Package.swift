// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Danger",
    products: [
        .library(
            name: "DangerDeps",
            type: .dynamic,
            targets: ["DangerDependencies"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/danger/swift.git", from: "3.14.2"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.49.1")
    ],
    targets: [
        .target(
            name: "DangerDependencies",
            dependencies: [
                .product(name: "Danger", package: "swift")
            ]
        )
    ]
)
