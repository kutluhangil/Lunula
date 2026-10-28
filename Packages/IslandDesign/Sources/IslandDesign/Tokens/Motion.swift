import SwiftUI

public struct MotionSpec: Equatable, Sendable {
    public var duration: Double
    public var bounce: Double

    public init(duration: Double, bounce: Double) {
        self.duration = duration
        self.bounce = bounce
    }

    public var animation: Animation { .spring(duration: duration, bounce: bounce) }
}

public enum MotionToken: CaseIterable, Sendable {
    case open, close, peek, morph, content, bud, pulse, breath

    public var spec: MotionSpec {
        switch self {
        case .open: MotionSpec(duration: 0.45, bounce: 0.10)
        case .close: MotionSpec(duration: 0.35, bounce: 0)
        case .peek: MotionSpec(duration: 0.30, bounce: 0.08)
        case .morph: MotionSpec(duration: 0.40, bounce: 0.05)
        case .content: MotionSpec(duration: 0.25, bounce: 0)
        case .bud: MotionSpec(duration: 0.55, bounce: 0)
        case .pulse: MotionSpec(duration: 0.9, bounce: 0)
        case .breath: MotionSpec(duration: 5.0, bounce: 0)
        }
    }

    /// Everything except `breath`, an ambient loop exempt from the 2 s transition limit.
    public static var transitions: [MotionToken] { allCases.filter { $0 != .breath } }

    public static func animation(_ token: MotionToken, reduceMotion: Bool) -> Animation {
        if reduceMotion { return .easeInOut(duration: 0.2) }
        switch token {
        case .content: return .smooth(duration: token.spec.duration)
        case .breath:
            // The halo breath runs on Core Animation (HaloLayer), not this; each autoreversed half is duration / 2.
            return .easeInOut(duration: token.spec.duration / 2).repeatForever(autoreverses: true)
        default: return token.spec.animation
        }
    }

    @MainActor public static let reducedTransition: AnyTransition = .opacity.combined(with: .scale(scale: 0.98))
}
