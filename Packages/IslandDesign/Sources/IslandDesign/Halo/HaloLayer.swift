import Foundation
import IslandCore
import QuartzCore

/// Glow outside the outline, an inner key line and a progress stroke. All animation runs on the render server.
/// The outline is in the view's SwiftUI (y-down) local space; the layer's geometry is flipped to match.
@MainActor
public final class HaloLayer: CALayer {
    // CALayer's overridden inits are nonisolated; these are only mutated from the MainActor.
    nonisolated(unsafe) let glow = CALayer()
    nonisolated(unsafe) private let glowMask = CAShapeLayer()
    nonisolated(unsafe) let keyLine = CAShapeLayer()
    nonisolated(unsafe) private let keyLineMask = CAShapeLayer()
    nonisolated(unsafe) let progress = CAShapeLayer()
    nonisolated(unsafe) private var lastApplied: Applied?

    private struct Applied: Equatable {
        var values: HaloStyleValues
        var state: HaloState
        var outline: CGPath
    }

    public override init() {
        super.init()
        isGeometryFlipped = true
        glow.shadowOffset = .zero
        glow.shadowRadius = HaloStyle.glowRadius
        // Even-odd over (canvas + outline) keeps the glow outside, so it never tints the #000000 core.
        glowMask.fillRule = .evenOdd
        glow.mask = glowMask
        keyLine.mask = keyLineMask
        addSublayer(glow)
        for shape in [keyLine, progress] {
            shape.fillColor = nil
            shape.lineCap = .round
            addSublayer(shape)
        }
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Layers created in code under a layer-hosting view stay at 1× unless told the screen's scale.
    public func setContentsScale(_ scale: CGFloat) {
        for layer in [self, glow, glowMask, keyLine, keyLineMask, progress] { layer.contentsScale = scale }
    }

    /// Idempotent: SwiftUI re-applies on every parent update, which must not restart a breath or re-flash a pulse.
    public func apply(_ values: HaloStyleValues, state: HaloState, outline: CGPath, now: Date) {
        let next = Applied(values: values, state: state, outline: outline)
        guard next != lastApplied else { return }
        suspend()
        lastApplied = next
        let accent = CGColor(
            red: state.color.red, green: state.color.green, blue: state.color.blue, alpha: state.color.alpha)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Bounds origin at the canvas origin keeps the glow's coordinates identical to this layer's.
        let canvas = outline.boundingBoxOfPath.insetBy(dx: -3 * values.glowRadius, dy: -3 * values.glowRadius)
        glow.bounds = canvas
        glow.position = CGPoint(x: canvas.midX, y: canvas.midY)
        glow.shadowPath = outline
        glow.shadowRadius = values.glowRadius
        glow.shadowColor = accent
        // A pulse rests dark and flashes through its keyframes.
        glow.shadowOpacity = values.pulses ? 0 : Float(values.glowOpacity)
        let outside = CGMutablePath()
        outside.addRect(canvas)
        outside.addPath(outline)
        glowMask.path = outside

        keyLine.path = outline
        keyLineMask.path = outline
        keyLine.strokeColor = accent
        // The mask clips the outer half of the centred stroke, leaving an inner line of keyLineWidth.
        keyLine.lineWidth = values.keyLineWidth * 2
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
            glow.add(breath, forKey: "lunula.breath")
        }
        if values.pulses {
            let pulse = CAKeyframeAnimation(keyPath: "shadowOpacity")
            pulse.values = [0, Float(values.glowOpacity), 0]
            pulse.keyTimes = [0, 0.35, 1]
            pulse.duration = 0.9
            glow.add(pulse, forKey: "lunula.pulse")
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
        lastApplied = nil
        for layer in [self, glow, keyLine, progress] { layer.removeAllAnimations() }
    }

    private func clamp(_ x: Double) -> CGFloat { CGFloat(min(max(x, 0), 1)) }
}
