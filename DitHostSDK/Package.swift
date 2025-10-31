// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DitHostSDK",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .watchOS(.v10),
    .tvOS(.v17),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "DitHostSDK",
      targets: ["DitHostSDK"]
    ),
    .library(name: "DitHostSDK-AWSProvider", targets: ["DitHostSDK-AWSProvider"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ajevans99/swift-json-schema.git", from: "0.9.1"),
    .package(
      url: "https://github.com/awslabs/aws-sdk-swift",
      from: "1.0.0"
    ),
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0"),
    .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3"),
    .package(url: "https://github.com/davbeck/swift-glob.git", from: "0.1.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DitHostSDK",
      dependencies: [
        .product(name: "JSONSchema", package: "swift-json-schema"),
        .product(name: "JSONSchemaBuilder", package: "swift-json-schema"),
        .product(name: "Yams", package: "Yams"),
      ]
    ),
    .target(
      name: "DitHostSDK-AWSProvider",
      dependencies: [
        "DitHostSDK",
        .product(name: "JSONSchema", package: "swift-json-schema"),
        .product(name: "JSONSchemaBuilder", package: "swift-json-schema"),
        .product(name: "AWSEC2", package: "aws-sdk-swift"),
        .product(name: "AWSSTS", package: "aws-sdk-swift"),
        .product(name: "Glob", package: "swift-glob"),
      ]
    ),
    Target
      .testTarget(
        name: "DitHostSDKTests",
        dependencies: ["DitHostSDK"]
      ),
  ]
)
