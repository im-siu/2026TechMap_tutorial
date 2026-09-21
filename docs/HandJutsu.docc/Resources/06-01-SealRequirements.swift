import Foundation

public enum InterlockedTwoFingerSeal {
    public static let requiredJoints: Set<HandJoint> = [
        .wrist,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .indexFingerTip,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip
    ]

    public static let optionalJoints: Set<HandJoint> = [
        .thumbKnuckle,
        .thumbTip,
        .ringFingerKnuckle,
        .ringFingerTip,
        .littleFingerKnuckle,
        .littleFingerTip
    ]

    public static let minimumExtensionScore: Float = 0.85
    public static let minimumFingerLengthRatio: Float = 0.8
    public static let minimumFingerAlignmentScore: Float = 0.8
    public static let maximumInterlockDistanceRatio: Float = 1.2
}
