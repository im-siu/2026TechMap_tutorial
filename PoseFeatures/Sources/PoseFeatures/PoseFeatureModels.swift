import Foundation

public enum HandSide: String, CaseIterable, Codable, Sendable {
    case left
    case right
}

public enum HandJoint: String, CaseIterable, Codable, Sendable {
    case wrist
    case thumbTip
    case thumbKnuckle
    case indexFingerKnuckle
    case indexFingerIntermediateBase
    case indexFingerIntermediateTip
    case indexFingerTip
    case middleFingerKnuckle
    case middleFingerIntermediateBase
    case middleFingerIntermediateTip
    case middleFingerTip
    case ringFingerKnuckle
    case ringFingerTip
    case littleFingerKnuckle
    case littleFingerTip
    case forearmWrist
}

public enum PoseFeatureAvailability: String, Codable, Sendable {
    case complete
    case partial
    case unavailable
}

public enum PoseFeatureName: String, CaseIterable, Codable, Sendable {
    case wristRelativePositions
    case handScale
    case normalizedPinchDistance
    case orientationHints
}

public enum PoseEvaluationStatus: String, Codable, Sendable {
    case matched
    case notMatched
    case notEvaluable
    case candidate
}

public enum TargetPose: String, Codable, Sendable {
    case bilateralPinch
    case interlockedTwoFingerSeal
}

public struct HandPoseInput: Sendable {
    public let side: HandSide
    public let jointPositions: [HandJoint: SIMD3<Float>]

    public init(side: HandSide, jointPositions: [HandJoint: SIMD3<Float>]) {
        self.side = side
        self.jointPositions = jointPositions
    }
}

public struct TrackedJointPosition: Sendable {
    public let joint: HandJoint
    public let worldPosition: SIMD3<Float>

    public init(joint: HandJoint, worldPosition: SIMD3<Float>) {
        self.joint = joint
        self.worldPosition = worldPosition
    }
}

public struct HandPoseFeature: Sendable {
    public let side: HandSide
    public let availability: PoseFeatureAvailability
    public let relativeJointPositions: [HandJoint: SIMD3<Float>]
    public let handScale: Float?
    public let normalizedPinchDistance: Float?
    public let availableFeatures: [PoseFeatureName]
    public let missingFeatures: [PoseFeatureName]
    public let missingJoints: [HandJoint]
    public let jointCoverageRatio: Float

    public var isEvaluable: Bool {
        normalizedPinchDistance != nil
    }
}

public struct BilateralPinchEvaluation: Sendable {
    public let status: PoseEvaluationStatus
    public let leftNormalizedPinchDistance: Float?
    public let rightNormalizedPinchDistance: Float?

    public init(
        status: PoseEvaluationStatus,
        leftNormalizedPinchDistance: Float?,
        rightNormalizedPinchDistance: Float?
    ) {
        self.status = status
        self.leftNormalizedPinchDistance = leftNormalizedPinchDistance
        self.rightNormalizedPinchDistance = rightNormalizedPinchDistance
    }
}
