import Foundation

public struct SpellEffectController: Sendable {
    public let configuration: SpellEffectControllerConfiguration

    private var lastReliableOrigin: SIMD3<Float>?
    private var originLostAt: TimeInterval?
    private var lastTimestamp: TimeInterval?

    public init(configuration: SpellEffectControllerConfiguration = .init()) {
        self.configuration = configuration
    }

    public mutating func update(
        spellState: SpellState,
        origin: SIMD3<Float>?,
        style: SpellStyle = .light,
        at timestamp: TimeInterval
    ) -> SpellEffectPresentation {
        let now = normalizedTimestamp(timestamp)

        guard shouldShowEffect(for: spellState),
              let displayedOrigin = resolvedOrigin(from: origin, at: now) else {
            if !shouldShowEffect(for: spellState) {
                clearOrigin()
            }

            return hiddenPresentation(style: style, spellState: spellState)
        }

        return SpellEffectPresentation(
            isVisible: true,
            origin: displayedOrigin,
            scale: scale(for: spellState),
            style: style,
            spellState: spellState
        )
    }

    public mutating func reset() {
        clearOrigin()
        lastTimestamp = nil
    }
}

private extension SpellEffectController {
    mutating func normalizedTimestamp(_ timestamp: TimeInterval) -> TimeInterval {
        let now = max(timestamp, lastTimestamp ?? timestamp)
        lastTimestamp = now
        return now
    }

    func shouldShowEffect(for state: SpellState) -> Bool {
        switch state {
        case .preparing, .charging, .releasing:
            true
        case .idle, .cooldown:
            false
        }
    }

    mutating func resolvedOrigin(from origin: SIMD3<Float>?, at timestamp: TimeInterval) -> SIMD3<Float>? {
        if let origin {
            lastReliableOrigin = origin
            originLostAt = nil
            return origin
        }

        guard let lastReliableOrigin else {
            return nil
        }

        if originLostAt == nil {
            originLostAt = timestamp
        }

        guard let originLostAt,
              timestamp - originLostAt <= configuration.originGraceDuration else {
            clearOrigin()
            return nil
        }

        return lastReliableOrigin
    }

    func scale(for state: SpellState) -> Float {
        switch state {
        case .preparing:
            configuration.preparingScale
        case .charging:
            configuration.chargingScale
        case .releasing:
            configuration.releasingScale
        case .idle, .cooldown:
            0
        }
    }

    func hiddenPresentation(style: SpellStyle, spellState: SpellState) -> SpellEffectPresentation {
        SpellEffectPresentation(
            isVisible: false,
            origin: nil,
            scale: 0,
            style: style,
            spellState: spellState
        )
    }

    mutating func clearOrigin() {
        lastReliableOrigin = nil
        originLostAt = nil
    }
}
