// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "rindent",
    products: [
        .library(name: "rindent", targets: ["rindent"])
    ],
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.3.2")
    ],
    targets: [
        .target(name: "rindent", dependencies: ["SwiftCLI"])
    ]
)
