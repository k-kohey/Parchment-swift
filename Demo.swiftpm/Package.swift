// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Demo",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .iOSApplication(
            name: "Demo",
            targets: ["AppModule"],
            bundleIdentifier: "com.k-kohey.demo",
            teamIdentifier: "xxxxxxxxxx",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(name: "Parchment", path: "../"),
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Parchment", package: "Parchment"),
            ]
        )
    ]
)

