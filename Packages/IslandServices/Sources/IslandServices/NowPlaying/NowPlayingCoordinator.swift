import AppKit
import IslandCore
import Observation

/// Event-driven Now Playing: player notifications only trigger a scripted re-read (payloads are never trusted);
/// the most recently started source wins; no polling except a 10 s check while the island is expanded.
@MainActor @Observable public final class NowPlayingCoordinator: ActivityProviding, AlertProviding {
    public static let activityID: ActivityID = "nowPlaying"
    static let pausedLifetime: TimeInterval = 600
    static let verificationInterval: TimeInterval = 10

    @ObservationIgnored private let sources: [NowPlayingSource]
    @ObservationIgnored private let center: NotificationCenter
    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private let accents: ArtworkAccentProviding
    @ObservationIgnored private let permissionChecker: AutomationPermissionChecking
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var latest: [MediaSourceID: NowPlayingSnapshot] = [:]
    @ObservationIgnored private var activeID: MediaSourceID?
    @ObservationIgnored private var pausedSince: Date?
    @ObservationIgnored private var consentAlerted: Set<MediaSourceID> = []
    @ObservationIgnored private var verification: ScheduledToken?
    @ObservationIgnored private var isExpanded = false
    @ObservationIgnored public var onActivitiesChange: (@MainActor () -> Void)?
    @ObservationIgnored public var onAlert: (@MainActor (TransientAlert) -> Void)?

    public private(set) var snapshot: NowPlayingSnapshot?
    public private(set) var accent: RGBAColor?
    public private(set) var permissions: [MediaSourceID: AutomationPermission] = [:]
    public private(set) var pendingConsent: MediaSourceID?

    public init(
        sources: [NowPlayingSource], center: NotificationCenter = DistributedNotificationCenter.default(),
        time: IslandTime, accents: ArtworkAccentProviding, permissions: AutomationPermissionChecking
    ) {
        self.sources = sources
        self.center = center
        self.time = time
        self.accents = accents
        permissionChecker = permissions
    }

    public var activities: [Activity] {
        guard let snapshot else { return [] }
        let content = ActivityContent.nowPlaying(snapshot)
        return [
            Activity(
                id: Self.activityID, priority: ActivityPriorityRules.priority(for: content, now: time.now),
                startedAt: snapshot.positionTimestamp, updatedAt: snapshot.positionTimestamp,
                expiresAt: snapshot.isPlaying ? nil : pausedSince?.addingTimeInterval(Self.pausedLifetime),
                content: content, accent: accent)
        ]
    }

    public func start() {
        guard observers.isEmpty else { return }
        for source in sources {
            // Observe by name: unnamed distributed observation does not work in the sandbox.
            observers.append(
                center.addObserver(forName: source.notificationName, object: nil, queue: nil) { [weak self] _ in
                    Task { @MainActor [weak self] in await self?.refresh(source, triggeredByPlayer: true) }
                })
            Task { await refresh(source, triggeredByPlayer: false) }
        }
    }

    public func stop() {
        for observer in observers { center.removeObserver(observer) }
        observers = []
        verification?.cancel()
        verification = nil
    }

    public func perform(_ command: PlaybackCommand) async {
        guard let source = activeSource else { return }
        await source.perform(command)
        await refresh(source, triggeredByPlayer: false)
    }

    public func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        verification?.cancel()
        verification = nil
        if expanded { scheduleVerification() }
    }

    public func requestConsent(for id: MediaSourceID) async {
        guard let source = sources.first(where: { $0.id == id }) else { return }
        let result = await permissionChecker.requestConsent(for: source.bundleID)
        permissions[id] = result
        if result == .granted {
            if pendingConsent == id { pendingConsent = nil }
            await refresh(source, triggeredByPlayer: false)
        }
    }

    // MARK: - Private

    private var activeSource: NowPlayingSource? { sources.first { $0.id == activeID } }

    private func scheduleVerification() {
        verification = time.schedule(after: Self.verificationInterval) { [weak self] in
            guard let self, isExpanded else { return }
            if let source = activeSource { Task { await self.refresh(source, triggeredByPlayer: false) } }
            scheduleVerification()
        }
    }

    private func refresh(_ source: NowPlayingSource, triggeredByPlayer: Bool) async {
        let permission = await permissionChecker.status(for: source.bundleID)
        permissions[source.id] = permission
        switch permission {
        case .notRunning:
            apply(nil, from: source)
            return
        case .denied:
            return  // shown in Settings' permission centre (T9.2), never as an alert
        case .needsConsent:
            pendingConsent = source.id
            // Only when the user is actually playing music, once per session; never at launch.
            if triggeredByPlayer, consentAlerted.insert(source.id).inserted {
                onAlert?(
                    TransientAlert(
                        id: UUID(), kind: .permissionNeeded, detail: .permission(source.id), tint: .neutral,
                        duration: 2.6, priority: .normal))
            }
            return
        case .granted:
            if pendingConsent == source.id { pendingConsent = nil }
        }
        apply(await source.snapshot(now: time.now), from: source)
    }

    private func apply(_ new: NowPlayingSnapshot?, from source: NowPlayingSource) {
        latest[source.id] = new
        if new?.isPlaying == true || activeID == nil || (activeID == source.id && new == nil) {
            activeID = new == nil ? latest.first(where: { $0.value.isPlaying })?.key ?? latest.keys.first : source.id
        }
        let previous = snapshot
        let current = activeID.flatMap { latest[$0] }

        if let current, current.isPlaying {
            pausedSince = nil
        } else if current != nil, pausedSince == nil || previous?.trackID != current?.trackID {
            pausedSince = time.now
        }

        if let current, let previous, current.trackID != previous.trackID {
            onAlert?(
                TransientAlert(
                    id: UUID(), kind: .trackChanged,
                    detail: .track(title: current.title, artist: current.artist, artworkKey: current.artworkKey),
                    tint: accent.map(SignalTint.accent) ?? .neutral, duration: 2.0, priority: .normal))
        }
        if current?.artworkKey != previous?.artworkKey {
            accent = nil
            if let current { loadAccent(for: current, from: activeSource ?? source) }
        }
        guard current != previous else { return }
        snapshot = current
        onActivitiesChange?()
    }

    private func loadAccent(for track: NowPlayingSnapshot, from source: NowPlayingSource) {
        guard let key = track.artworkKey else { return }
        let trackID = track.trackID
        Task {
            let color = await accents.accent(for: key) { await source.artwork(for: trackID) }
            guard snapshot?.artworkKey == key else { return }
            accent = color
            onActivitiesChange?()
        }
    }
}
