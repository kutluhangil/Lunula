import Foundation
import IslandCoreTestSupport
import Testing

@testable import IslandCore

private func run(_ s: IslandState, _ events: IslandEvent...) -> IslandTransition {
    var transition = IslandTransition(state: s, effects: [])
    for e in events { transition = IslandReducer.reduce(transition.state, e) }
    return transition
}

@Suite struct IslandReducerTests {
    var compactState: IslandState {
        var s = IslandState()
        s.layout = .init(primary: .fixture(), detached: [], overflowCount: 0)
        s.phase = .compact
        return s
    }

    @Test func hoverDwellOpensPeek() {
        let entered = IslandReducer.reduce(IslandState(), .pointerEnteredHotZone)
        #expect(Set(entered.effects) == [.schedule(.dwell, after: 0.1)])
        let t = IslandReducer.reduce(entered.state, .pointerDwellElapsed(speed: 300))
        #expect(t.state.phase == .peek && Set(t.effects) == [.setMouseEventsIgnored(false)])
    }
    @Test func fastPointerDoesNotPeek() {
        let t = run(IslandState(), .pointerEnteredHotZone, .pointerDwellElapsed(speed: 1500))
        #expect(t.state.phase == .idle && Set(t.effects) == [.schedule(.dwell, after: 0.1)])
    }
    @Test func dwellAfterPointerLeftIsIgnored() {
        #expect(
            run(IslandState(), .pointerEnteredHotZone, .pointerExitedIsland, .pointerDwellElapsed(speed: 100))
                .state.phase == .idle)
    }
    @Test func exitGraceCollapsesAfter250ms() {
        let exited = run(IslandState(), .pointerEnteredHotZone, .pointerDwellElapsed(speed: 0), .pointerExitedIsland)
        #expect(Set(exited.effects) == [.schedule(.exitGrace, after: 0.25)])
        let t = IslandReducer.reduce(exited.state, .exitGraceElapsed)
        #expect(t.state.phase == .idle && Set(t.effects) == [.setMouseEventsIgnored(true), .makePanelKey(false)])
    }
    @Test func reenterDuringExitGraceKeepsOpen() {
        let t = run(
            IslandState(), .pointerEnteredHotZone, .pointerDwellElapsed(speed: 0), .pointerExitedIsland,
            .pointerEnteredHotZone)
        #expect(Set(t.effects) == [.cancel(.exitGrace)])
        #expect(IslandReducer.reduce(t.state, .exitGraceElapsed).state.phase == .peek)
    }
    @Test func clickFromCompactExpandsHomeWithHaptic() {
        let t = IslandReducer.reduce(compactState, .clicked(.island))
        #expect(t.state.phase == .expanded(.home))
        #expect(Set(t.effects).isSuperset(of: [.playHaptic(.alignment), .setMouseEventsIgnored(false)]))
    }
    @Test func clickOnBubbleOpensThatActivity() {
        #expect(IslandReducer.reduce(compactState, .clicked(.bubble("b"))).state.phase == .expanded(.activity("b")))
    }
    @Test func escapeCollapsesToCompactWhenActivityExists() {
        #expect(run(compactState, .clicked(.island), .escapePressed).state.phase == .compact)
    }
    @Test func escapeCollapsesToIdleWhenNoActivity() {
        #expect(run(IslandState(), .toggleRequested, .escapePressed).state.phase == .idle)
    }
    @Test func fileDragOpensShelfAndLeavingCollapses() {
        let opened = IslandReducer.reduce(IslandState(), .fileDragApproached)
        #expect(opened.state.phase == .expanded(.shelf))
        #expect(IslandReducer.reduce(opened.state, .fileDragLeft).state.phase == .idle)
    }
    @Test func alertWhileExpandedIsQueuedAndShownOnCollapse() {
        let a = TransientAlert.fixture(kind: .charging, duration: 2.6)
        let queued = run(IslandState(), .toggleRequested, .alertRaised(a))
        #expect(queued.state.phase == .expanded(.home) && queued.state.pendingAlerts == [a])
        let t = IslandReducer.reduce(queued.state, .escapePressed)
        #expect(t.state.phase == .transient(a) && Set(t.effects).contains(.schedule(.alertExpiry, after: 2.6)))
    }
    @Test func higherPriorityAlertPreemptsCurrent() {
        let low = TransientAlert.fixture(priority: .normal)
        let high = TransientAlert.fixture(priority: .critical)
        let t = run(IslandState(), .alertRaised(low), .alertRaised(high))
        #expect(t.state.phase == .transient(high) && t.state.pendingAlerts == [low])
    }
    @Test func alertQueueKeepsAtMostThree() {
        let alerts = (0..<5).map { _ in TransientAlert.fixture(priority: .normal) }
        var s = IslandReducer.reduce(IslandState(), .toggleRequested).state
        for a in alerts { s = IslandReducer.reduce(s, .alertRaised(a)).state }
        #expect(s.pendingAlerts == Array(alerts.suffix(3)))
    }
    @Test func timerFinishedAlertPlaysSound() {
        let t = IslandReducer.reduce(IslandState(), .alertRaised(.fixture(kind: .timerFinished, priority: .critical)))
        #expect(Set(t.effects).contains(.playSound(.timerFinished)))
    }
    @Test func fullscreenHidesIsland() {
        let t = IslandReducer.reduce(compactState, .fullscreenChanged(true))
        #expect(t.state.phase == .hidden && Set(t.effects).contains(.setMouseEventsIgnored(true)))
        #expect(IslandReducer.reduce(t.state, .fullscreenChanged(false)).state.phase == .compact)
    }
    @Test func criticalAlertShowsInFullscreenFor2Seconds() {
        let hidden = IslandReducer.reduce(IslandState(), .fullscreenChanged(true)).state
        let t = IslandReducer.reduce(hidden, .alertRaised(.fixture(duration: 6, priority: .critical)))
        #expect(Set(t.effects).contains(.schedule(.alertExpiry, after: 2.0)))
        #expect(IslandReducer.reduce(t.state, .alertExpired).state.phase == .hidden)
    }
    @Test func nonCriticalAlertDroppedInFullscreen() {
        let hidden = IslandReducer.reduce(IslandState(), .fullscreenChanged(true)).state
        #expect(IslandReducer.reduce(hidden, .alertRaised(.fixture(priority: .normal))).state.phase == .hidden)
    }
    @Test func activitiesChangedMovesIdleToCompactAndBack() {
        let layout = IslandLayout(primary: .fixture(), detached: [], overflowCount: 0)
        let s = IslandReducer.reduce(IslandState(), .activitiesChanged(layout)).state
        #expect(s.phase == .compact)
        #expect(IslandReducer.reduce(s, .activitiesChanged(.empty)).state.phase == .idle)
    }
    @Test func removedActivityPageFallsBackToHome() {
        let s = IslandReducer.reduce(compactState, .clicked(.bubble("gone"))).state
        #expect(IslandReducer.reduce(s, .activitiesChanged(.empty)).state.phase == .expanded(.home))
    }
    @Test func sleepCollapsesAndCancelsAllTimers() {
        let t = run(compactState, .clicked(.island), .systemWillSleep)
        #expect(t.state.phase == .compact)
        #expect(Set(t.effects).isSuperset(of: [.cancel(.dwell), .cancel(.exitGrace), .cancel(.alertExpiry)]))
    }
    @Test func wakeShowsAlertQueuedDuringSleep() {
        let a = TransientAlert.fixture(kind: .timerFinished, priority: .critical)
        let t = run(IslandState(), .toggleRequested, .alertRaised(a), .systemWillSleep, .systemDidWake)
        #expect(t.state.phase == .transient(a))
    }
    @Test func toggleOpensWithKeyFocusAndClosesWhenOpen() {
        let opened = IslandReducer.reduce(IslandState(), .toggleRequested)
        #expect(opened.state.phase == .expanded(.home) && Set(opened.effects).contains(.makePanelKey(true)))
        #expect(IslandReducer.reduce(opened.state, .toggleRequested).state.phase == .idle)
    }
    @Test func queuedNormalAlertStaysQueuedInFullscreen() {
        let normal = TransientAlert.fixture(priority: .normal)
        let t = run(
            IslandState(), .toggleRequested, .alertRaised(normal), .fullscreenChanged(true),
            .alertRaised(.fixture(priority: .critical)), .alertExpired)
        #expect(t.state.phase == .hidden && t.state.pendingAlerts == [normal])
        let after = IslandReducer.reduce(t.state, .fullscreenChanged(false))
        #expect(after.state.phase == .transient(normal))
    }
    @Test func pointerExitDuringAlertClearsInside() {
        let t = run(IslandState(), .alertRaised(.fixture()), .pointerEnteredHotZone, .pointerExitedIsland)
        #expect(!t.state.pointerInside)
    }
    @Test func fullscreenExitDuringCriticalAlertRestoresIsland() {
        let t = run(
            compactState, .fullscreenChanged(true), .alertRaised(.fixture(priority: .critical)),
            .fullscreenChanged(false))
        #expect(!t.state.isFullscreen)
        guard case .transient = t.state.phase else {
            Issue.record("expected transient, got \(t.state.phase)")
            return
        }
        #expect(IslandReducer.reduce(t.state, .alertExpired).state.phase == .compact)
    }
    @Test func enablingHideWhileFullscreenHides() {
        var s = IslandState()
        s.options.hideInFullscreen = false
        let fs = IslandReducer.reduce(s, .fullscreenChanged(true)).state
        #expect(fs.phase == .idle && fs.isFullscreen)
        #expect(IslandReducer.reduce(fs, .optionsChanged(IslandOptions())).state.phase == .hidden)
    }
}
