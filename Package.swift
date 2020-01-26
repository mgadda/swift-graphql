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
            targets: ["SwiftGraphQl"]),
    ],
    dependencies: [
      .package(url: "https://github.com/mgadda/swift-parse", .branch("0.4.0"))
      // Uncomment for local development
//      .package(url: "../swift-parse", .branch("0.4.0"))
    ],
    targets: [
        .target(
            name: "GraphQlCLI",
            dependencies: ["SwiftGraphQl"]
        ),
        .target(
            name: "SwiftGraphQl",
            dependencies: ["SwiftParse"]),
        .testTarget(
            name: "SwiftGraphQlTests",
            dependencies: ["SwiftGraphQl"]),
    ]
)
