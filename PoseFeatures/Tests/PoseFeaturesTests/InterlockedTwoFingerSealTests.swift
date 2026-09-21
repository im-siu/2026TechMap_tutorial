import XCTest
@testable import PoseFeatures

final class InterlockedTwoFingerSealTests: XCTestCase {
    func testInterlockedTwoFingerSealIsCandidateAcrossHandScales() {
        let left = sealInput(side: .left, wrist: SIMD3(-0.025, 0, 0), scale: 0.1)
        let right = sealInput(side: .right, wrist: SIMD3(0.025, 0, 0), scale: 0.2)

        let evaluation = InterlockedTwoFingerSeal.evaluate(
            left: InterlockedTwoFingerSeal.makeFeature(from: left),
            right: InterlockedTwoFingerSeal.makeFeature(from: right)
        )

        XCTAssertEqual(evaluation.status, .candidate)
        XCTAssertNotNil(evaluation.normalizedInterlockDistance)
    }

    func testMissingOptionalJointsProducesPartialFeatureThatRemainsCandidate() {
        let left = sealInput(
            side: .left,
            wrist: SIMD3(-0.025, 0, 0),
            scale: 0.1,
            includesOptionalJoints: false
        )
        let right = sealInput(side: .right, wrist: SIMD3(0.025, 0, 0), scale: 0.1)

        let leftFeature = InterlockedTwoFingerSeal.makeFeature(from: left)
        let evaluation = InterlockedTwoFingerSeal.evaluate(
            left: leftFeature,
            right: InterlockedTwoFingerSeal.makeFeature(from: right)
        )

        XCTAssertEqual(leftFeature.availability, .partial)
        XCTAssertTrue(leftFeature.availableJoints.contains(.indexFingerTip))
        XCTAssertFalse(leftFeature.availableJoints.contains(.littleFingerTip))
        XCTAssertFalse(leftFeature.missingOptionalJoints.isEmpty)
        XCTAssertEqual(evaluation.status, .candidate)
    }

    func testBentIndexFingerIsNotMatched() {
        let left = sealInput(side: .left, wrist: SIMD3(-0.025, 0, 0), scale: 0.1, bendsIndexFinger: true)
        let right = sealInput(side: .right, wrist: SIMD3(0.025, 0, 0), scale: 0.1)

        let evaluation = InterlockedTwoFingerSeal.evaluate(
            left: InterlockedTwoFingerSeal.makeFeature(from: left),
            right: InterlockedTwoFingerSeal.makeFeature(from: right)
        )

        XCTAssertEqual(evaluation.status, .notMatched)
    }

    func testSeparatedHandsAreNotMatched() {
        let left = sealInput(side: .left, wrist: SIMD3(-0.3, 0, 0), scale: 0.1)
        let right = sealInput(side: .right, wrist: SIMD3(0.3, 0, 0), scale: 0.1)

        let evaluation = InterlockedTwoFingerSeal.evaluate(
            left: InterlockedTwoFingerSeal.makeFeature(from: left),
            right: InterlockedTwoFingerSeal.makeFeature(from: right)
        )

        XCTAssertEqual(evaluation.status, .notMatched)
    }

    func testMissingRequiredJointIsNotEvaluable() {
        let left = sealInput(
            side: .left,
            wrist: SIMD3(-0.025, 0, 0),
            scale: 0.1,
            includesMiddleTip: false
        )
        let right = sealInput(side: .right, wrist: SIMD3(0.025, 0, 0), scale: 0.1)

        let leftFeature = InterlockedTwoFingerSeal.makeFeature(from: left)
        let evaluation = InterlockedTwoFingerSeal.evaluate(
            left: leftFeature,
            right: InterlockedTwoFingerSeal.makeFeature(from: right)
        )

        XCTAssertEqual(leftFeature.availability, .unavailable)
        XCTAssertTrue(leftFeature.missingRequiredJoints.contains(.middleFingerTip))
        XCTAssertEqual(evaluation.status, .notEvaluable)
    }

    private func sealInput(
        side: HandSide,
        wrist: SIMD3<Float>,
        scale: Float,
        includesOptionalJoints: Bool = true,
        includesMiddleTip: Bool = true,
        bendsIndexFinger: Bool = false
    ) -> HandPoseInput {
        func point(_ x: Float, _ y: Float) -> SIMD3<Float> {
            wrist + SIMD3(x * scale, y * scale, 0)
        }

        var positions: [HandJoint: SIMD3<Float>] = [
            .wrist: wrist,
            .indexFingerKnuckle: point(0.2, 0.3),
            .indexFingerIntermediateBase: point(0.2, 0.7),
            .indexFingerIntermediateTip: point(0.2, 1.1),
            .indexFingerTip: point(0.2, 1.5),
            .middleFingerKnuckle: point(0.6, 0.3),
            .middleFingerIntermediateBase: point(0.6, 0.8),
            .middleFingerIntermediateTip: point(0.6, 1.3),
            .middleFingerTip: point(0.6, 1.8)
        ]

        if bendsIndexFinger {
            positions[.indexFingerIntermediateBase] = point(0.7, 0.6)
            positions[.indexFingerIntermediateTip] = point(-0.3, 0.8)
            positions[.indexFingerTip] = point(0.2, 0.9)
        }

        if !includesMiddleTip {
            positions.removeValue(forKey: .middleFingerTip)
        }

        if includesOptionalJoints {
            positions[.thumbKnuckle] = point(-0.2, 0.2)
            positions[.thumbTip] = point(-0.3, 0.4)
            positions[.ringFingerKnuckle] = point(1.0, 0.3)
            positions[.ringFingerTip] = point(0.8, 0.5)
            positions[.littleFingerKnuckle] = point(1.2, 0.25)
            positions[.littleFingerTip] = point(0.9, 0.35)
        }

        return HandPoseInput(side: side, jointPositions: positions)
    }
}
