import Foundation

public struct InterlockedTwoFingerSealEvaluation: Sendable {
    public let status: PoseEvaluationStatus
    public let leftFingerAlignmentScore: Float?
    public let rightFingerAlignmentScore: Float?
    public let normalizedInterlockDistance: Float?
}

public extension InterlockedTwoFingerSeal {
    static func evaluate(
        left: InterlockedTwoFingerSealHandFeature,
        right: InterlockedTwoFingerSealHandFeature,
        minimumExtensionScore: Float = minimumExtensionScore,
        minimumFingerLengthRatio: Float = minimumFingerLengthRatio,
        minimumFingerAlignmentScore: Float = minimumFingerAlignmentScore,
        maximumInterlockDistanceRatio: Float = maximumInterlockDistanceRatio
    ) -> InterlockedTwoFingerSealEvaluation {
        guard left.side == .left, right.side == .right,
              left.isEvaluable, right.isEvaluable,
              let leftWrist = left.wristPosition,
              let rightWrist = right.wristPosition,
              let leftScale = left.handScale,
              let rightScale = right.handScale,
              let leftIndexExtension = left.indexExtensionScore,
              let leftMiddleExtension = left.middleExtensionScore,
              let rightIndexExtension = right.indexExtensionScore,
              let rightMiddleExtension = right.middleExtensionScore,
              let leftIndexLength = left.normalizedIndexLength,
              let leftMiddleLength = left.normalizedMiddleLength,
              let rightIndexLength = right.normalizedIndexLength,
              let rightMiddleLength = right.normalizedMiddleLength,
              let leftAlignment = left.fingerAlignmentScore,
              let rightAlignment = right.fingerAlignmentScore else {
            return InterlockedTwoFingerSealEvaluation(
                status: .notEvaluable,
                leftFingerAlignmentScore: left.fingerAlignmentScore,
                rightFingerAlignmentScore: right.fingerAlignmentScore,
                normalizedInterlockDistance: nil
            )
        }
    }
}
