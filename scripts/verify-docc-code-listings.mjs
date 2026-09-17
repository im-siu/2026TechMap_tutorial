#!/usr/bin/env node

import { readFile } from "node:fs/promises";

const codeListings = new Map([
  ["docs/HandJutsu.docc/Resources/05-01-PoseFeatureModels.swift", "PoseFeatures/Sources/PoseFeatures/PoseFeatureModels.swift"],
  ["docs/HandJutsu.docc/Resources/05-02-BilateralPinchPose.swift", "PoseFeatures/Sources/PoseFeatures/BilateralPinchPose.swift"],
  ["docs/HandJutsu.docc/Resources/05-03-BilateralPinchPose-Feature.swift", "PoseFeatures/Sources/PoseFeatures/BilateralPinchPose+Feature.swift"],
  ["docs/HandJutsu.docc/Resources/05-04-BilateralPinchPose-Evaluation.swift", "PoseFeatures/Sources/PoseFeatures/BilateralPinchPose+Evaluation.swift"],
  ["docs/HandJutsu.docc/Resources/05-05-HandTrackingPoseFeatureAdapter.swift", "PoseFeatures/Sources/PoseFeatures/HandTrackingPoseFeatureAdapter.swift"],
  ["docs/HandJutsu.docc/Resources/05-06-PoseFeatureVerificationRecord.swift", "PoseFeatures/Sources/PoseFeatures/PoseFeatureVerificationRecord.swift"],
  ["docs/HandJutsu.docc/Resources/05-07-BilateralPinchPoseTests.swift", "PoseFeatures/Tests/PoseFeaturesTests/BilateralPinchPoseTests.swift"],
]);

let differences = 0;

for (const [listingPath, sourcePath] of codeListings) {
  const [listing, source] = await Promise.all([
    readFile(listingPath, "utf8"),
    readFile(sourcePath, "utf8"),
  ]);

  if (listing !== source) {
    console.error(`DocC listing differs from source: ${listingPath} != ${sourcePath}`);
    differences += 1;
  }
}

if (differences > 0) {
  process.exit(1);
}

console.log(`Verified ${codeListings.size} DocC code listings against package sources.`);
