import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandFeatures

@MainActor @Suite struct IslandStoreTests {
    let time = ManualTime()
    let panel = FakePanel()
    let feedback = FakeFeedback()

    func store(speed: Double = 100) -> IslandStore {
        IslandStore(time: time, panel: panel, feedback: feedback, speed: { speed })
    }

    @Test func sendAppliesReducerState() {
        let s = store()
        s.send(.toggleRequested)
        #expect(s.state.phase == .expanded(.home))
    }

    @Test func dwellTimerFiresWithMeasuredSpeed() {
        let s = store()
        s.send(.pointerEnteredHotZone)
        time.advance(by: 0.1)
        #expect(s.state.phase == .peek)
    }

    @Test func fastPointerReschedulesDwell() {
        let s = store(speed: 2000)
        s.send(.pointerEnteredHotZone)
        time.advance(by: 0.35)
        #expect(s.state.phase == .idle)
    }

    @Test func reschedulingSameTimerReplacesPrevious() {
        let s = store()
        s.send(.pointerEnteredHotZone)
        time.advance(by: 0.05)
        s.send(.pointerExitedIsland)
        s.send(.pointerEnteredHotZone)
        time.advance(by: 0.06)
        #expect(s.state.phase == .idle)  // first dwell was cancelled
        time.advance(by: 0.05)
        #expect(s.state.phase == .peek)
    }

    @Test func exitGraceCollapsesAfterTimer() {
        let s = store()
        s.send(.toggleRequested)
        s.send(.pointerEnteredHotZone)
        s.send(.pointerExitedIsland)
        time.advance(by: 0.25)
        #expect(s.state.phase == .idle)
    }

    @Test func panelReceivesMouseAndKeyChanges() {
        let s = store()
        s.send(.toggleRequested)
        #expect(panel.ignoredHistory.last == false && panel.keyHistory.last == true)
    }

    @Test func hapticsForwardedToFeedbackPlayer() {
        let s = store()
        s.send(.clicked(.island))
        #expect(feedback.haptics == [.alignment])
    }
}
