import AppKit
import Testing

@testable import IslandDesign

final class FeedbackFakePerformer: NSObject, NSHapticFeedbackPerformer {
    nonisolated(unsafe) var patterns: [NSHapticFeedbackManager.FeedbackPattern] = []
    func perform(
        _ pattern: NSHapticFeedbackManager.FeedbackPattern, performanceTime: NSHapticFeedbackManager.PerformanceTime
    ) {
        patterns.append(pattern)
    }
}

@MainActor @Suite struct SystemFeedbackPlayerTests {
    @Test func alignmentMapsToAlignmentPattern() {
        let fake = FeedbackFakePerformer()
        SystemFeedbackPlayer(performer: fake, preferences: { (true, true) }).play(.alignment)
        #expect(fake.patterns == [.alignment])
    }
    @Test func hapticsDisabledPlaysNothing() {
        let fake = FeedbackFakePerformer()
        SystemFeedbackPlayer(performer: fake, preferences: { (false, true) }).play(.levelChange)
        #expect(fake.patterns.isEmpty)
    }
    @Test func timerFinishedPlaysGlassWhenSoundsEnabled() {
        var played: [String] = []
        SystemFeedbackPlayer(
            performer: FeedbackFakePerformer(), playSound: { played.append($0) }, preferences: { (true, true) }
        ).play(.timerFinished)
        #expect(played == ["Glass"])
    }
    @Test func soundsDisabledPlaysNothing() {
        var played: [String] = []
        SystemFeedbackPlayer(
            performer: FeedbackFakePerformer(), playSound: { played.append($0) }, preferences: { (true, false) }
        ).play(.timerFinished)
        #expect(played.isEmpty)
    }
}
