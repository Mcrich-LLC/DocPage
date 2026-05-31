// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocPage",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/Zollerboy1/SwiftCommand.git", from: "1.4.2"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "docpage",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SwiftCommand",
                "ZIPFoundation",
            ]
        ),

    ],
    swiftLanguageModes: [.v6]
)
