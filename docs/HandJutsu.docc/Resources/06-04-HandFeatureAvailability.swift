import Foundation

public struct InterlockedTwoFingerSealHandFeature: Sendable {
    public let side: HandSide
    public let availability: PoseFeatureAvailability
    public let wristPosition: SIMD3<Float>?
    public let handScale: Float?
    public let indexExtensionScore: Float?
    public let middleExtensionScore: Float?
    public let normalizedIndexLength: Float?
    public let normalizedMiddleLength: Float?
    public let fingerAlignmentScore: Float?
    public let availableJoints: [HandJoint]
    public let missingRequiredJoints: [HandJoint]
    public let missingOptionalJoints: [HandJoint]
    public let jointCoverageRatio: Float

    public var isEvaluable: Bool {
        wristPosition != nil &&
            handScale != nil &&
            indexExtensionScore != nil &&
            middleExtensionScore != nil &&
            normalizedIndexLength != nil &&
            normalizedMiddleLength != nil &&
            fingerAlignmentScore != nil
    }
}

public extension InterlockedTwoFingerSeal {
    static func makeFeature(from input: HandPoseInput) -> InterlockedTwoFingerSealHandFeature {
        let targetJoints = requiredJoints.union(optionalJoints)
        let missingRequiredJoints = missingJoints(in: input, from: requiredJoints)
        let missingOptionalJoints = missingJoints(in: input, from: optionalJoints)
        let availableJoints = targetJoints
            .filter { input.jointPositions[$0] != nil }
            .sorted { $0.rawValue < $1.rawValue }
        let jointCoverageRatio = Float(availableJoints.count) / Float(targetJoints.count)

        guard
            missingRequiredJoints.isEmpty,
            let wrist = input.jointPositions[.wrist],
            let middleFingerKnuckle = input.jointPositions[.middleFingerKnuckle]
        else {
            return unavailableFeature(
                side: input.side,
                availableJoints: availableJoints,
                missingRequiredJoints: missingRequiredJoints,
                missingOptionalJoints: missingOptionalJoints,
                jointCoverageRatio: jointCoverageRatio
            )
        }
    }
}

private extension InterlockedTwoFingerSeal {
    static func unavailableFeature(
        side: HandSide,
        availableJoints: [HandJoint],
        missingRequiredJoints: [HandJoint],
        missingOptionalJoints: [HandJoint],
        jointCoverageRatio: Float
    ) -> InterlockedTwoFingerSealHandFeature {
        InterlockedTwoFingerSealHandFeature(
            side: side,
            availability: .unavailable,
            wristPosition: nil,
            handScale: nil,
            indexExtensionScore: nil,
            middleExtensionScore: nil,
            normalizedIndexLength: nil,
            normalizedMiddleLength: nil,
            fingerAlignmentScore: nil,
            availableJoints: availableJoints,
            missingRequiredJoints: missingRequiredJoints,
            missingOptionalJoints: missingOptionalJoints,
            jointCoverageRatio: jointCoverageRatio
        )
    }

    static func missingJoints(
        in input: HandPoseInput,
        from targetJoints: Set<HandJoint>
    ) -> [HandJoint] {
        targetJoints
            .filter { input.jointPositions[$0] == nil }
            .sorted { $0.rawValue < $1.rawValue }
    }
}
