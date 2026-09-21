import Foundation

public struct GestureClassifier: Sendable {
    public private(set) var state: GestureClassifierState = .idle
    public let configuration: GestureClassifierConfiguration

    private var candidateStartedAt: TimeInterval?
    private var lossStartedAt: TimeInterval?
    private var stateBeforeLoss: GestureClassifierState?
    private var lossIsReleaseConfirmation = false
    private var lastTimestamp: TimeInterval?

    public init(configuration: GestureClassifierConfiguration = .init()) {
        self.configuration = configuration
    }

    public mutating func update(
        with evaluationStatus: PoseEvaluationStatus,
        at timestamp: TimeInterval
    ) -> GestureClassifierUpdate {
        let now = normalizedTimestamp(timestamp)

        switch state {
        case .idle:
            guard evaluationStatus == .candidate || evaluationStatus == .matched else {
                return update()
            }

            state = .candidate
            candidateStartedAt = now

        case .candidate:
            switch evaluationStatus {
            case .candidate, .matched:
                if hasCandidateHoldElapsed(at: now) {
                    state = .recognized
                    return update(recognitionStarted: true)
                }

            case .notEvaluable:
                beginLoss(from: .candidate, at: now, isReleaseConfirmation: false)

            case .notMatched:
                resetToIdle()
            }

        case .recognized:
            switch evaluationStatus {
            case .candidate, .matched:
                break

            case .notEvaluable:
                beginLoss(from: .recognized, at: now, isReleaseConfirmation: false)

            case .notMatched:
                beginLoss(from: .recognized, at: now, isReleaseConfirmation: true)
            }

        case .lost:
            return updateLoss(with: evaluationStatus, at: now)

        return update()
    }
}

private extension GestureClassifier {
    mutating func normalizedTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        let now = max(timestamp, lastTimestamp ?? timestamp)
        lastTimestamp = now
        return now
    }

    mutating func beginLoss(
        from previousState: GestureClassifierState,
        at timestamp: TimeInterval,
        isReleaseConfirmation: Bool
    ) {
        state = .lost
        stateBeforeLoss = previousState
        lossStartedAt = timestamp
        lossIsReleaseConfirmation = isReleaseConfirmation
    }

    mutating func updateLoss(
        with evaluationStatus: PoseEvaluationStatus,
        at timestamp: TimeInterval
    ) -> GestureClassifierUpdate {
        guard let previousState = stateBeforeLoss else {
            resetToIdle()
            return update()
        }

        switch evaluationStatus {
        case .candidate, .matched:
            let graceDuration = lossIsReleaseConfirmation
                ? configuration.releaseConfirmationDuration
                : configuration.trackingLossGraceDuration

            if lossHasElapsed(graceDuration, at: timestamp) {
                if previousState == .recognized {
                    enterCooldown(at: timestamp)
                    return update(recognitionEnded: true)
                }

                resetToIdle()
                return update()
            }

            clearLoss()

            if previousState == .recognized {
                state = .recognized
                return update()
            }

            state = .candidate
            if hasCandidateHoldElapsed(at: timestamp) {
                state = .recognized
                return update(recognitionStarted: true)
            }

            return update()

        case .notMatched:
            if previousState == .candidate {
                resetToIdle()
                return update()
            }

            if !lossIsReleaseConfirmation {
                lossStartedAt = timestamp
                lossIsReleaseConfirmation = true
            }

            if lossHasElapsed(configuration.releaseConfirmationDuration, at: timestamp) {
                enterCooldown(at: timestamp)
                return update(recognitionEnded: true)
            }

        case .notEvaluable:
            let graceDuration = lossIsReleaseConfirmation
                ? configuration.releaseConfirmationDuration
                : configuration.trackingLossGraceDuration

            if lossHasElapsed(graceDuration, at: timestamp) {
                if previousState == .recognized {
                    enterCooldown(at: timestamp)
                    return update(recognitionEnded: true)
                }

                resetToIdle()
            }
        }

        return update()
    }

    func hasCandidateHoldElapsed(at timestamp: TimeInterval) -> Bool {
        guard let candidateStartedAt else { return false }
        return timestamp - candidateStartedAt >= configuration.candidateHoldDuration
    }

    func lossHasElapsed(_ duration: TimeInterval, at timestamp: TimeInterval) -> Bool {
        guard let lossStartedAt else { return false }
        return timestamp - lossStartedAt >= duration
    }
    func update(
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
