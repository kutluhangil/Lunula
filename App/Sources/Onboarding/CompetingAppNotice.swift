import AppKit
import IslandCore

/// Watches app launches for known notch apps and raises one gentle island alert per app, ever.
@MainActor final class CompetingAppNotice: AlertProviding {
    var onAlert: (@MainActor (TransientAlert) -> Void)?
    private let settings: SettingsStore
    private var observer: NSObjectProtocol?

    init(settings: SettingsStore) { self.settings = settings }

    func start() {
        check()
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.check() } }
    }

    private func check() {
        let running = NSWorkspace.shared.runningApplications
        guard
            let id = CompetingApps.detect(
                running: running.compactMap(\.bundleIdentifier), alreadyNotified: settings.settings.notifiedCompetitors)
        else { return }
        settings.update { $0.notifiedCompetitors.insert(id) }
        let name = running.first { $0.bundleIdentifier == id }?.localizedName ?? id
        onAlert?(
            TransientAlert(
                id: UUID(), kind: .custom,
                detail: .text(
                    title: String(localized: "competing.notice \(name)"), subtitle: nil,
                    symbol: "exclamationmark.triangle"),
                tint: .orange, duration: 4, priority: .normal))
    }
}
