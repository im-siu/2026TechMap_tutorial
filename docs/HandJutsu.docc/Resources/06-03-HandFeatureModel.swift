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
