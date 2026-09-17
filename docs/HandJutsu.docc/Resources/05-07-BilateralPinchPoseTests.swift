import XCTest
@testable import PoseFeatures

final class BilateralPinchPoseTests: XCTestCase {
    func testBilateralPinchMatchesAcrossHandScales() {
        let left = makePinchInput(side: .left, scale: 0.1, ratio: 0.2)
        let right = makePinchInput(side: .right, scale: 0.2, ratio: 0.2)

        let result = BilateralPinchPose.evaluate(
            left: BilateralPinchPose.makeFeature(from: left),
            right: BilateralPinchPose.makeFeature(from: right)
        )

        XCTAssertEqual(result.status, .matched)
    }

    func testMissingRequiredJointIsNotEvaluable() {
        let left = HandPoseInput(side: .left, jointPositions: [:])
        let right = makePinchInput(side: .right, scale: 0.1, ratio: 0.2)

        let result = BilateralPinchPose.evaluate(
            left: BilateralPinchPose.makeFeature(from: left),
            right: BilateralPinchPose.makeFeature(from: right)
        )

        XCTAssertEqual(result.status, .notEvaluable)
    }

    private func makePinchInput(
        side: HandSide,
        scale: Float,
        ratio: Float
    ) -> HandPoseInput {
        let halfDistance = scale * ratio / 2
        return HandPoseInput(
            side: side,
            jointPositions: [
                .wrist: .zero,
                .middleFingerKnuckle: SIMD3(0, scale, 0),
                .thumbTip: SIMD3(-halfDistance, 0, 0),
                .indexFingerTip: SIMD3(halfDistance, 0, 0)
            ]
        )
    }
}
