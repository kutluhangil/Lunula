import Foundation
import IslandCore
import QuartzCore

/// Glow (shadow along the outline), a key line and a progress stroke. All animation runs on the render server.
@MainActor
public final class HaloLayer: CALayer {
    nonisolated(unsafe) private let keyLine = CAShapeLayer()
    nonisolated(unsafe) private let progress = CAShapeLayer()

    public override init() {
        super.init()
        for shape in [keyLine, progress] {
            shape.fillColor = nil
            shape.lineCap = .round
            addSublayer(shape)
        }
        shadowOffset = .zero
        shadowRadius = HaloStyle.glowRadius
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public func apply(_ values: HaloStyleValues, state: HaloState, outline: CGPath, now: Date) {
        suspend()
        let accent = CGColor(
            red: state.color.red, green: state.color.green, blue: state.color.blue, alpha: state.color.alpha)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shadowPath = outline
        shadowRadius = values.glowRadius
        shadowOffset = .zero
        shadowColor = accent
        // A pulse rests dark and flashes through its keyframes.
        shadowOpacity = values.pulses ? 0 : Float(values.glowOpacity)

        keyLine.path = outline
        keyLine.strokeColor = accent
        keyLine.lineWidth = values.keyLineWidth
        keyLine.opacity = Float(values.keyLineOpacity)

        progress.path = outline
        progress.strokeColor = accent
        progress.lineWidth = values.keyLineWidth * 2
        progress.strokeStart = 0
        switch state.mode {
        case .progress(let fraction, let endsAt):
            progress.opacity = 1
            progress.strokeEnd = endsAt == nil ? clamp(fraction) : 1
        case .warming(let fraction), .fill(let fraction):
            progress.opacity = 1
            progress.strokeEnd = clamp(fraction)
        default:
            progress.opacity = 0
            progress.strokeEnd = 0
        }
        CATransaction.commit()

        if values.breathes {
            let breath = CABasicAnimation(keyPath: "shadowOpacity")
            breath.fromValue = Float(values.glowOpacity * 0.6)
            breath.toValue = Float(values.glowOpacity)
            breath.duration = 2.5
            breath.autoreverses = true
            breath.repeatCount = .infinity
            breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            add(breath, forKey: "lunula.breath")
        }
        if values.pulses {
            let pulse = CAKeyframeAnimation(keyPath: "shadowOpacity")
            pulse.values = [0, Float(values.glowOpacity), 0]
            pulse.keyTimes = [0, 0.35, 1]
            pulse.duration = 0.9
            add(pulse, forKey: "lunula.pulse")
        }
        if case .progress(let fraction, let endsAt?) = state.mode, endsAt.timeIntervalSince(now) > 0 {
            let sweep = CABasicAnimation(keyPath: "strokeEnd")
            sweep.fromValue = clamp(fraction)
            sweep.toValue = 1
            sweep.duration = endsAt.timeIntervalSince(now)
            sweep.timingFunction = CAMediaTimingFunction(name: .linear)
            progress.add(sweep, forKey: "lunula.progress")
        }
    }

    /// Hidden islands must not animate.
    public func suspend() {
        removeAllAnimations()
        keyLine.removeAllAnimations()
        progress.removeAllAnimations()
    }

    private func clamp(_ x: Double) -> CGFloat { CGFloat(min(max(x, 0), 1)) }
}
