import PoseFeatures
import simd

enum SyntheticHandSamples {
  static func open(side: HandSide = .right) -> HandSample {
    var joints: [HandJoint: SIMD3<Float>] = [
      .wrist: [0, 0, 0],

      .thumbKnuckle: [-0.020, 0.015, 0],
      .thumbIntermediateBase: [-0.032, 0.025, 0],
      .thumbIntermediateTip: [-0.044, 0.035, 0],
      .thumbTip: [-0.056, 0.045, 0],

      .indexFingerMetacarpal: [-0.025, 0.030, 0],
      .indexFingerKnuckle: [-0.025, 0.055, 0],
      .indexFingerIntermediateBase: [-0.025, 0.080, 0],
      .indexFingerIntermediateTip: [-0.025, 0.105, 0],
      .indexFingerTip: [-0.025, 0.130, 0],

      .middleFingerMetacarpal: [0, 0.040, 0],
      .middleFingerKnuckle: [0, 0.070, 0],
      .middleFingerIntermediateBase: [0, 0.100, 0],
      .middleFingerIntermediateTip: [0, 0.130, 0],
      .middleFingerTip: [0, 0.160, 0],

      .ringFingerMetacarpal: [0.020, 0.035, 0],
      .ringFingerKnuckle: [0.020, 0.063, 0],
      .ringFingerIntermediateBase: [0.020, 0.090, 0],
      .ringFingerIntermediateTip: [0.020, 0.117, 0],
      .ringFingerTip: [0.020, 0.144, 0],

      .littleFingerMetacarpal: [0.040, 0.025, 0],
      .littleFingerKnuckle: [0.040, 0.050, 0],
      .littleFingerIntermediateBase: [0.040, 0.075, 0],
      .littleFingerIntermediateTip: [0.040, 0.100, 0],
      .littleFingerTip: [0.040, 0.125, 0],
    ]

    if side == .left {
      joints = joints.mapValues { [-$0.x, $0.y, $0.z] }
    }
    return HandSample(side: side, joints: joints)
  }

  static func fist(side: HandSide = .right) -> HandSample {
    var sample = open(side: side)
    let direction: Float = side == .right ? 1 : -1

    curl(
      joints: &sample.joints,
      chain: [
        .indexFingerMetacarpal,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .indexFingerTip,
      ],
      lateralOffset: 0,
      direction: direction
    )
    curl(
      joints: &sample.joints,
      chain: [
        .middleFingerMetacarpal,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip,
      ],
      lateralOffset: 0.001,
      direction: direction
    )
    curl(
      joints: &sample.joints,
      chain: [
        .ringFingerMetacarpal,
        .ringFingerKnuckle,
        .ringFingerIntermediateBase,
        .ringFingerIntermediateTip,
        .ringFingerTip,
      ],
      lateralOffset: 0.002,
      direction: direction
    )
    curl(
      joints: &sample.joints,
      chain: [
        .littleFingerMetacarpal,
        .littleFingerKnuckle,
        .littleFingerIntermediateBase,
        .littleFingerIntermediateTip,
        .littleFingerTip,
      ],
      lateralOffset: 0.003,
      direction: direction
    )
    return sample
  }

  static func pinch(side: HandSide = .right) -> HandSample {
    var sample = open(side: side)
    let indexTip = sample.joints[.indexFingerTip]!
    sample.joints[.thumbIntermediateTip] = indexTip + [0, -0.018, 0.006]
    sample.joints[.thumbTip] = indexTip + [0.001, 0, 0]
    return sample
  }

  static func partiallyBentIndex(side: HandSide = .right) -> HandSample {
    var sample = open(side: side)
    let x = sample.joints[.indexFingerMetacarpal]!.x
    sample.joints[.indexFingerIntermediateTip] = [x, 0.095, -0.012]
    sample.joints[.indexFingerTip] = [x, 0.100, -0.032]
    return sample
  }

  static func transformed(
    _ sample: HandSample,
    scale: Float = 1,
    rotationY: Float = 0,
    translation: SIMD3<Float> = .zero
  ) -> HandSample {
    let cosine = cos(rotationY)
    let sine = sin(rotationY)
    let transformedJoints = sample.joints.mapValues { point in
      let scaled = point * scale
      let rotated = SIMD3<Float>(
        cosine * scaled.x + sine * scaled.z,
        scaled.y,
        -sine * scaled.x + cosine * scaled.z
      )
      return rotated + translation
    }
    return HandSample(side: sample.side, joints: transformedJoints)
  }

  private static func curl(
    joints: inout [HandJoint: SIMD3<Float>],
    chain: [HandJoint],
    lateralOffset: Float,
    direction: Float
  ) {
    let metacarpal = joints[chain[0]]!
    let x = metacarpal.x + lateralOffset * direction
    joints[chain[1]] = [x, metacarpal.y + 0.025, 0]
    joints[chain[2]] = [x, metacarpal.y + 0.040, -0.010]
    joints[chain[3]] = [x, metacarpal.y + 0.030, -0.025]
    joints[chain[4]] = [x, metacarpal.y + 0.010, -0.030]
  }
}
