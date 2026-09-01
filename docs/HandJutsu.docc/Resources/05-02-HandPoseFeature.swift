import ARKit
import simd

struct HandPoseFeature {
    let side: HandSide
    let originJoint: HandSkeleton.JointName
    let jointPositions: [HandSkeleton.JointName: SIMD3<Float>]
    let missingJoints: [HandSkeleton.JointName]

    var isComplete: Bool {
        missingJoints.isEmpty
    }

    var trackedJointCount: Int {
        jointPositions.count
    }

    var thumbTipToIndexTipDistance: Float? {
        guard
            let thumbTip = jointPositions[.thumbTip],
            let indexTip = jointPositions[.indexFingerTip]
        else {
            return nil
        }

        return simd_distance(thumbTip, indexTip)
    }

    func position(for jointName: HandSkeleton.JointName) -> SIMD3<Float>? {
        jointPositions[jointName]
    }
}
