// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EventGen",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "eventgen", targets: ["eventgen"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-markdown", revision: "87ae1a8fa9180b85630c7b41ddd5aa40ffc87ce3"),
        .package(name: "Parchment", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "eventgen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "EventGenKit"
            ]
        ),
        .target(
            name: "EventGenKit",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Parchment", package: "Parchment")
            ]
        ),
        .testTarget(
            name: "EventGenKitTests",
            dependencies: [
                "EventGenKit"
            ]
        ),
    ]
)
