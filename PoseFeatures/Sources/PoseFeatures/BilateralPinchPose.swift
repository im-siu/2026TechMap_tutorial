import Foundation

public enum BilateralPinchPose {
    public static let requiredJoints: Set<HandJoint> = [
        .wrist,
        .thumbTip,
        .indexFingerTip,
        .middleFingerKnuckle
    ]

    public static let auxiliaryJoints: Set<HandJoint> = [
        .thumbKnuckle,
        .indexFingerKnuckle,
        .forearmWrist
    ]

    public static let normalizedPinchThreshold: Float = 0.35

    public static func makeFeature(from input: HandPoseInput) -> HandPoseFeature {
        let targetJoints = requiredJoints.union(auxiliaryJoints)
        let missingJoints = targetJoints
            .filter { input.jointPositions[$0] == nil }
            .sorted { $0.rawValue < $1.rawValue }
        let availableJointCount = targetJoints.count - missingJoints.count
        let jointCoverageRatio = Float(availableJointCount) / Float(targetJoints.count)
        let missingRequiredJoints = requiredJoints.filter { input.jointPositions[$0] == nil }

        guard
            missingRequiredJoints.isEmpty,
            let wrist = input.jointPositions[.wrist],
            let thumbTip = input.jointPositions[.thumbTip],
            let indexFingerTip = input.jointPositions[.indexFingerTip],
            let middleFingerKnuckle = input.jointPositions[.middleFingerKnuckle]
        else {
            return HandPoseFeature(
                side: input.side,
                availability: .unavailable,
                relativeJointPositions: [:],
                handScale: nil,
                normalizedPinchDistance: nil,
                availableFeatures: [],
                missingFeatures: [.wristRelativePositions, .handScale, .normalizedPinchDistance, .orientationHints],
                missingJoints: missingJoints,
                jointCoverageRatio: jointCoverageRatio
            )
        }

        let handScale = distance(from: wrist, to: middleFingerKnuckle)

        guard handScale > .ulpOfOne else {
            return HandPoseFeature(
                side: input.side,
                availability: .unavailable,
                relativeJointPositions: [:],
                handScale: nil,
                normalizedPinchDistance: nil,
                availableFeatures: [],
                missingFeatures: [.handScale, .normalizedPinchDistance, .orientationHints],
                missingJoints: missingJoints,
                jointCoverageRatio: jointCoverageRatio
            )
        }

        let relativeJointPositions = Dictionary(
            uniqueKeysWithValues: input.jointPositions.map { joint, position in
                (joint, position - wrist)
            }
        )
        let normalizedPinchDistance = distance(from: thumbTip, to: indexFingerTip) / handScale
        let hasOrientationHints = auxiliaryJoints.isSubset(of: Set(input.jointPositions.keys))

        return HandPoseFeature(
            side: input.side,
            availability: hasOrientationHints ? .complete : .partial,
            relativeJointPositions: relativeJointPositions,
            handScale: handScale,
            normalizedPinchDistance: normalizedPinchDistance,
            availableFeatures: hasOrientationHints
                ? [.wristRelativePositions, .handScale, .normalizedPinchDistance, .orientationHints]
                : [.wristRelativePositions, .handScale, .normalizedPinchDistance],
            missingFeatures: hasOrientationHints ? [] : [.orientationHints],
            missingJoints: missingJoints,
            jointCoverageRatio: jointCoverageRatio
        )
    }

    public static func evaluate(
        left: HandPoseFeature,
        right: HandPoseFeature,
        threshold: Float = normalizedPinchThreshold
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

        let status: PoseEvaluationStatus = leftDistance <= threshold && rightDistance <= threshold
            ? .matched
            : .notMatched

        return BilateralPinchEvaluation(
            status: status,
            leftNormalizedPinchDistance: leftDistance,
            rightNormalizedPinchDistance: rightDistance
        )
    }

    private static func distance(from first: SIMD3<Float>, to second: SIMD3<Float>) -> Float {
        let delta = first - second
        return (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z).squareRoot()
    }
}
