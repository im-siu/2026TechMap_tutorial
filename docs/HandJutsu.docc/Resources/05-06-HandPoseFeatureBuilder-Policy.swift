import ARKit
import simd

enum HandPoseFeatureBuilder {
    static let originJoint: HandSkeleton.JointName = .wrist

    static let requiredJoints: [HandSkeleton.JointName] = [
        .wrist,
        .thumbKnuckle,
        .thumbIntermediateBase,
        .thumbIntermediateTip,
        .thumbTip,
        .indexFingerMetacarpal,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .indexFingerTip,
        .middleFingerMetacarpal,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip,
        .ringFingerMetacarpal,
        .ringFingerKnuckle,
        .ringFingerIntermediateBase,
        .ringFingerIntermediateTip,
        .ringFingerTip,
        .littleFingerMetacarpal,
        .littleFingerKnuckle,
        .littleFingerIntermediateBase,
        .littleFingerIntermediateTip,
        .littleFingerTip
    ]

    static func makeFeature(
        for side: HandSide,
        from hand: HandTrackingSnapshot.HandState
    ) -> HandPoseFeature {
        guard hand.isTracked else {
            return HandPoseFeature(
                side: side,
                originJoint: originJoint,
                jointPositions: [:],
                missingJoints: requiredJoints
            )
        }

        let worldPositions = Dictionary(
            uniqueKeysWithValues: hand.joints.map { sample in
                let positionSample = HandJointPositionSample(sample: sample)
                return (positionSample.name, positionSample.worldPosition)
            }
        )

        let missingJoints = requiredJoints.filter { jointName in
            worldPositions[jointName] == nil
        }

        guard let originPosition = worldPositions[originJoint] else {
            return HandPoseFeature(
                side: side,
                originJoint: originJoint,
                jointPositions: [:],
                missingJoints: missingJoints
            )
        }

        let relativePositions = Dictionary(
            uniqueKeysWithValues: requiredJoints.compactMap { jointName in
                guard let worldPosition = worldPositions[jointName] else {
                    return nil
                }

                return (jointName, worldPosition - originPosition)
            }
        )

        return HandPoseFeature(
            side: side,
            originJoint: originJoint,
            jointPositions: relativePositions,
            missingJoints: missingJoints
        )
    }
}
