import ARKit
import Foundation
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
        case .left: "왼손"
        case .right: "오른손"
        }
    }
}

struct HandJointSample {
    let name: HandSkeleton.JointName
    let isTracked: Bool
    let originFromJointTransform: simd_float4x4

    var worldPosition: SIMD3<Float> {
        let translation = originFromJointTransform.columns.3
        return SIMD3(translation.x, translation.y, translation.z)
    }
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

    subscript(side: HandSide) -> HandSnapshot? {
        get { side == .left ? left : right }
        set {
            if side == .left {
                left = newValue
            } else {
                right = newValue
            }
        }
    }
}

enum HandTrackingStatus: Equatable {
    case idle
    case requestingAuthorization
    case starting
    case running
    case stopped
    case unsupported
    case denied
    case failed(String)

    var title: String {
        switch self {
        case .idle: "대기 중"
        case .requestingAuthorization: "권한 확인 중"
        case .starting: "세션 시작 중"
        case .running: "관절 수신 중"
        case .stopped: "중지됨"
        case .unsupported: "지원하지 않음"
        case .denied: "권한 거부됨"
        case .failed: "오류"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            "실기기 검증 시작을 눌러 Immersive Space를 여세요."
        case .requestingAuthorization:
            "손 추적 권한 상태를 확인하고 있습니다."
        case .starting:
            "ARKitSession과 HandTrackingProvider를 시작합니다."
        case .running:
            "양손을 시야에 두고 관절 구체와 수신 값을 확인하세요."
        case .stopped:
            "마지막 관찰값은 유지됩니다. 다시 시작해 재검증할 수 있습니다."
        case .unsupported:
            "Simulator가 아닌 지원되는 Apple Vision Pro에서 실행하세요."
        case .denied:
            "설정에서 이 앱의 손 추적 권한을 허용한 뒤 다시 실행하세요."
        case .failed(let reason):
            reason
        }
    }

    var isFailure: Bool {
        switch self {
        case .unsupported, .denied, .failed:
            true
        default:
            false
        }
    }
}

enum HandAuthorizationState: String {
    case unknown = "확인 전"
    case notDetermined = "결정 전"
    case allowed = "허용됨"
    case denied = "거부됨"
}

struct HandObservation: Equatable {
    var isTracked = false
    var jointCount = 0
    var updateCount = 0
    var lossCount = 0
    var updateRateHz: Double = 0
    var wristWorldPosition: SIMD3<Float>?
    var palmWidthMeters: Float?
    var pinchDistanceMeters: Float?
    var wristToMiddleTipMeters: Float?

}

struct VerificationMetrics: Equatable {
    var left = HandObservation()
    var right = HandObservation()
    var lastUpdateAt: Date?
    var palmCenterDistanceMeters: Float?

    var normalizedPalmCenterDistance: Float?

    subscript(side: HandSide) -> HandObservation {
        get { side == .left ? left : right }
        set {
            if side == .left {
                left = newValue
            } else {
                right = newValue
            }
        }
    }
}

struct VerificationLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let message: String
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

    static func stableName(for joint: HandSkeleton.JointName) -> String {
        names[joint] ?? "unknown"
    }

    private static let names: [HandSkeleton.JointName: String] = [
        .forearmArm: "forearmArm",
        .forearmWrist: "forearmWrist",
        .wrist: "wrist",
        .thumbKnuckle: "thumbKnuckle",
        .thumbIntermediateBase: "thumbIntermediateBase",
        .thumbIntermediateTip: "thumbIntermediateTip",
        .thumbTip: "thumbTip",
        .indexFingerMetacarpal: "indexFingerMetacarpal",
        .indexFingerKnuckle: "indexFingerKnuckle",
        .indexFingerIntermediateBase: "indexFingerIntermediateBase",
        .indexFingerIntermediateTip: "indexFingerIntermediateTip",
        .indexFingerTip: "indexFingerTip",
        .middleFingerMetacarpal: "middleFingerMetacarpal",
        .middleFingerKnuckle: "middleFingerKnuckle",
        .middleFingerIntermediateBase: "middleFingerIntermediateBase",
        .middleFingerIntermediateTip: "middleFingerIntermediateTip",
        .middleFingerTip: "middleFingerTip",
        .ringFingerMetacarpal: "ringFingerMetacarpal",
        .ringFingerKnuckle: "ringFingerKnuckle",
        .ringFingerIntermediateBase: "ringFingerIntermediateBase",
        .ringFingerIntermediateTip: "ringFingerIntermediateTip",
        .ringFingerTip: "ringFingerTip",
        .littleFingerMetacarpal: "littleFingerMetacarpal",
        .littleFingerKnuckle: "littleFingerKnuckle",
        .littleFingerIntermediateBase: "littleFingerIntermediateBase",
        .littleFingerIntermediateTip: "littleFingerIntermediateTip",
        .littleFingerTip: "littleFingerTip"
    ]
}

enum VerificationRecordingState: Equatable {
    case idle
    case starting
    case recording
    case stopping
    case ready
    case failed(String)

    var title: String {
        switch self {
        case .idle: "기록 대기"
        case .starting: "기록 준비 중"
        case .recording: "기록 중"
        case .stopping: "파일 정리 중"
        case .ready: "내보내기 준비됨"
        case .failed: "기록 오류"
        }
    }

    var isRecording: Bool {
        self == .recording
    }
}

struct RecordingMarker: Equatable {
    let index: Int
    let label: String
    let elapsedSeconds: TimeInterval
}
