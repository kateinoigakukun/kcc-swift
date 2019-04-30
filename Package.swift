// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "kcc",
    products: [
    ],
    dependencies: [
        .package(url: "https://github.com/thoughtbot/Curry.git", from: "4.0.2"),
    ],
    targets: [
        .target(
            name: "CodeGen",
            dependencies: ["Parser"]),
        .target(
            name: "Parser",
            dependencies: ["Curry"]),
        .testTarget(
            name: "CodeGenTests",
            dependencies: ["CodeGen"]),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"]),
    ]
)
