import XCTest
@testable import PoseFeatures

final class SpellStateMachineTests: XCTestCase {
    func testCandidateAndRecognitionBeginPreparingThenCharging() {
        var machine = makeMachine()

        XCTAssertEqual(machine.update(with: gesture(.candidate), at: 0).state, .preparing)

        let update = machine.update(
            with: gesture(.recognized, recognitionStarted: true),
            at: 0.3
        )

        XCTAssertEqual(update.state, .charging)
        XCTAssertTrue(update.startedCharging)
    }

    func testBriefTrackingLossKeepsTheChargingState() {
        var machine = makeMachine()
        beginCharging(&machine)

        let update = machine.update(with: gesture(.lost), at: 0.35)

        XCTAssertEqual(update.state, .charging)
        XCTAssertFalse(update.finishedReleasing)
    }

    func testRecognitionEndReleasesThenCoolsDownAndReturnsToIdle() {
        var machine = makeMachine()
        beginCharging(&machine)

        XCTAssertEqual(
            machine.update(with: gesture(.cooldown, recognitionEnded: true), at: 0.4).state,
            .releasing
        )

        let releaseUpdate = machine.update(with: gesture(.cooldown), at: 0.61)
        XCTAssertEqual(releaseUpdate.state, .cooldown)
        XCTAssertTrue(releaseUpdate.finishedReleasing)

        XCTAssertEqual(machine.update(with: gesture(.candidate), at: 0.9).state, .cooldown)
        XCTAssertEqual(machine.update(with: gesture(.candidate), at: 1.12).state, .idle)
        XCTAssertEqual(machine.update(with: gesture(.candidate), at: 1.13).state, .preparing)
    }

    private func makeMachine() -> SpellStateMachine {
        SpellStateMachine(
            configuration: SpellStateMachineConfiguration(
                releaseDuration: 0.2,
                cooldownDuration: 0.5
            )
        )
    }

    private func beginCharging(_ machine: inout SpellStateMachine) {
        _ = machine.update(with: gesture(.candidate), at: 0)
        _ = machine.update(
            with: gesture(.recognized, recognitionStarted: true),
            at: 0.3
        )
        XCTAssertEqual(machine.state, .charging)
    }

    private func gesture(
        _ state: GestureClassifierState,
        recognitionStarted: Bool = false,
        recognitionEnded: Bool = false
    ) -> GestureClassifierUpdate {
        GestureClassifierUpdate(
            state: state,
            recognitionStarted: recognitionStarted,
            recognitionEnded: recognitionEnded
        )
    }
}
