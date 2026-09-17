import Foundation

public enum HandTrackingPoseFeatureAdapter {
    public static func makeInput(
        side: HandSide,
        samples: [TrackedJointPosition]
    ) -> HandPoseInput {
        let positions = samples.reduce(into: [HandJoint: SIMD3<Float>]()) { positions, sample in
            positions[sample.joint] = sample.worldPosition
        }

        return HandPoseInput(side: side, jointPositions: positions)
    }

    public static func makeVerificationRecord(
        leftSamples: [TrackedJointPosition],
        rightSamples: [TrackedJointPosition],
        capturedAt: Date = .now
    ) -> PoseFeatureVerificationRecord {
        PoseFeatureVerificationAdapter.makeRecord(
            leftInput: makeInput(side: .left, samples: leftSamples),
            rightInput: makeInput(side: .right, samples: rightSamples),
            capturedAt: capturedAt
        )
    }
}
