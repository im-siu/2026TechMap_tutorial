import Foundation

public struct SpellStateMachine: Sendable {
    public private(set) var state: SpellState = .idle
    public let configuration: SpellStateMachineConfiguration

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
        return update()
    }
}

private extension SpellStateMachine {
    mutating func normalizedTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        let now = max(timestamp, lastTimestamp ?? timestamp)
        lastTimestamp = now
        return now
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
