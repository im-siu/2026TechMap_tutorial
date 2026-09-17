import XCTest
@testable import PoseFeatures

final class BilateralPinchPoseTests: XCTestCase {
    func testBilateralPinchMatchesAcrossHandScales() {
        let left = completeInput(side: .left, scale: 0.1, pinchDistanceRatio: 0.2)
        let right = completeInput(side: .right, scale: 0.2, pinchDistanceRatio: 0.2)

        let leftFeature = BilateralPinchPose.makeFeature(from: left)
        let rightFeature = BilateralPinchPose.makeFeature(from: right)
        let evaluation = BilateralPinchPose.evaluate(left: leftFeature, right: rightFeature)

        XCTAssertEqual(leftFeature.availability, .complete)
        XCTAssertEqual(rightFeature.availability, .complete)
        XCTAssertEqual(leftFeature.normalizedPinchDistance ?? -1, 0.2, accuracy: 0.0001)
        XCTAssertEqual(rightFeature.normalizedPinchDistance ?? -1, 0.2, accuracy: 0.0001)
        XCTAssertEqual(evaluation.status, .matched)
    }

    func testMissingAuxiliaryJointProducesPartialFeatureThatRemainsEvaluable() {
        let left = completeInput(side: .left, scale: 0.1, pinchDistanceRatio: 0.2, includesAuxiliaryJoints: false)
        let right = completeInput(side: .right, scale: 0.1, pinchDistanceRatio: 0.2)

        let leftFeature = BilateralPinchPose.makeFeature(from: left)
        let evaluation = BilateralPinchPose.evaluate(
            left: leftFeature,
            right: BilateralPinchPose.makeFeature(from: right)
        )

        XCTAssertEqual(leftFeature.availability, .partial)
        XCTAssertEqual(leftFeature.missingFeatures, [.orientationHints])
        XCTAssertEqual(evaluation.status, .matched)
    }

    func testOpenHandIsNotMatched() {
        let left = completeInput(side: .left, scale: 0.1, pinchDistanceRatio: 0.2)
        let right = completeInput(side: .right, scale: 0.1, pinchDistanceRatio: 0.8)

        let evaluation = BilateralPinchPose.evaluate(
            left: BilateralPinchPose.makeFeature(from: left),
            right: BilateralPinchPose.makeFeature(from: right)
        )

        XCTAssertEqual(evaluation.status, .notMatched)
    }

    func testMissingRequiredJointIsNotEvaluable() {
        var left = completeInput(side: .left, scale: 0.1, pinchDistanceRatio: 0.2)
        left = HandPoseInput(
            side: left.side,
            jointPositions: left.jointPositions.filter { $0.key != .thumbTip }
        )
        let right = completeInput(side: .right, scale: 0.1, pinchDistanceRatio: 0.2)

        let leftFeature = BilateralPinchPose.makeFeature(from: left)
        let evaluation = BilateralPinchPose.evaluate(
            left: leftFeature,
            right: BilateralPinchPose.makeFeature(from: right)
        )

        XCTAssertEqual(leftFeature.availability, .unavailable)
        XCTAssertTrue(leftFeature.missingJoints.contains(.thumbTip))
        XCTAssertEqual(evaluation.status, .notEvaluable)
    }

    func testVerificationRecordUsesCurrentSchemaAndIncludesMetrics() {
        let record = PoseFeatureVerificationAdapter.makeRecord(
            leftInput: completeInput(side: .left, scale: 0.1, pinchDistanceRatio: 0.2),
            rightInput: completeInput(side: .right, scale: 0.1, pinchDistanceRatio: 0.2),
            capturedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(record.schemaVersion, 1)
        XCTAssertEqual(record.targetPose, .bilateralPinch)
        XCTAssertEqual(record.evaluationStatus, .matched)
        XCTAssertEqual(record.hands.count, 2)
        XCTAssertEqual(record.metrics.leftNormalizedPinchDistance ?? -1, 0.2, accuracy: 0.0001)
    }

    func testTrackingAdapterCreatesARecordFromTrackedJointSamples() {
        let leftInput = completeInput(side: .left, scale: 0.1, pinchDistanceRatio: 0.2)
        let rightInput = completeInput(side: .right, scale: 0.1, pinchDistanceRatio: 0.2)
        let record = HandTrackingPoseFeatureAdapter.makeVerificationRecord(
            leftSamples: trackedSamples(from: leftInput),
            rightSamples: trackedSamples(from: rightInput),
            capturedAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(record.evaluationStatus, .matched)
        XCTAssertEqual(record.hands.map(\.availability), [.complete, .complete])
    }

    private func completeInput(
        side: HandSide,
        scale: Float,
        pinchDistanceRatio: Float,
        includesAuxiliaryJoints: Bool = true
    ) -> HandPoseInput {
        let halfPinchDistance = scale * pinchDistanceRatio / 2
        var positions: [HandJoint: SIMD3<Float>] = [
            .wrist: .zero,
            .middleFingerKnuckle: SIMD3(0, scale, 0),
            .thumbTip: SIMD3(-halfPinchDistance, 0, 0),
            .indexFingerTip: SIMD3(halfPinchDistance, 0, 0)
        ]

        if includesAuxiliaryJoints {
            positions[.thumbKnuckle] = SIMD3(-scale * 0.25, scale * 0.25, 0)
            positions[.indexFingerKnuckle] = SIMD3(scale * 0.25, scale * 0.25, 0)
            positions[.forearmWrist] = SIMD3(0, -scale * 0.5, 0)
        }

        return HandPoseInput(side: side, jointPositions: positions)
    }

    private func trackedSamples(from input: HandPoseInput) -> [TrackedJointPosition] {
        input.jointPositions.map { joint, position in
            TrackedJointPosition(joint: joint, worldPosition: position)
        }
    }
}
