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

        let handScale = distance(from: wrist, to: middleFingerKnuckle)
        guard handScale > .ulpOfOne,
              let indexScore = fingerScore(for: indexFingerChain, in: input.jointPositions),
              let middleScore = fingerScore(for: middleFingerChain, in: input.jointPositions) else {
            return unavailableFeature(
                side: input.side,
                availableJoints: availableJoints,
                missingRequiredJoints: missingRequiredJoints,
                missingOptionalJoints: missingOptionalJoints,
                jointCoverageRatio: jointCoverageRatio
            )
        }

        let alignment = dot(indexScore.direction, middleScore.direction)
        return InterlockedTwoFingerSealHandFeature(
            side: input.side,
            availability: missingOptionalJoints.isEmpty ? .complete : .partial,
            wristPosition: wrist,
            handScale: handScale,
            indexExtensionScore: indexScore.extensionScore,
            middleExtensionScore: middleScore.extensionScore,
            normalizedIndexLength: indexScore.directLength / handScale,
            normalizedMiddleLength: middleScore.directLength / handScale,
            fingerAlignmentScore: alignment,
            availableJoints: availableJoints,
            missingRequiredJoints: missingRequiredJoints,
            missingOptionalJoints: missingOptionalJoints,
            jointCoverageRatio: jointCoverageRatio
        )
    }
}

private extension InterlockedTwoFingerSeal {
    struct FingerScore {
        let extensionScore: Float
        let directLength: Float
        let direction: SIMD3<Float>
    }

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

    static func fingerScore(
        for chain: [HandJoint],
        in positions: [HandJoint: SIMD3<Float>]
    ) -> FingerScore? {
        let joints = chain.compactMap { positions[$0] }
        guard joints.count == chain.count,
              let knuckle = joints.first,
              let tip = joints.last else {
            return nil
        }

        let directVector = tip - knuckle
        let directLength = length(of: directVector)
        guard directLength > .ulpOfOne else { return nil }

        let pathLength = zip(joints, joints.dropFirst())
            .map { length(of: $1 - $0) }
            .reduce(0, +)
        guard pathLength > .ulpOfOne else { return nil }

        return FingerScore(
            extensionScore: directLength / pathLength,
            directLength: directLength,
            direction: directVector / directLength
        )
    }

    static func distance(from first: SIMD3<Float>, to second: SIMD3<Float>) -> Float {
        length(of: first - second)
    }

    static func length(of vector: SIMD3<Float>) -> Float {
        (vector.x * vector.x + vector.y * vector.y + vector.z * vector.z).squareRoot()
    }

    static func dot(_ first: SIMD3<Float>, _ second: SIMD3<Float>) -> Float {
        first.x * second.x + first.y * second.y + first.z * second.z
    }
}
