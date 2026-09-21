import Foundation

public enum GestureClassifierState: String, Codable, Sendable, Equatable {
    case idle
    case candidate
    case recognized
    case lost
    case cooldown
}

public struct GestureClassifierConfiguration: Sendable, Equatable {
    public let candidateHoldDuration: TimeInterval
    public let trackingLossGraceDuration: TimeInterval
    public let releaseConfirmationDuration: TimeInterval
    public let cooldownDuration: TimeInterval

    public init(
        candidateHoldDuration: TimeInterval = 0.3,
        trackingLossGraceDuration: TimeInterval = 0.1,
        releaseConfirmationDuration: TimeInterval = 0.05,
        cooldownDuration: TimeInterval = 0.5
    ) {
        self.candidateHoldDuration = max(0, candidateHoldDuration)
        self.trackingLossGraceDuration = max(0, trackingLossGraceDuration)
        self.releaseConfirmationDuration = max(0, releaseConfirmationDuration)
        self.cooldownDuration = max(0, cooldownDuration)
    }
}

public struct GestureClassifierUpdate: Sendable, Equatable {
    public let state: GestureClassifierState
    public let recognitionStarted: Bool
    public let recognitionEnded: Bool

    public init(
        state: GestureClassifierState,
        recognitionStarted: Bool = false,
        recognitionEnded: Bool = false
    ) {
        self.state = state
        self.recognitionStarted = recognitionStarted
        self.recognitionEnded = recognitionEnded
    }
}
