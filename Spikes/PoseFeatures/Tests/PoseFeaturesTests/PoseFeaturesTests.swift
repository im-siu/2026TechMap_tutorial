import XCTest
import simd

@testable import PoseFeatures

final class PoseFeaturesTests: XCTestCase {
  private let accuracy: Float = 1e-5

  func testOpenFistAndPartialBendProduceOrderedFingerFeatures() throws {
    let open = try HandFeatureExtractor.extract(from: SyntheticHandSamples.open())
    let partial = try HandFeatureExtractor.extract(
      from: SyntheticHandSamples.partiallyBentIndex()
    )
    let fist = try HandFeatureExtractor.extract(from: SyntheticHandSamples.fist())

    let openIndex = try XCTUnwrap(open.fingers[.index])
    let partialIndex = try XCTUnwrap(partial.fingers[.index])
    let fistIndex = try XCTUnwrap(fist.fingers[.index])

    XCTAssertGreaterThan(openIndex.straightness, partialIndex.straightness)
    XCTAssertGreaterThan(partialIndex.straightness, fistIndex.straightness)
    XCTAssertEqual(openIndex.straightness, 1, accuracy: 0.001)
    XCTAssertEqual(partialIndex.straightness, 0.86, accuracy: 0.01)
    XCTAssertEqual(fistIndex.straightness, 0.39, accuracy: 0.01)
    XCTAssertLessThan(openIndex.bendAnglesRadians.max()!, 0.001)
    XCTAssertGreaterThan(fistIndex.bendAnglesRadians.max()!, 0.5)
    XCTAssertGreaterThan(
      openIndex.normalizedTipToWristDistance,
      fistIndex.normalizedTipToWristDistance
    )
    XCTAssertEqual(openIndex.normalizedTipToWristDistance, 2.59, accuracy: 0.01)
    XCTAssertEqual(fistIndex.normalizedTipToWristDistance, 1.10, accuracy: 0.01)
  }

  func testPinchReducesNormalizedThumbIndexDistance() throws {
    let open = try HandFeatureExtractor.extract(from: SyntheticHandSamples.open())
    let pinch = try HandFeatureExtractor.extract(from: SyntheticHandSamples.pinch())

    XCTAssertGreaterThan(open.normalizedThumbIndexTipDistance, 1)
    XCTAssertLessThan(pinch.normalizedThumbIndexTipDistance, 0.05)
    XCTAssertEqual(open.normalizedThumbIndexTipDistance, 1.77, accuracy: 0.01)
    XCTAssertEqual(pinch.normalizedThumbIndexTipDistance, 0.020, accuracy: 0.001)
  }

  func testNormalizedFeaturesAreInvariantToTranslationRotationAndScale() throws {
    let original = try HandFeatureExtractor.extract(from: SyntheticHandSamples.pinch())
    let transformed = try HandFeatureExtractor.extract(
      from: SyntheticHandSamples.transformed(
        SyntheticHandSamples.pinch(),
        scale: 1.8,
        rotationY: 0.73,
        translation: [0.4, -0.2, 1.1]
      )
    )

    XCTAssertEqual(
      transformed.normalization.palmWidth,
      original.normalization.palmWidth * 1.8,
      accuracy: accuracy
    )
    XCTAssertEqual(
      transformed.normalization.palmLength,
      original.normalization.palmLength * 1.8,
      accuracy: accuracy
    )
    XCTAssertEqual(
      transformed.normalizedThumbIndexTipDistance,
      original.normalizedThumbIndexTipDistance,
      accuracy: accuracy
    )

    for finger in Finger.allCases {
      let originalFinger = try XCTUnwrap(original.fingers[finger])
      let transformedFinger = try XCTUnwrap(transformed.fingers[finger])
      XCTAssertEqual(
        transformedFinger.straightness,
        originalFinger.straightness,
        accuracy: accuracy
      )
      XCTAssertEqual(
        transformedFinger.normalizedTipToWristDistance,
        originalFinger.normalizedTipToWristDistance,
        accuracy: accuracy
      )
      assertEqualArrays(
        transformedFinger.bendAnglesRadians,
        originalFinger.bendAnglesRadians,
        accuracy: accuracy
      )
    }
  }

  func testMirroredHandsProduceConsistentPalmNormals() throws {
    let right = try HandFeatureExtractor.extract(
      from: SyntheticHandSamples.open(side: .right)
    )
    let left = try HandFeatureExtractor.extract(
      from: SyntheticHandSamples.open(side: .left)
    )

    XCTAssertEqual(left.palmNormal.x, right.palmNormal.x, accuracy: accuracy)
    XCTAssertEqual(left.palmNormal.y, right.palmNormal.y, accuracy: accuracy)
    XCTAssertEqual(left.palmNormal.z, right.palmNormal.z, accuracy: accuracy)
  }

  func testBimanualFeaturesMeasureDistanceDirectionAndFacing() throws {
    let left = SyntheticHandSamples.transformed(
      SyntheticHandSamples.open(side: .left),
      rotationY: .pi / 2,
      translation: [-0.2, 0, 0]
    )
    let right = SyntheticHandSamples.transformed(
      SyntheticHandSamples.open(side: .right),
      rotationY: -.pi / 2,
      translation: [0.2, 0, 0]
    )
    let features = try BimanualFeatureExtractor.extract(left: left, right: right)
    let direction = try XCTUnwrap(features.leftToRightDirection)
    let leftFacing = try XCTUnwrap(features.leftPalmFacingRight)
    let rightFacing = try XCTUnwrap(features.rightPalmFacingLeft)
    let mutualFacing = try XCTUnwrap(features.mutualFacingScore)

    XCTAssertGreaterThan(features.palmCenterDistance, 0)
    XCTAssertGreaterThan(features.normalizedPalmCenterDistance, 0)
    XCTAssertEqual(direction.x, 1, accuracy: accuracy)
    XCTAssertEqual(direction.y, 0, accuracy: accuracy)
    XCTAssertEqual(direction.z, 0, accuracy: accuracy)
    XCTAssertEqual(features.palmNormalAlignment, -1, accuracy: accuracy)
    XCTAssertEqual(leftFacing, 1, accuracy: accuracy)
    XCTAssertEqual(rightFacing, 1, accuracy: accuracy)
    XCTAssertEqual(mutualFacing, 1, accuracy: accuracy)
  }

  func testBimanualNormalizationSupportsDifferentHandSizes() throws {
    let left = SyntheticHandSamples.transformed(
      SyntheticHandSamples.open(side: .left),
      scale: 0.8,
      translation: [-0.15, 0, 0]
    )
    let right = SyntheticHandSamples.transformed(
      SyntheticHandSamples.open(side: .right),
      scale: 1.3,
      translation: [0.15, 0, 0]
    )
    let features = try BimanualFeatureExtractor.extract(left: left, right: right)
    let scaledFeatures = try BimanualFeatureExtractor.extract(
      left: SyntheticHandSamples.transformed(left, scale: 2),
      right: SyntheticHandSamples.transformed(right, scale: 2)
    )

    XCTAssertTrue(features.palmCenterDistance.isFinite)
    XCTAssertTrue(features.normalizedPalmCenterDistance.isFinite)
    XCTAssertGreaterThan(features.normalizedPalmCenterDistance, 0)
    XCTAssertEqual(
      scaledFeatures.normalizedPalmCenterDistance,
      features.normalizedPalmCenterDistance,
      accuracy: accuracy
    )
  }

  func testMissingNonFiniteAndDegenerateInputsProduceExplicitErrors() throws {
    var missing = SyntheticHandSamples.open()
    missing.joints[.thumbTip] = nil
    XCTAssertThrowsError(try HandFeatureExtractor.extract(from: missing)) { error in
      XCTAssertEqual(error as? FeatureExtractionError, .missingJoints([.thumbTip]))
    }

    var nonFinite = SyntheticHandSamples.open()
    nonFinite.joints[.thumbTip] = [.infinity, 0, 0]
    XCTAssertThrowsError(try HandFeatureExtractor.extract(from: nonFinite)) { error in
      XCTAssertEqual(error as? FeatureExtractionError, .nonFinitePosition(.thumbTip))
    }

    var zeroWidth = SyntheticHandSamples.open()
    zeroWidth.joints[.littleFingerMetacarpal] = zeroWidth.joints[.indexFingerMetacarpal]
    XCTAssertThrowsError(try HandFeatureExtractor.extract(from: zeroWidth)) { error in
      XCTAssertEqual(error as? FeatureExtractionError, .degeneratePalmScale)
    }

    var duplicateSegment = SyntheticHandSamples.open()
    duplicateSegment.joints[.indexFingerIntermediateBase] =
      duplicateSegment.joints[
        .indexFingerKnuckle
      ]
    XCTAssertThrowsError(try HandFeatureExtractor.extract(from: duplicateSegment)) { error in
      XCTAssertEqual(
        error as? FeatureExtractionError,
        .degenerateFingerSegment(finger: .index, segmentIndex: 1)
      )
    }
  }

  func testCoincidentPalmCentersHaveNoDirectionAndNoNaN() throws {
    let left = SyntheticHandSamples.open(side: .left)
    let right = HandSample(side: .right, joints: left.joints)
    let features = try BimanualFeatureExtractor.extract(left: left, right: right)

    XCTAssertEqual(features.palmCenterDistance, 0, accuracy: accuracy)
    XCTAssertEqual(features.normalizedPalmCenterDistance, 0, accuracy: accuracy)
    XCTAssertNil(features.leftToRightDirection)
    XCTAssertNil(features.leftPalmFacingRight)
    XCTAssertNil(features.rightPalmFacingLeft)
    XCTAssertNil(features.mutualFacingScore)
    XCTAssertTrue(features.palmNormalAlignment.isFinite)
  }
}

extension XCTestCase {
  fileprivate func assertEqualArrays(
    _ values: [Float],
    _ expectedValues: [Float],
    accuracy: Float,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(values.count, expectedValues.count, file: file, line: line)
    for (value, expected) in zip(values, expectedValues) {
      XCTAssertEqual(value, expected, accuracy: accuracy, file: file, line: line)
    }
  }
}
