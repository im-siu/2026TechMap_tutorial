import XCTest
@testable import PoseFeatures

final class GestureClassifierTests: XCTestCase {
    func testCandidateMustHoldBeforeRecognitionStarts() {
        var classifier = makeClassifier()

        XCTAssertEqual(classifier.update(with: .candidate, at: 0).state, .candidate)
        XCTAssertFalse(classifier.update(with: .candidate, at: 0.29).recognitionStarted)

        let update = classifier.update(with: .candidate, at: 0.3)

        XCTAssertEqual(update.state, .recognized)
        XCTAssertTrue(update.recognitionStarted)
        XCTAssertFalse(update.recognitionEnded)
    }

    func testMatchedStatusIsAlsoAcceptedAsAPoseMatch() {
        var classifier = makeClassifier()

        XCTAssertEqual(classifier.update(with: .matched, at: 0).state, .candidate)

        let update = classifier.update(with: .matched, at: 0.3)

        XCTAssertEqual(update.state, .recognized)
        XCTAssertTrue(update.recognitionStarted)
    }

    func testBriefTrackingLossReturnsToCandidateWithoutResettingHold() {
        var classifier = makeClassifier()

        _ = classifier.update(with: .candidate, at: 0)
        XCTAssertEqual(classifier.update(with: .notEvaluable, at: 0.2).state, .lost)
        XCTAssertEqual(classifier.update(with: .candidate, at: 0.25).state, .candidate)

        let update = classifier.update(with: .candidate, at: 0.31)

        XCTAssertEqual(update.state, .recognized)
        XCTAssertTrue(update.recognitionStarted)
    }

    func testBriefTrackingLossReturnsToRecognized() {
        var classifier = makeClassifier()

        recognize(&classifier)
        XCTAssertEqual(classifier.update(with: .notEvaluable, at: 0.35).state, .lost)

        let update = classifier.update(with: .candidate, at: 0.4)

        XCTAssertEqual(update.state, .recognized)
        XCTAssertFalse(update.recognitionStarted)
        XCTAssertFalse(update.recognitionEnded)
    }

    func testTrackingLossPastGraceEndsRecognitionAndStartsCooldown() {
        var classifier = makeClassifier()

        recognize(&classifier)
        _ = classifier.update(with: .notEvaluable, at: 0.35)

        let update = classifier.update(with: .notEvaluable, at: 0.46)

        XCTAssertEqual(update.state, .cooldown)
        XCTAssertTrue(update.recognitionEnded)
    }

    func testReleaseMustBeConfirmedBeforeRecognitionEnds() {
        var classifier = makeClassifier()

        recognize(&classifier)
        XCTAssertEqual(classifier.update(with: .notMatched, at: 0.35).state, .lost)

        let update = classifier.update(with: .notMatched, at: 0.41)

        XCTAssertEqual(update.state, .cooldown)
        XCTAssertTrue(update.recognitionEnded)
    }

    func testCooldownIgnoresCandidateUntilTheFollowingUpdate() {
        var classifier = makeClassifier()

        recognize(&classifier)
        _ = classifier.update(with: .notMatched, at: 0.35)
        _ = classifier.update(with: .notMatched, at: 0.41)

        XCTAssertEqual(classifier.update(with: .candidate, at: 0.9).state, .cooldown)
        XCTAssertEqual(classifier.update(with: .candidate, at: 0.91).state, .idle)
        XCTAssertEqual(classifier.update(with: .candidate, at: 0.92).state, .candidate)
    }

    private func makeClassifier() -> GestureClassifier {
        GestureClassifier(
            configuration: GestureClassifierConfiguration(
                candidateHoldDuration: 0.3,
                trackingLossGraceDuration: 0.1,
                releaseConfirmationDuration: 0.05,
                cooldownDuration: 0.5
            )
        )
    }

    private func recognize(_ classifier: inout GestureClassifier) {
        _ = classifier.update(with: .candidate, at: 0)
        _ = classifier.update(with: .candidate, at: 0.3)
        XCTAssertEqual(classifier.state, .recognized)
    }
}
