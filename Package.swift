// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LoggerSandbox",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "app", targets: ["LoggerSandbox", "Logger"])
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LoggerSandbox",
            dependencies: [.target(name: "Logger")]
        ),
        .target(
            name: "Logger",
            dependencies: []
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]),
    ]
)

