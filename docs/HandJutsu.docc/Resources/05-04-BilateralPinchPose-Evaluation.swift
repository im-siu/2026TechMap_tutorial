enum PoseEvaluationStatus: String, Codable, Sendable {
    case matched
    case notMatched
    case notEvaluable
}

struct BilateralPinchEvaluation {
    let status: PoseEvaluationStatus
    let leftNormalizedPinchDistance: Float?
    let rightNormalizedPinchDistance: Float?
}

extension BilateralPinchPose {
    static let normalizedPinchThreshold: Float = 0.35

    static func evaluate(
        left: HandPoseFeature,
        right: HandPoseFeature
    ) -> BilateralPinchEvaluation {
        guard
            let leftDistance = left.normalizedPinchDistance,
            let rightDistance = right.normalizedPinchDistance
        else {
            return BilateralPinchEvaluation(
                status: .notEvaluable,
                leftNormalizedPinchDistance: left.normalizedPinchDistance,
                rightNormalizedPinchDistance: right.normalizedPinchDistance
            )
        }

        return BilateralPinchEvaluation(
            status: leftDistance <= normalizedPinchThreshold && rightDistance <= normalizedPinchThreshold
                ? .matched
                : .notMatched,
            leftNormalizedPinchDistance: leftDistance,
            rightNormalizedPinchDistance: rightDistance
        )
    }
}
