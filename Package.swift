// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoScreenCast",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PoScreenCast",
            targets: ["PoScreenCast"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.6.1"),
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PoScreenCast",
        dependencies: [
            .product(name: "AEXML", package: "AEXML"),
            .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
        ]),
        .testTarget(
            name: "PoScreenCastTests",
            dependencies: ["PoScreenCast"]),
    ]
)
