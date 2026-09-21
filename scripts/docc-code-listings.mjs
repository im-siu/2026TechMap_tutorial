export const codeListings = [
  { listingPath: "docs/HandJutsu.docc/Resources/05-01-PoseFeatureModels.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/PoseFeatureModels.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/05-02-BilateralPinchPose.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/BilateralPinchPose.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/05-03-BilateralPinchPose-Feature.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/BilateralPinchPose+Feature.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/05-04-BilateralPinchPose-Evaluation.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/BilateralPinchPose+Evaluation.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/05-05-HandTrackingPoseFeatureAdapter.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/HandTrackingPoseFeatureAdapter.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/05-06-PoseFeatureVerificationRecord.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/PoseFeatureVerificationRecord.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/05-07-BilateralPinchPoseTests.swift", sourcePath: "PoseFeatures/Tests/PoseFeaturesTests/BilateralPinchPoseTests.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/06-01-SealRequirements.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal.swift", ranges: [[1, 29]] },
  { listingPath: "docs/HandJutsu.docc/Resources/06-02-SealFingerChains.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/06-03-HandFeatureModel.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal+Feature.swift", ranges: [[1, 27]] },
  { listingPath: "docs/HandJutsu.docc/Resources/06-04-HandFeatureAvailability.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal+Feature.swift", ranges: [[1, 28], [29, 51], [82, 85], [92, 123], [163, 163]] },
  { listingPath: "docs/HandJutsu.docc/Resources/06-05-HandFeatureMetrics.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal+Feature.swift", ranges: [[1, 28], [29, 85], [92, 123], [163, 163]] },
  { listingPath: "docs/HandJutsu.docc/Resources/06-06-FingerScore.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal+Feature.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/06-07-SealEvaluationInput.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal+Evaluation.swift", ranges: [[1, 41], [78, 79]] },
  { listingPath: "docs/HandJutsu.docc/Resources/06-08-SealEvaluationRules.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/InterlockedTwoFingerSeal+Evaluation.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/06-09-SealEvaluationTests.swift", sourcePath: "PoseFeatures/Tests/PoseFeaturesTests/InterlockedTwoFingerSealTests.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/07-01-GestureClassifierModels.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/GestureClassifierModels.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/07-02-GestureClassifier-CandidateStart.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/GestureClassifier.swift", ranges: [[1, 7], [12, 32], [71, 80], [202, 212]] },
  { listingPath: "docs/HandJutsu.docc/Resources/07-03-GestureClassifier-CandidateHold.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/GestureClassifier.swift", ranges: [[1, 7], [12, 40], [46, 46], [71, 80], [167, 170], [202, 212]] },
  { listingPath: "docs/HandJutsu.docc/Resources/07-04-GestureClassifier-Loss.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/GestureClassifier.swift", ranges: [[1, 10], [12, 62], [71, 175], [202, 212]] },
  { listingPath: "docs/HandJutsu.docc/Resources/07-05-GestureClassifier-Cooldown.swift", sourcePath: "PoseFeatures/Sources/PoseFeatures/GestureClassifier.swift" },
  { listingPath: "docs/HandJutsu.docc/Resources/07-06-GestureClassifierTests.swift", sourcePath: "PoseFeatures/Tests/PoseFeaturesTests/GestureClassifierTests.swift" },
];

export function sourceListing(source, ranges) {
  if (!ranges) {
    return source;
  }

  const lines = source.split("\n");
  return `${ranges
    .map(([start, end]) => lines.slice(start - 1, end).join("\n"))
    .join("\n")}\n`;
}
