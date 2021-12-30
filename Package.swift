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
            targets: ["ParchmentDefault"]),
    ],
    targets: [
        .target(
            name: "Parchment",
            dependencies: []),
        .target(
            name: "ParchmentDefault",
            dependencies: [.target(name: "Parchment")]
        ),
        .testTarget(
            name: "ParchmentTests",
            dependencies: ["Parchment"]),
        .testTarget(
            name: "ParchmentDefaultTests",
            dependencies: ["ParchmentDefault"]),
    ]
)
