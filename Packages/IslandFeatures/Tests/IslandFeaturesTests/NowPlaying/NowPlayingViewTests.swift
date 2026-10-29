import Foundation
import IslandCore
import IslandCoreTestSupport
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct NowPlayingViewTests {
    @Test func progressFractionIsClamped() {
        #expect(NowPlayingProgress.fraction(position: 50, duration: 100) == 0.5)
        #expect(NowPlayingProgress.fraction(position: 150, duration: 100) == 1)
        #expect(NowPlayingProgress.fraction(position: 10, duration: nil) == 0)
    }

    @Test func compactAndExpandedRender() {
        let s = NowPlayingSnapshot.fixture()
        #expect(ImageRenderer(content: NowPlayingCompactLeading(snapshot: s)).cgImage != nil)
        #expect(
            ImageRenderer(content: NowPlayingExpandedCard(snapshot: s, accent: nil).frame(width: 492)).cgImage != nil)
    }

    @Test func longTurkishTitleStaysInsideCard() {
        let s = NowPlayingSnapshot.fixture(
            title: "Gönülçelen Şarkılar Antolojisi — Uzun Versiyon Özel Kayıt",
            artist: "Müzeyyen Senar & İstanbul Senfoni Orkestrası")
        let r = ImageRenderer(
            content: NowPlayingExpandedCard(snapshot: s, accent: nil).frame(width: 492)
                .environment(\.locale, Locale(identifier: "tr_TR")))
        #expect(r.cgImage?.width == Int(492 * r.scale))
    }
}
