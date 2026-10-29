import IslandCore
import SwiftUI

/// Root of one screen's island panel; renders the store's state through IslandSurface.
public struct IslandRootView: View {
    private let store: IslandStore
    private let notch: NotchMetrics
    private let home: @MainActor () -> HomeInputs
    private let onHover: @MainActor (Bool) -> Void
    private let openSettings: @MainActor () -> Void

    public init(
        store: IslandStore, notch: NotchMetrics, home: @escaping @MainActor () -> HomeInputs,
        onHover: @escaping @MainActor (Bool) -> Void, openSettings: @escaping @MainActor () -> Void
    ) {
        self.store = store
        self.notch = notch
        self.home = home
        self.onHover = onHover
        self.openSettings = openSettings
    }

    public var body: some View {
        IslandSurface(
            state: store.state, notch: notch, home: home(), now: Date(), send: { store.send($0) }, onHover: onHover,
            openSettings: openSettings)
    }
}

#if DEBUG
    extension IslandRootView {
        static let previewNotch = NotchMetrics(rect: CGRect(x: 0, y: 0, width: 188, height: 32), hasHardwareNotch: true)

        /// Fixed state for tests and #Preview; bypasses the store so any phase can be shown directly.
        @MainActor static func preview(phase: IslandPhase) -> some View {
            var state = IslandState()
            state.phase = phase
            if phase != .idle {
                state.layout = IslandLayout(
                    primary: Activity(
                        id: "preview", priority: .normal, startedAt: .distantPast, updatedAt: .distantPast,
                        expiresAt: nil,
                        content: .custom(
                            CustomActivitySnapshot(
                                title: "Preview", subtitle: nil, symbol: "sparkles", progress: nil, endsAt: nil)),
                        accent: nil),
                    detached: [], overflowCount: 0)
            }
            let home = HomeInputs(
                pendingPermission: nil, hasNowPlaying: false, hasImminentMeeting: false, hasRunningTimer: false,
                hasWeather: true, hasUpcomingEvent: true, calendarAccessUndetermined: false)
            return IslandSurface(
                state: state, notch: previewNotch, home: home, now: .distantPast, send: { _ in }, onHover: { _ in },
                openSettings: {})
        }
    }

    #Preview("Expanded") { IslandRootView.preview(phase: .expanded(.home)).background(.white) }
#endif
