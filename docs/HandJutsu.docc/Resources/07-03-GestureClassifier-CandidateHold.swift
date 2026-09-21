import Foundation

public struct GestureClassifier: Sendable {
    public private(set) var state: GestureClassifierState = .idle
    public let configuration: GestureClassifierConfiguration

    private var candidateStartedAt: TimeInterval?
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

            }
        return update()
    }
}

private extension GestureClassifier {
    mutating func normalizedTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        let now = max(timestamp, lastTimestamp ?? timestamp)
        lastTimestamp = now
        return now
    }
    func hasCandidateHoldElapsed(at timestamp: TimeInterval) -> Bool {
        guard let candidateStartedAt else { return false }
        return timestamp - candidateStartedAt >= configuration.candidateHoldDuration
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
