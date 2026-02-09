// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AuroraReader",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AuroraReader",
            targets: ["AuroraReader"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AuroraReader",
            dependencies: [],
            path: "AuroraReader"
        ),
        .testTarget(
            name: "AuroraReaderTests",
            dependencies: ["AuroraReader"],
            path: "AuroraReaderTests"
        ),
    ]
)
