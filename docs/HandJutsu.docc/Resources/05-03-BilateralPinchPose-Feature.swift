enum BilateralPinchPose {
    static let requiredJoints: Set<HandJoint> = [
        .wrist,
        .thumbTip,
        .indexFingerTip,
        .middleFingerKnuckle
    ]

    static let auxiliaryJoints: Set<HandJoint> = [
        .thumbKnuckle,
        .indexFingerKnuckle,
        .forearmWrist
    ]

    static func makeFeature(from input: HandPoseInput) -> HandPoseFeature {
        let targetJoints = requiredJoints.union(auxiliaryJoints)
        let missingJoints = targetJoints
            .filter { input.jointPositions[$0] == nil }
            .sorted { $0.rawValue < $1.rawValue }
        let jointCoverageRatio = Float(targetJoints.count - missingJoints.count) / Float(targetJoints.count)
        let missingRequiredJoints = requiredJoints.filter { input.jointPositions[$0] == nil }

        guard
            missingRequiredJoints.isEmpty,
            let wrist = input.jointPositions[.wrist],
            let thumbTip = input.jointPositions[.thumbTip],
            let indexTip = input.jointPositions[.indexFingerTip],
            let middleKnuckle = input.jointPositions[.middleFingerKnuckle]
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

        let handScale = distance(from: wrist, to: middleKnuckle)

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

        let normalizedPinchDistance = distance(from: thumbTip, to: indexTip) / handScale
        let hasOrientationHints = auxiliaryJoints.isSubset(of: Set(input.jointPositions.keys))
        let relativeJointPositions = Dictionary(
            uniqueKeysWithValues: input.jointPositions.map { joint, position in
                (joint, position - wrist)
            }
        )

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

    private static func distance(from first: SIMD3<Float>, to second: SIMD3<Float>) -> Float {
        let delta = first - second
        return (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z).squareRoot()
    }
}
