// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGraphQl",
    products: [
        .executable(
            name: "graphql-cli",
            targets: ["GraphQlCLI"]),
        .library(
            name: "SwiftGraphQl",
            targets: ["SwiftGraphQl"])
    ],
    dependencies: [
        // Use `swift package config set-mirror` for local development.
        // swift package config set-mirror \
        //   --original-url 'https://github.com/mgadda/swift-parse' \
        //   --mirror-url '../swift-parse'
        .package(
            url: "https://github.com/mgadda/swift-parse",
            .upToNextMinor(from: "0.4.0"))
    ],
    targets: [
        .target(
            name: "GraphQlCLI",
            dependencies: ["SwiftGraphQl"]),
        .target(
            name: "SwiftGraphQl",
            dependencies: ["SwiftParse"]),
        .testTarget(
            name: "SwiftGraphQlTests",
            dependencies: ["SwiftGraphQl"])
    ]
)
