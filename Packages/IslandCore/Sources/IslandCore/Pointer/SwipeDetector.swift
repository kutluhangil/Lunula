import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

public enum ScrollPhase: Sendable { case began, changed, ended, none }
public enum SwipeDirection: Sendable { case up, down }

/// Two-finger swipe recognizer: at most one swipe per gesture, momentum ignored.
public struct SwipeDetector: Sendable {
    private let threshold: CGFloat
    private var accumulated: CGFloat = 0
    private var fired = false

    public init(threshold: CGFloat = 24) {
        self.threshold = threshold
    }

    /// "Fingers down" is `.down`; `inverted` (natural scrolling) flips the raw delta sign.
    public mutating func feed(deltaY: CGFloat, phase: ScrollPhase, isMomentum: Bool, inverted: Bool) -> SwipeDirection?
    {
        guard !isMomentum else { return nil }
        switch phase {
        case .ended:
            accumulated = 0
            fired = false
            return nil
        case .began:
            accumulated = 0
            fired = false
        case .changed, .none:
            break
        }
        guard !fired else { return nil }
        accumulated += inverted ? deltaY : -deltaY
        if accumulated >= threshold {
            fired = true
            return .down
        }
        if accumulated <= -threshold {
            fired = true
            return .up
        }
        return nil
    }
}
