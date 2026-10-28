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
    @Test func breathingAddsBreathAnimation() {
        #expect(
            applied(.init(mode: .ambient(breathing: true), color: .white)).animation(forKey: "lunula.breath") != nil)
    }
    @Test func reduceMotionAddsNoAnimations() {
        var a = HaloAccessibility.standard
        a.reduceMotion = true
        #expect((applied(.init(mode: .ambient(breathing: true), color: .white), a).animationKeys() ?? []).isEmpty)
    }
    @Test func progressWithEndDateAnimatesStrokeEnd() {
        let l = applied(.init(mode: .progress(fraction: 0.2, endsAt: Date().addingTimeInterval(60)), color: .white))
        #expect(l.sublayers?.contains { $0.animation(forKey: "lunula.progress") != nil } == true)
    }
    @Test func suspendRemovesAllAnimations() {
        let l = applied(.init(mode: .ambient(breathing: true), color: .white))
        l.suspend()
        #expect(
            (l.animationKeys() ?? []).isEmpty && (l.sublayers ?? []).allSatisfy { ($0.animationKeys() ?? []).isEmpty })
    }
}
