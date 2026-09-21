import Foundation

public struct SpellEffectColor: Sendable, Equatable {
    public let red: Float
    public let green: Float
    public let blue: Float

    public init(red: Float, green: Float, blue: Float) {
        self.red = min(max(0, red), 1)
        self.green = min(max(0, green), 1)
        self.blue = min(max(0, blue), 1)
    }
}

public enum SpellStyle: String, CaseIterable, Codable, Sendable {
    case light
    case fire
    case water

    public var color: SpellEffectColor {
        switch self {
        case .light:
            SpellEffectColor(red: 0.78, green: 0.68, blue: 1)
        case .fire:
            SpellEffectColor(red: 1, green: 0.3, blue: 0.08)
        case .water:
            SpellEffectColor(red: 0.08, green: 0.7, blue: 1)
        }
    }
}

public struct SpellEffectControllerConfiguration: Sendable, Equatable {
    public let originGraceDuration: TimeInterval
    public let preparingScale: Float
    public let chargingScale: Float
    public let releasingScale: Float

    public init(
        originGraceDuration: TimeInterval = 0.1,
        preparingScale: Float = 0.035,
        chargingScale: Float = 0.08,
        releasingScale: Float = 0.12
    ) {
        self.originGraceDuration = max(0, originGraceDuration)
        self.preparingScale = max(0, preparingScale)
        self.chargingScale = max(0, chargingScale)
        self.releasingScale = max(0, releasingScale)
    }
}

public struct SpellEffectPresentation: Sendable, Equatable {
    public let isVisible: Bool
    public let origin: SIMD3<Float>?
    public let scale: Float
    public let style: SpellStyle
    public let spellState: SpellState

    public init(
        isVisible: Bool,
        origin: SIMD3<Float>?,
        scale: Float,
        style: SpellStyle,
        spellState: SpellState
    ) {
        self.isVisible = isVisible
        self.origin = origin
        self.scale = scale
        self.style = style
        self.spellState = spellState
    }
}
