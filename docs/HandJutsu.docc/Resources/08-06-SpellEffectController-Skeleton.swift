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
}
