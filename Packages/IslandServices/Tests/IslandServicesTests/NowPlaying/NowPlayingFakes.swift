import Foundation
import IslandCore
import IslandCoreTestSupport

@testable import IslandServices

/// Returns prepared snapshots instead of running scripts; records queries and commands.
final class FakeSource: NowPlayingSource, @unchecked Sendable {  // tests mutate it from the main actor only
    enum State { case playing, paused }
    let id: MediaSourceID
    var state: State
    var trackID = "1"
    var title = "Title"
    private(set) var queryCount = 0
    private(set) var commands: [PlaybackCommand] = []

    init(_ id: MediaSourceID, playing: Bool) {
        self.id = id
        state = playing ? .playing : .paused
    }

    var bundleID: String { "fake.\(id.rawValue)" }
    var notificationName: Notification.Name { .init("fake.\(id.rawValue).changed") }

    func snapshot(now: Date) async -> NowPlayingSnapshot? {
        queryCount += 1
        return NowPlayingSnapshot(
            source: id, trackID: trackID, title: title, artist: "Artist", album: nil, artworkKey: "\(id):\(trackID)",
            duration: 200, position: 0, positionTimestamp: now, isPlaying: state == .playing)
    }

    func artwork(for trackID: String) async -> Data? { nil }
    func perform(_ command: PlaybackCommand) async { commands.append(command) }
}

struct FakeAccents: ArtworkAccentProviding {
    func accent(for key: String, data: @Sendable () async -> Data?) async -> RGBAColor? { nil }
}

final class FakePermissions: AutomationPermissionChecking, @unchecked Sendable {  // main-actor tests only
    var values: [MediaSourceID: AutomationPermission]
    let afterRequest: AutomationPermission

    init(_ values: [MediaSourceID: AutomationPermission] = [:], afterRequest: AutomationPermission = .granted) {
        self.values = values
        self.afterRequest = afterRequest
    }

    private func value(_ bundleID: String) -> AutomationPermission {
        values.first { "fake.\($0.key.rawValue)" == bundleID }?.value ?? .granted
    }

    func status(for bundleID: String) async -> AutomationPermission { value(bundleID) }
    func requestConsent(for bundleID: String) async -> AutomationPermission {
        for key in values.keys where "fake.\(key.rawValue)" == bundleID { values[key] = afterRequest }
        return afterRequest
    }
}

extension NowPlayingCoordinator {
    @MainActor static func make(sources: [NowPlayingSource], permissions: FakePermissions) -> NowPlayingCoordinator {
        NowPlayingCoordinator(
            sources: sources, center: NotificationCenter(), time: ManualTime(), accents: FakeAccents(),
            permissions: permissions)
    }
}
