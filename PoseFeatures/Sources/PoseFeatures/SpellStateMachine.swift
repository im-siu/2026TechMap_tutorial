import Foundation

public struct SpellStateMachine: Sendable {
    public private(set) var state: SpellState = .idle
    public let configuration: SpellStateMachineConfiguration

    private var releaseStartedAt: TimeInterval?
    private var cooldownStartedAt: TimeInterval?
    private var lastTimestamp: TimeInterval?

    public init(configuration: SpellStateMachineConfiguration = .init()) {
        self.configuration = configuration
    }

    public mutating func update(
        with gestureUpdate: GestureClassifierUpdate,
        at timestamp: TimeInterval
    ) -> SpellStateMachineUpdate {
        let now = normalizedTimestamp(timestamp)

        switch state {
        case .idle:
            if gestureUpdate.state == .candidate {
                state = .preparing
            }

        case .preparing:
            if gestureUpdate.recognitionStarted || gestureUpdate.state == .recognized {
                state = .charging
                return update(startedCharging: true)
            }

            if gestureUpdate.state == .idle || gestureUpdate.state == .cooldown {
                resetToIdle()
            }

        case .charging:
            if gestureUpdate.recognitionEnded || gestureUpdate.state == .cooldown || gestureUpdate.state == .idle {
                state = .releasing
                releaseStartedAt = now
            }

        case .releasing:
            if releaseHasElapsed(at: now) {
                state = .cooldown
                cooldownStartedAt = now
                releaseStartedAt = nil
                return update(finishedReleasing: true)
            }

        case .cooldown:
            if cooldownHasElapsed(at: now) {
                resetToIdle()
            }
        }

        return update()
    }
}

private extension SpellStateMachine {
    mutating func normalizedTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        let now = max(timestamp, lastTimestamp ?? timestamp)
        lastTimestamp = now
        return now
    }

    func releaseHasElapsed(at timestamp: TimeInterval) -> Bool {
        guard let releaseStartedAt else { return false }
        return timestamp - releaseStartedAt >= configuration.releaseDuration
    }

    func cooldownHasElapsed(at timestamp: TimeInterval) -> Bool {
        guard let cooldownStartedAt else { return false }
        return timestamp - cooldownStartedAt >= configuration.cooldownDuration
    }

    mutating func resetToIdle() {
        state = .idle
        releaseStartedAt = nil
        cooldownStartedAt = nil
    }

    func update(
        startedCharging: Bool = false,
        finishedReleasing: Bool = false
    ) -> SpellStateMachineUpdate {
        SpellStateMachineUpdate(
            state: state,
            startedCharging: startedCharging,
            finishedReleasing: finishedReleasing
        )
    }
}
