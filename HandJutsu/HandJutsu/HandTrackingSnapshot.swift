import ARKit
import simd

enum HandSide: CaseIterable, Hashable {
    case left
    case right

    init?(chirality: HandAnchor.Chirality) {
        switch chirality {
        case .left:
            self = .left
        case .right:
            self = .right
        @unknown default:
            return nil
        }
    }

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

struct HandSnapshot {
    let side: HandSide
    let isTracked: Bool
    let joints: [HandJointSample]
}

struct HandTrackingSnapshot {
    var left: HandSnapshot?
    var right: HandSnapshot?

    static let empty = HandTrackingSnapshot(left: nil, right: nil)
}

enum HandJointCatalog {
    static let all: [HandSkeleton.JointName] = [
        .forearmArm,
        .forearmWrist,
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
}
