import Foundation
import IslandCore
import SwiftUI
import Testing

@testable import IslandFeatures

@MainActor @Suite struct TimerViewTests {
    @Test func quickStartOffers5_15_25() { #expect(TimerQuickStartTile.presetMinutes == [5, 15, 25]) }

    @Test func cardsRender() {
        let snap = TimerSnapshot(
            timerID: "timer", label: nil, phase: .focus, duration: 1500, endsAt: Date().addingTimeInterval(600),
            pausedRemaining: nil, cycle: 1, totalCycles: 4)
        #expect(ImageRenderer(content: TimerExpandedCard(snapshot: snap).frame(width: 492)).cgImage != nil)
        #expect(ImageRenderer(content: TimerCompactTrailing(snapshot: snap)).cgImage != nil)
    }
}
