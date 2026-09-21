import Foundation

public enum SpellState: String, Codable, Sendable, Equatable {
    case idle
    case preparing
    case charging
    case releasing
    case cooldown
}

public struct SpellStateMachineConfiguration: Sendable, Equatable {
    public let releaseDuration: TimeInterval
    public let cooldownDuration: TimeInterval

    public init(
        releaseDuration: TimeInterval = 0.18,
        cooldownDuration: TimeInterval = 0.5
    ) {
        self.releaseDuration = max(0, releaseDuration)
        self.cooldownDuration = max(0, cooldownDuration)
    }
}

public struct SpellStateMachineUpdate: Sendable, Equatable {
    public let state: SpellState
    public let startedCharging: Bool
    public let finishedReleasing: Bool

    public init(
        state: SpellState,
        startedCharging: Bool = false,
        finishedReleasing: Bool = false
    ) {
        self.state = state
        self.startedCharging = startedCharging
        self.finishedReleasing = finishedReleasing
    }
}
