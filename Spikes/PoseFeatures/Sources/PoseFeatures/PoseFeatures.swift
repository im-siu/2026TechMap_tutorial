import simd

public enum HandSide: Equatable, Sendable {
  case left
  case right
}

/// ARKit의 `HandSkeleton.JointName` 중 특징 계산에 필요한 관절 이름과 일치한다.
public enum HandJoint: String, CaseIterable, Hashable, Sendable {
  case wrist

  case thumbKnuckle
  case thumbIntermediateBase
  case thumbIntermediateTip
  case thumbTip

  case indexFingerMetacarpal
  case indexFingerKnuckle
  case indexFingerIntermediateBase
  case indexFingerIntermediateTip
  case indexFingerTip

  case middleFingerMetacarpal
  case middleFingerKnuckle
  case middleFingerIntermediateBase
  case middleFingerIntermediateTip
  case middleFingerTip

  case ringFingerMetacarpal
  case ringFingerKnuckle
  case ringFingerIntermediateBase
  case ringFingerIntermediateTip
  case ringFingerTip

  case littleFingerMetacarpal
  case littleFingerKnuckle
  case littleFingerIntermediateBase
  case littleFingerIntermediateTip
  case littleFingerTip
}

public enum Finger: CaseIterable, Hashable, Sendable {
  case thumb
  case index
  case middle
  case ring
  case little
}

/// 한 시점의 한 손을 나타내는 ARKit 비의존 입력이다.
public struct HandSample: Sendable {
  public var side: HandSide
  public var joints: [HandJoint: SIMD3<Float>]

  public init(side: HandSide, joints: [HandJoint: SIMD3<Float>]) {
    self.side = side
    self.joints = joints
  }

  /// 추적 계층이 전달한 월드 좌표 배열을 특징 계산 입력으로 변환한다.
  ///
  /// #5의 `HandSnapshot`처럼 추적 여부와 관절 배열을 따로 제공하는 입력을
  /// ARKit 타입 없이 연결하기 위한 경계다. 누락 관절은 이 단계에서 채우지 않고
  /// `HandFeatureExtractor`의 `missingJoints` 오류로 보고한다.
  public init(
    side: HandSide,
    isTracked: Bool,
    jointWorldPositions: [HandJointWorldPosition]
  ) throws {
    guard isTracked else {
      throw HandSampleConstructionError.handNotTracked(side)
    }

    var joints: [HandJoint: SIMD3<Float>] = [:]
    for sample in jointWorldPositions {
      guard joints.updateValue(sample.position, forKey: sample.joint) == nil else {
        throw HandSampleConstructionError.duplicateJoint(sample.joint)
      }
    }

    self.init(side: side, joints: joints)
  }
}

/// 추적 계층과 특징 계산 계층 사이에서 사용하는 ARKit 비의존 관절 월드 좌표다.
public struct HandJointWorldPosition: Equatable, Sendable {
  public let joint: HandJoint
  public let position: SIMD3<Float>

  public init(joint: HandJoint, position: SIMD3<Float>) {
    self.joint = joint
    self.position = position
  }
}

public enum HandSampleConstructionError: Error, Equatable, Sendable {
  case handNotTracked(HandSide)
  case duplicateJoint(HandJoint)
}

public enum FeatureExtractionError: Error, Equatable, Sendable {
  case missingJoints([HandJoint])
  case nonFinitePosition(HandJoint)
  case degeneratePalmScale
  case degeneratePalmPlane
  case degenerateFingerSegment(finger: Finger, segmentIndex: Int)
}

public struct NormalizationScales: Equatable, Sendable {
  public let palmWidth: Float
  public let palmLength: Float
  public let geometricMean: Float
}

public struct FingerFeatures: Equatable, Sendable {
  /// 첫 관절과 손끝의 직선거리를 관절 경로 길이로 나눈 값이다. 1에 가까울수록 곧다.
  public let straightness: Float

  /// 연속 뼈 벡터가 꺾인 각도(라디안)다. 0에 가까울수록 곧다.
  public let bendAnglesRadians: [Float]

  public let tipToWristDistance: Float
  public let normalizedTipToWristDistance: Float
}

public struct HandFeatures: Sendable {
  public let side: HandSide
  public let palmCenter: SIMD3<Float>
  public let palmNormal: SIMD3<Float>
  public let normalization: NormalizationScales
  public let fingers: [Finger: FingerFeatures]
  public let thumbIndexTipDistance: Float
  public let normalizedThumbIndexTipDistance: Float
}

public struct BimanualFeatures: Sendable {
  public let palmCenterDistance: Float
  public let normalizedPalmCenterDistance: Float

  /// 두 손의 중심이 같으면 방향을 정의할 수 없으므로 `nil`이다.
  public let leftToRightDirection: SIMD3<Float>?

  /// 두 법선의 내적이다. 범위는 -1...1이다.
  public let palmNormalAlignment: Float

  /// 각 손바닥 법선이 상대 손을 향하는 정도다. 중심이 같으면 `nil`이다.
  public let leftPalmFacingRight: Float?
  public let rightPalmFacingLeft: Float?
  public let mutualFacingScore: Float?
}

public enum HandFeatureExtractor {
  private static let epsilon: Float = 1e-6

  public static func extract(from sample: HandSample) throws -> HandFeatures {
    let requiredJoints = Set(HandJoint.allCases)
    let missing = requiredJoints.subtracting(sample.joints.keys).sorted {
      $0.rawValue < $1.rawValue
    }
    guard missing.isEmpty else {
      throw FeatureExtractionError.missingJoints(missing)
    }

    for joint in HandJoint.allCases {
      guard let position = sample.joints[joint], position.isFinite else {
        throw FeatureExtractionError.nonFinitePosition(joint)
      }
    }

    let wrist = sample.joints[.wrist]!
    let indexMetacarpal = sample.joints[.indexFingerMetacarpal]!
    let middleMetacarpal = sample.joints[.middleFingerMetacarpal]!
    let ringMetacarpal = sample.joints[.ringFingerMetacarpal]!
    let littleMetacarpal = sample.joints[.littleFingerMetacarpal]!

    let palmWidth = simd_distance(indexMetacarpal, littleMetacarpal)
    let palmLength = simd_distance(wrist, middleMetacarpal)
    guard palmWidth > epsilon, palmLength > epsilon else {
      throw FeatureExtractionError.degeneratePalmScale
    }

    let geometricMean = sqrt(palmWidth * palmLength)
    guard geometricMean.isFinite, geometricMean > epsilon else {
      throw FeatureExtractionError.degeneratePalmScale
    }

    let palmCenter =
      (wrist + indexMetacarpal + middleMetacarpal + ringMetacarpal + littleMetacarpal) / 5

    let widthDirection = littleMetacarpal - indexMetacarpal
    let lengthDirection = middleMetacarpal - wrist
    var palmNormal = simd_cross(widthDirection, lengthDirection)
    let normalLength = simd_length(palmNormal)
    guard normalLength > epsilon else {
      throw FeatureExtractionError.degeneratePalmPlane
    }
    palmNormal /= normalLength
    if sample.side == .left {
      palmNormal *= -1
    }

    var fingerFeatures: [Finger: FingerFeatures] = [:]
    for finger in Finger.allCases {
      fingerFeatures[finger] = try features(
        for: finger,
        sample: sample,
        wrist: wrist,
        normalizationScale: geometricMean
      )
    }

    let thumbIndexTipDistance = simd_distance(
      sample.joints[.thumbTip]!,
      sample.joints[.indexFingerTip]!
    )

    return HandFeatures(
      side: sample.side,
      palmCenter: palmCenter,
      palmNormal: palmNormal,
      normalization: NormalizationScales(
        palmWidth: palmWidth,
        palmLength: palmLength,
        geometricMean: geometricMean
      ),
      fingers: fingerFeatures,
      thumbIndexTipDistance: thumbIndexTipDistance,
      normalizedThumbIndexTipDistance: thumbIndexTipDistance / geometricMean
    )
  }

  private static func features(
    for finger: Finger,
    sample: HandSample,
    wrist: SIMD3<Float>,
    normalizationScale: Float
  ) throws -> FingerFeatures {
    let chain = jointChain(for: finger)
    let points = chain.map { sample.joints[$0]! }

    var pathLength: Float = 0
    var segments: [SIMD3<Float>] = []
    for index in 0..<(points.count - 1) {
      let segment = points[index + 1] - points[index]
      let length = simd_length(segment)
      guard length > epsilon else {
        throw FeatureExtractionError.degenerateFingerSegment(
          finger: finger,
          segmentIndex: index
        )
      }
      pathLength += length
      segments.append(segment / length)
    }

    var bendAngles: [Float] = []
    for index in 0..<(segments.count - 1) {
      let cosine = max(-1, min(1, simd_dot(segments[index], segments[index + 1])))
      bendAngles.append(acos(cosine))
    }

    let tip = points.last!
    let tipToWristDistance = simd_distance(wrist, tip)
    return FingerFeatures(
      straightness: simd_distance(points.first!, tip) / pathLength,
      bendAnglesRadians: bendAngles,
      tipToWristDistance: tipToWristDistance,
      normalizedTipToWristDistance: tipToWristDistance / normalizationScale
    )
  }

  private static func jointChain(for finger: Finger) -> [HandJoint] {
    switch finger {
    case .thumb:
      return [
        .thumbKnuckle,
        .thumbIntermediateBase,
        .thumbIntermediateTip,
        .thumbTip,
      ]
    case .index:
      return [
        .indexFingerMetacarpal,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .indexFingerTip,
      ]
    case .middle:
      return [
        .middleFingerMetacarpal,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip,
      ]
    case .ring:
      return [
        .ringFingerMetacarpal,
        .ringFingerKnuckle,
        .ringFingerIntermediateBase,
        .ringFingerIntermediateTip,
        .ringFingerTip,
      ]
    case .little:
      return [
        .littleFingerMetacarpal,
        .littleFingerKnuckle,
        .littleFingerIntermediateBase,
        .littleFingerIntermediateTip,
        .littleFingerTip,
      ]
    }
  }
}

public enum BimanualFeatureExtractor {
  private static let epsilon: Float = 1e-6

  public static func extract(left: HandSample, right: HandSample) throws -> BimanualFeatures {
    let leftFeatures = try HandFeatureExtractor.extract(from: left)
    let rightFeatures = try HandFeatureExtractor.extract(from: right)

    let offset = rightFeatures.palmCenter - leftFeatures.palmCenter
    let distance = simd_length(offset)
    let meanScale =
      (leftFeatures.normalization.geometricMean
        + rightFeatures.normalization.geometricMean) / 2

    let direction: SIMD3<Float>?
    let leftFacing: Float?
    let rightFacing: Float?
    let mutualFacing: Float?
    if distance > epsilon {
      let unitDirection = offset / distance
      direction = unitDirection
      leftFacing = simd_dot(leftFeatures.palmNormal, unitDirection)
      rightFacing = simd_dot(rightFeatures.palmNormal, -unitDirection)
      mutualFacing = min(leftFacing!, rightFacing!)
    } else {
      direction = nil
      leftFacing = nil
      rightFacing = nil
      mutualFacing = nil
    }

    return BimanualFeatures(
      palmCenterDistance: distance,
      normalizedPalmCenterDistance: distance / meanScale,
      leftToRightDirection: direction,
      palmNormalAlignment: simd_dot(
        leftFeatures.palmNormal,
        rightFeatures.palmNormal
      ),
      leftPalmFacingRight: leftFacing,
      rightPalmFacingLeft: rightFacing,
      mutualFacingScore: mutualFacing
    )
  }
}

extension SIMD3 where Scalar == Float {
  fileprivate var isFinite: Bool {
    x.isFinite && y.isFinite && z.isFinite
  }
}
