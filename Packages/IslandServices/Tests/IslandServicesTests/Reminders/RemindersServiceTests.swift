import Foundation
import Testing

@testable import IslandServices

final class FakeReminderReader: ReminderReading, @unchecked Sendable {
    var status: CalendarAuthorization
    var grantedOnRequest: CalendarAuthorization
    var records: [ReminderRecord]
    private(set) var requestCount = 0

    init(
        _ status: CalendarAuthorization, grantedOnRequest: CalendarAuthorization = .fullAccess,
        records: [ReminderRecord] = []
    ) {
        self.status = status
        self.grantedOnRequest = grantedOnRequest
        self.records = records
    }

    func authorization() -> CalendarAuthorization { status }

    func requestAccess() async -> CalendarAuthorization {
        requestCount += 1
        status = grantedOnRequest
        return status
    }

    func incompleteReminders() async -> [ReminderRecord] {
        records.filter { !$0.isCompleted }
    }

    func addReminder(title: String) async -> Bool {
        records.append(ReminderRecord(id: "r-\(records.count + 1)", title: title, isCompleted: false))
        return true
    }

    func toggleReminder(id: String) async -> Bool {
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return false }
        records[idx].isCompleted.toggle()
        return true
    }

    func removeReminder(id: String) async -> Bool {
        let before = records.count
        records.removeAll { $0.id == id }
        return records.count != before
    }
}

@MainActor @Suite struct RemindersServiceTests {
    @Test func notDeterminedNeverPromptsAndReturnsEmpty() async {
        let reader = FakeReminderReader(
            .notDetermined, records: [.init(id: "1", title: "Buy milk", isCompleted: false)])
        let service = RemindersService(reader: reader)
        service.start()
        await settle()
        #expect(service.authorization == .notDetermined)
        #expect(service.items.isEmpty)
        #expect(reader.requestCount == 0)
    }

    @Test func requestAccessLoadsAndMutatesReminders() async {
        let reader = FakeReminderReader(
            .notDetermined, grantedOnRequest: .fullAccess,
            records: [.init(id: "1", title: "Ship v1", isCompleted: false)])
        let service = RemindersService(reader: reader)
        service.start()
        await service.requestAccess()
        await settle()
        #expect(service.authorization == .fullAccess)
        #expect(service.items.map(\.title) == ["Ship v1"])

        service.add("Write release notes")
        await settle()
        #expect(service.items.count == 2)

        service.toggle("1")
        await settle()
        #expect(service.items.map(\.title) == ["Write release notes"])

        if let remainingID = service.items.first?.id {
            service.remove(remainingID)
            await settle()
        }
        #expect(service.items.isEmpty)
    }

    @Test func storeChangeNotificationRefreshes() async {
        let center = NotificationCenter()
        let reader = FakeReminderReader(.fullAccess, records: [])
        let service = RemindersService(reader: reader, center: center)
        service.start()
        await settle()
        #expect(service.items.isEmpty)

        reader.records = [.init(id: "9", title: "Synced from iPhone", isCompleted: false)]
        center.post(name: .EKEventStoreChanged, object: nil)
        await settle()
        #expect(service.items.map(\.title) == ["Synced from iPhone"])
    }
}
