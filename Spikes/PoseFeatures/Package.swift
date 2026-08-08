// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "PoseFeatures",
  products: [
    .library(name: "PoseFeatures", targets: ["PoseFeatures"])
  ],
  targets: [
    .target(name: "PoseFeatures"),
    .testTarget(
      name: "PoseFeaturesTests",
      dependencies: ["PoseFeatures"]
    ),
  ]
)
