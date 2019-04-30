// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "kcc",
    products: [
        .executable(
            name: "kcc",
            targets: ["kcc"]),
    ],
    dependencies: [
        .package(url: "https://github.com/thoughtbot/Curry.git", from: "4.0.2"),
    ],
    targets: [
        .target(
            name: "kcc",
            dependencies: ["Driver"]),
        .target(
            name: "Driver",
            dependencies: ["CodeGen"]),
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
