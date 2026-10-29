import AppKit
import SwiftUI

/// Place above the island fill, outside its clipShape. `outline` is in this view's SwiftUI (y-down) local space.
/// The view's frame must exceed the outline by at least `HaloStyle.glowRadius` (14 pt) on every side or the glow clips.
public struct HaloView: NSViewRepresentable {
    public var state: HaloState
    public var outline: CGPath
    public var lowPowerMode: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    public init(state: HaloState, outline: CGPath, lowPowerMode: Bool) {
        self.state = state
        self.outline = outline
        self.lowPowerMode = lowPowerMode
    }

    public func makeNSView(context: Context) -> HaloHostView { HaloHostView() }

    public func updateNSView(_ view: HaloHostView, context: Context) {
        let accessibility = HaloAccessibility(
            reduceMotion: reduceMotion, reduceTransparency: reduceTransparency,
            increaseContrast: contrast == .increased, lowPowerMode: lowPowerMode)
        view.halo.apply(
            HaloStyle.resolve(state, accessibility: accessibility), state: state, outline: outline, now: Date())
    }

    public static func dismantleNSView(_ view: HaloHostView, coordinator: ()) {
        view.halo.suspend()
    }
}

/// Layer-hosting view for `HaloLayer` that keeps its raster scale in step with the window's screen.
public final class HaloHostView: NSView {
    let halo = HaloLayer()

    init() {
        super.init(frame: .zero)
        layer = halo
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// AppKit syncs a hosted layer's geometryFlipped with the view; flipped keeps the y-down outline upright.
    public override var isFlipped: Bool { true }

    public override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        guard let window else { return }
        halo.setContentsScale(window.backingScaleFactor)
    }
}
