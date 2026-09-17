import ARKit
import PoseFeatures

enum HandTrackingSnapshotAdapter {
    static func input(
        for side: PoseFeatures.HandSide,
        from hand: HandTrackingSnapshot.HandState
    ) -> HandPoseInput {
        let samples = hand.joints.compactMap { sample in
                guard let joint = HandJoint(sample.name) else {
                    return nil
                }

                let translation = sample.originFromJointTransform.columns.3
                return TrackedJointPosition(
                    joint: joint,
                    worldPosition: SIMD3(translation.x, translation.y, translation.z)
                )
            }

        return PoseFeatures.HandTrackingPoseFeatureAdapter.makeInput(side: side, samples: samples)
    }
}

private extension HandJoint {
    init?(_ jointName: HandSkeleton.JointName) {
        switch jointName {
        case .wrist: self = .wrist
        case .thumbTip: self = .thumbTip
        case .indexFingerTip: self = .indexFingerTip
        case .middleFingerKnuckle: self = .middleFingerKnuckle
        case .thumbKnuckle: self = .thumbKnuckle
        case .indexFingerKnuckle: self = .indexFingerKnuckle
        case .forearmWrist: self = .forearmWrist
        default: return nil
        }
    }
}
