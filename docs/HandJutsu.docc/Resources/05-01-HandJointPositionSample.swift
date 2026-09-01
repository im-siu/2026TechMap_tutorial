import ARKit
import simd

struct HandJointPositionSample {
    let name: HandSkeleton.JointName
    let worldPosition: SIMD3<Float>

    init(sample: HandJointSample) {
        name = sample.name

        let translation = sample.originFromJointTransform.columns.3
        worldPosition = SIMD3<Float>(
            translation.x,
            translation.y,
            translation.z
        )
    }
}
