import AppKit
import SwiftUI

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

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.layer = HaloLayer()
        view.wantsLayer = true
        return view
    }

    public func updateNSView(_ view: NSView, context: Context) {
        guard let layer = view.layer as? HaloLayer else { return }
        let accessibility = HaloAccessibility(
            reduceMotion: reduceMotion, reduceTransparency: reduceTransparency,
            increaseContrast: contrast == .increased, lowPowerMode: lowPowerMode)
        layer.apply(HaloStyle.resolve(state, accessibility: accessibility), state: state, outline: outline, now: Date())
    }

    public static func dismantleNSView(_ view: NSView, coordinator: ()) {
        (view.layer as? HaloLayer)?.suspend()
    }
}
