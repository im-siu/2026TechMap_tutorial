// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PoseFeatures",
    platforms: [
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "PoseFeatures",
            targets: ["PoseFeatures"]
        )
    ],
    targets: [
        .target(name: "PoseFeatures"),
        .testTarget(
            name: "PoseFeaturesTests",
            dependencies: ["PoseFeatures"]
        )
    ]
)
