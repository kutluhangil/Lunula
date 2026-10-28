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
    @Test func timingsComeFromMotionTokens() throws {
        let breath = try #require(
            animation("lunula.breath", in: applied(.init(mode: .ambient(breathing: true), color: .white))))
        #expect(breath.duration == MotionToken.breath.spec.duration / 2 && breath.autoreverses)
        let pulse = try #require(animation("lunula.pulse", in: applied(.init(mode: .pulse, color: .white))))
        #expect(pulse.duration == MotionToken.pulse.spec.duration)
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
    @Test func warmingDrawsNoProgressStrokeAndUsesResolvedColour() throws {
        let s = HaloState(mode: .warming(fraction: 1), color: .white)
        let l = applied(s)
        #expect(l.progress.opacity == 0)
        let warm = HaloStyle.resolve(s, accessibility: .standard).color
        let expected = [warm.red, warm.green, warm.blue, warm.alpha].map { CGFloat($0) }
        #expect(l.glow.shadowColor?.components == expected)
        #expect(l.keyLine.strokeColor?.components == expected)
    }
    @Test func outlineIsInSwiftUIYDownSpace() {
        #expect(HaloLayer().isGeometryFlipped)
    }
    @Test func glowIsMaskedToOutsideOfOutline() throws {
        let l = applied(.init(mode: .ambient(breathing: false), color: .white))
        #expect(l.shadowOpacity == 0)  // the root casts no shadow into the #000000 core
        #expect(l.glow.shadowOpacity > 0)
        let mask = try #require(l.glow.mask as? CAShapeLayer)
        let path = try #require(mask.path)
        #expect(mask.fillRule == .evenOdd)
        #expect(path.contains(CGPoint(x: 100, y: -5), using: .evenOdd))  // glow band outside the island
        #expect(path.contains(CGPoint(x: 100, y: 40 + HaloStyle.glowRadius), using: .evenOdd))
        #expect(!path.contains(CGPoint(x: 100, y: 20), using: .evenOdd))  // island core
    }
    @Test(arguments: [false, true])
    func keyLineIsAnInnerLineClippedToOutline(increaseContrast: Bool) throws {
        var a = HaloAccessibility.standard
        a.increaseContrast = increaseContrast
        let s = HaloState(mode: .ambient(breathing: false), color: .white)
        let l = applied(s, a)
        // Half of a centred stroke falls outside the clip, so the visible inner width is lineWidth / 2.
        #expect(l.keyLine.lineWidth == 2 * HaloStyle.resolve(s, accessibility: a).keyLineWidth)
        let mask = try #require(l.keyLine.mask as? CAShapeLayer)
        #expect(mask.path == outline)
    }
    @Test func contentsScaleReachesEverySublayerAndMask() {
        let l = applied(.init(mode: .ambient(breathing: false), color: .white))
        l.setContentsScale(2)
        func tree(_ layer: CALayer) -> [CALayer] {
            [layer] + (layer.mask.map(tree) ?? []) + (layer.sublayers ?? []).flatMap(tree)
        }
        #expect(tree(l).count == 6)
        #expect(tree(l).allSatisfy { $0.contentsScale == 2 })
    }
    @Test func reapplyingAfterSuspendRestartsAnimation() {
        let s = HaloState(mode: .ambient(breathing: true), color: .white)
        let l = applied(s)
        l.suspend()
        l.apply(HaloStyle.resolve(s, accessibility: .standard), state: s, outline: outline, now: Date())
        #expect(animation("lunula.breath", in: l) != nil)
    }
}
