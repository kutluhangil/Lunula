import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import IslandServices

@MainActor @Suite struct NowPlayingCoordinatorTests {
    let time = ManualTime()
    let center = NotificationCenter()

    func make(_ sources: [NowPlayingSource], permissions: FakePermissions = FakePermissions()) -> NowPlayingCoordinator
    {
        NowPlayingCoordinator(
            sources: sources, center: center, time: time, accents: FakeAccents(), permissions: permissions)
    }

    @Test func mostRecentlyChangedSourceWins() async {
        let music = FakeSource(.music, playing: true)
        let spotify = FakeSource(.spotify, playing: false)
        let c = make([music, spotify])
        c.start()
        await settle()
        spotify.state = .playing
        center.post(name: spotify.notificationName, object: nil)
        await settle()
        #expect(c.snapshot?.source == .spotify)
    }

    @Test func pausedSourceExpiresAfter10Minutes() async {
        let music = FakeSource(.music, playing: false)
        let c = make([music])
        c.start()
        await settle()
        #expect(c.activities.first?.expiresAt == time.now.addingTimeInterval(600))
    }

    @Test func trackChangeRaisesAlertOnce() async {
        let music = FakeSource(.music, playing: true)
        let c = make([music])
        var alerts = 0
        c.onAlert = { _ in alerts += 1 }
        c.start()
        await settle()
        music.trackID = "2"
        center.post(name: music.notificationName, object: nil)
        await settle()
        center.post(name: music.notificationName, object: nil)
        await settle()
        #expect(alerts == 1)
    }

    @Test func verificationQueriesOnlyWhileExpanded() async {
        let music = FakeSource(.music, playing: true)
        let c = make([music])
        c.start()
        await settle()
        let base = music.queryCount
        time.advance(by: 30)
        await settle()
        #expect(music.queryCount == base)
        c.setExpanded(true)
        time.advance(by: 10)
        await settle()
        #expect(music.queryCount == base + 1)
    }

    @Test func commandsRoutedToActiveSource() async {
        let music = FakeSource(.music, playing: true)
        let c = make([music])
        c.start()
        await settle()
        await c.perform(.next)
        #expect(music.commands == [.next])
    }

    @Test func notificationPayloadIsOnlyATrigger() async {
        let music = FakeSource(.music, playing: true)
        let c = make([music])
        c.start()
        await settle()
        center.post(name: music.notificationName, object: nil, userInfo: ["Name": "SAHTE"])
        await settle()
        #expect(c.snapshot?.title == music.title)
    }

    @Test func consentNeededSkipsScriptAndAlertsOncePerSession() async {
        let music = FakeSource(.music, playing: true)
        let perms = FakePermissions([.music: .needsConsent])
        let c = make([music], permissions: perms)
        var kinds: [AlertKind] = []
        c.onAlert = { kinds.append($0.kind) }
        c.start()
        await settle()
        center.post(name: music.notificationName, object: nil)
        await settle()
        #expect(music.queryCount == 0 && kinds == [.permissionNeeded] && c.pendingConsent == .music)
    }
}
