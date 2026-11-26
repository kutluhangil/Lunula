import EventKit
import Foundation
import Observation

/// Event-driven Apple Reminders synchronization. Never requests access automatically; refreshes on `.EKEventStoreChanged`.
@MainActor @Observable public final class RemindersService {
    @ObservationIgnored private let reader: ReminderReading
    @ObservationIgnored private let center: NotificationCenter
    @ObservationIgnored private var observer: NSObjectProtocol?

    public private(set) var items: [ReminderRecord] = []
    public private(set) var authorization: CalendarAuthorization = .notDetermined

    public init(reader: ReminderReading, center: NotificationCenter = .default) {
        self.reader = reader
        self.center = center
    }

    public func start() {
        authorization = reader.authorization()
        if observer == nil {
            observer = center.addObserver(forName: .EKEventStoreChanged, object: nil, queue: nil) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
        }
        refresh()
    }

    public func stop() {
        if let observer { center.removeObserver(observer) }
        observer = nil
    }

    public func requestAccess() async {
        authorization = await reader.requestAccess()
        await refreshNow()
    }

    public func add(_ rawTitle: String) {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, authorization == .fullAccess else { return }
        let reader = reader
        Task {
            if await reader.addReminder(title: trimmed) {
                refresh()
            }
        }
    }

    public func toggle(_ id: String) {
        guard authorization == .fullAccess else { return }
        let reader = reader
        Task {
            if await reader.toggleReminder(id: id) {
                refresh()
            }
        }
    }

    public func remove(_ id: String) {
        guard authorization == .fullAccess else { return }
        let reader = reader
        Task {
            if await reader.removeReminder(id: id) {
                refresh()
            }
        }
    }

    public func refresh() {
        Task { await refreshNow() }
    }

    private func refreshNow() async {
        authorization = reader.authorization()
        guard authorization == .fullAccess else {
            items = []
            return
        }
        let fetched = await reader.incompleteReminders()
        items = fetched
    }
}
