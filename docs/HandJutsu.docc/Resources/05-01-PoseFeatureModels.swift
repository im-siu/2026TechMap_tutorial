enum HandSide: String, CaseIterable, Codable, Sendable {
    case left
    case right
}

enum HandJoint: String, CaseIterable, Codable, Sendable {
    case wrist
    case thumbTip
    case indexFingerTip
    case middleFingerKnuckle
    case thumbKnuckle
    case indexFingerKnuckle
    case forearmWrist
}

enum PoseFeatureAvailability: String, Codable, Sendable {
    case complete
    case partial
    case unavailable
}

enum PoseFeatureName: String, CaseIterable, Codable, Sendable {
    case wristRelativePositions
    case handScale
    case normalizedPinchDistance
    case orientationHints
}

struct HandPoseInput: Sendable {
    let side: HandSide
    let jointPositions: [HandJoint: SIMD3<Float>]
}

struct HandPoseFeature: Sendable {
    let side: HandSide
    let availability: PoseFeatureAvailability
    let relativeJointPositions: [HandJoint: SIMD3<Float>]
    let handScale: Float?
    let normalizedPinchDistance: Float?
    let availableFeatures: [PoseFeatureName]
    let missingFeatures: [PoseFeatureName]
    let missingJoints: [HandJoint]
    let jointCoverageRatio: Float
}
