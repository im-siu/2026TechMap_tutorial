import XCTest
@testable import PoseFeatures

final class SpellEffectControllerTests: XCTestCase {
    func testOriginAveragesFourFingerTips() {
        let left = hand(
            side: .left,
            indexTip: SIMD3(0, 0, 0),
            middleTip: SIMD3(0, 2, 0)
        )
        let right = hand(
            side: .right,
            indexTip: SIMD3(2, 0, 0),
            middleTip: SIMD3(2, 2, 0)
        )

        XCTAssertEqual(SpellEffectOrigin.make(left: left, right: right), SIMD3(1, 1, 0))
    }

    func testOriginRequiresBothIndexAndMiddleTips() {
        let left = HandPoseInput(
            side: .left,
            jointPositions: [.indexFingerTip: SIMD3(0, 0, 0)]
        )
        let right = hand(
            side: .right,
            indexTip: SIMD3(2, 0, 0),
            middleTip: SIMD3(2, 2, 0)
        )

        XCTAssertNil(SpellEffectOrigin.make(left: left, right: right))
    }

    func testControllerKeepsTheLastOriginOnlyDuringTheGraceDuration() {
        var controller = makeController()
        let origin = SIMD3<Float>(0.1, 0.2, -0.3)

        XCTAssertEqual(
            controller.update(spellState: .charging, origin: origin, at: 0).origin,
            origin
        )

        let recovered = controller.update(spellState: .charging, origin: nil, at: 0.05)
        XCTAssertTrue(recovered.isVisible)
        XCTAssertEqual(recovered.origin, origin)

        let expired = controller.update(spellState: .charging, origin: nil, at: 0.16)
        XCTAssertFalse(expired.isVisible)
        XCTAssertNil(expired.origin)
    }

    func testControllerNeverUsesOriginWhenNoReliablePositionExists() {
        var controller = makeController()

        let presentation = controller.update(spellState: .charging, origin: nil, at: 0)

        XCTAssertFalse(presentation.isVisible)
        XCTAssertNil(presentation.origin)
    }

    func testIdleAndCooldownHideTheEffectAndClearItsCachedOrigin() {
        var controller = makeController()
        let origin = SIMD3<Float>(0.1, 0.2, -0.3)

        _ = controller.update(spellState: .charging, origin: origin, at: 0)
        XCTAssertFalse(controller.update(spellState: .idle, origin: origin, at: 0.1).isVisible)

        let afterIdle = controller.update(spellState: .charging, origin: nil, at: 0.11)
        XCTAssertFalse(afterIdle.isVisible)
        XCTAssertNil(afterIdle.origin)
    }

    func testStylesExposeDifferentColorsWhileSharingTheSamePresentation() {
        XCTAssertNotEqual(SpellStyle.light.color, SpellStyle.fire.color)
        XCTAssertNotEqual(SpellStyle.fire.color, SpellStyle.water.color)
    }

    private func makeController() -> SpellEffectController {
        SpellEffectController(
            configuration: SpellEffectControllerConfiguration(originGraceDuration: 0.1)
        )
    }

    private func hand(
        side: HandSide,
        indexTip: SIMD3<Float>,
        middleTip: SIMD3<Float>
    ) -> HandPoseInput {
        HandPoseInput(
            side: side,
            jointPositions: [
                .indexFingerTip: indexTip,
                .middleFingerTip: middleTip
            ]
        )
    }
}
