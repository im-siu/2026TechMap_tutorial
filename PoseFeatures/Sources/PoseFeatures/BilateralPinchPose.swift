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
}
