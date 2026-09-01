import ARKit

enum HandSide: CaseIterable, Hashable {
    case left
    case right

    var title: String {
        switch self {
        case .left:
            "Left"
        case .right:
            "Right"
        }
    }
}

struct HandJointSample {
    let name: HandSkeleton.JointName
    let originFromJointTransform: simd_float4x4
}
