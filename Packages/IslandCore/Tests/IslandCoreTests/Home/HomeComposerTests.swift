import Foundation
import Testing

@testable import IslandCore

@Suite struct HomeComposerTests {
    var base: HomeInputs {
        HomeInputs(
            pendingPermission: nil, hasNowPlaying: false, hasImminentMeeting: false, hasRunningTimer: false,
            hasWeather: false, hasUpcomingEvent: false, calendarAccessUndetermined: false)
    }

    @Test func heroOrderIsMusicMeetingTimerWeather() {
        var i = base
        i.hasWeather = true
        i.hasRunningTimer = true
        i.hasImminentMeeting = true
        i.hasNowPlaying = true
        #expect(HomeComposer.compose(i).hero == .nowPlaying)
        i.hasNowPlaying = false
        #expect(HomeComposer.compose(i).hero == .meeting)
    }

    @Test func permissionRequestIsAlwaysHero() {
        var i = base
        i.hasNowPlaying = true
        i.pendingPermission = .music
        #expect(HomeComposer.compose(i).hero == .permission(.music))
    }

    @Test func tilesAreAtMostTwoAndExcludeHero() {
        var i = base
        i.hasWeather = true
        i.hasUpcomingEvent = true
        i.hasNowPlaying = true
        let c = HomeComposer.compose(i)
        #expect(c.tiles.count <= 2 && !c.tiles.contains(c.hero!))
        #expect(c.tiles == [.weather, .nextEvent])
    }

    @Test func emptyHomeOffersQuickStart() { #expect(HomeComposer.compose(base).tiles.contains(.timerQuickStart)) }
}
