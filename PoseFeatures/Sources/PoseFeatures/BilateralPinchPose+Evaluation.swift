import Foundation

public extension BilateralPinchPose {
    static func evaluate(
        left: HandPoseFeature,
        right: HandPoseFeature,
        threshold: Float = normalizedPinchThreshold
    ) -> BilateralPinchEvaluation {
        guard left.side == .left, right.side == .right else {
            return BilateralPinchEvaluation(
                status: .notEvaluable,
                leftNormalizedPinchDistance: left.normalizedPinchDistance,
                rightNormalizedPinchDistance: right.normalizedPinchDistance
            )
        }

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

        let status: PoseEvaluationStatus = leftDistance <= threshold && rightDistance <= threshold
            ? .matched
            : .notMatched

        return BilateralPinchEvaluation(
            status: status,
            leftNormalizedPinchDistance: leftDistance,
            rightNormalizedPinchDistance: rightDistance
        )
    }
}
