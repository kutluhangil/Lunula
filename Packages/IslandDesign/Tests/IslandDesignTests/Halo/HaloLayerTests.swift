import Foundation
import IslandCore
import QuartzCore
import Testing

@testable import IslandDesign

@MainActor @Suite struct HaloLayerTests {
    let outline = CGPath(rect: CGRect(x: 0, y: 0, width: 200, height: 40), transform: nil)
    func applied(_ s: HaloState, _ a: HaloAccessibility = .standard) -> HaloLayer {
        let l = HaloLayer()
        l.apply(HaloStyle.resolve(s, accessibility: a), state: s, outline: outline, now: Date())
        return l
    }
    /// Searches the whole layer tree, so tests do not depend on which sublayer carries the glow.
    func animation(_ key: String, in layer: CALayer) -> CAAnimation? {
        layer.animation(forKey: key) ?? layer.sublayers?.lazy.compactMap { animation(key, in: $0) }.first
    }
    func allAnimationKeys(_ layer: CALayer) -> [String] {
        (layer.animationKeys() ?? []) + (layer.sublayers ?? []).flatMap { allAnimationKeys($0) }
    }
    @Test func breathingAddsBreathAnimation() {
        #expect(animation("lunula.breath", in: applied(.init(mode: .ambient(breathing: true), color: .white))) != nil)
    }
    @Test func pulseAddsPulseAnimation() {
        #expect(animation("lunula.pulse", in: applied(.init(mode: .pulse, color: .white))) != nil)
    }
    @Test func reduceMotionAddsNoAnimations() {
        var a = HaloAccessibility.standard
        a.reduceMotion = true
        #expect(allAnimationKeys(applied(.init(mode: .ambient(breathing: true), color: .white), a)).isEmpty)
    }
    @Test func progressWithEndDateAnimatesStrokeEnd() {
        let l = applied(.init(mode: .progress(fraction: 0.2, endsAt: Date().addingTimeInterval(60)), color: .white))
        #expect(l.sublayers?.contains { $0.animation(forKey: "lunula.progress") != nil } == true)
    }
    @Test func suspendRemovesAllAnimations() {
        let l = applied(.init(mode: .ambient(breathing: true), color: .white))
        l.suspend()
        #expect(allAnimationKeys(l).isEmpty)
    }
    @Test(arguments: [
        ("lunula.breath", HaloMode.ambient(breathing: true)), ("lunula.pulse", HaloMode.pulse),
    ])
    func reapplyingSameStateDoesNotRestartAnimation(key: String, mode: HaloMode) throws {
        let s = HaloState(mode: mode, color: .white)
        let l = applied(s)
        let first = try #require(animation(key, in: l))
        // A new but equal path, as SwiftUI rebuilds it on every update.
        let samePath = try #require(outline.mutableCopy())
        l.apply(HaloStyle.resolve(s, accessibility: .standard), state: s, outline: samePath, now: Date())
        #expect(animation(key, in: l) === first)
    }
    @Test func reapplyingAfterSuspendRestartsAnimation() {
        let s = HaloState(mode: .ambient(breathing: true), color: .white)
        let l = applied(s)
        l.suspend()
        l.apply(HaloStyle.resolve(s, accessibility: .standard), state: s, outline: outline, now: Date())
        #expect(animation("lunula.breath", in: l) != nil)
    }
}
