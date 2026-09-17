import PoseFeatures

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

    static let normalizedPinchThreshold: Float = 0.35
}
