import Foundation
import IslandCore
import IslandCoreTestSupport
import Testing

@testable import Lunula

@MainActor @Suite struct IntentsTests {
    @Test func showActivityIntentAddsCustomActivity() async throws {
        let custom = CustomActivityController(time: ManualTime())
        var intent = ShowActivityIntent()
        intent.id = "deploy"
        intent.title = "Yayın"
        intent.accentHex = "34C759"
        _ = try await intent.perform(using: custom)
        #expect(custom.activities.first?.accent == RGBAColor(hex: "34C759"))
    }

    @Test func invalidAccentHexThrows() async {
        var intent = ShowActivityIntent()
        intent.id = "x"
        intent.title = "t"
        intent.accentHex = "nothex"
        await #expect(throws: IntentError.self) {
            _ = try await intent.perform(using: CustomActivityController(time: ManualTime()))
        }
    }

    @Test func updateUnknownIDThrowsNotFound() async {
        var intent = UpdateActivityIntent()
        intent.id = "missing"
        intent.title = "t"
        await #expect(throws: IntentError.self) {
            _ = try await intent.perform(using: CustomActivityController(time: ManualTime()))
        }
    }

    @Test func startTimerIntentStartsTimer() async throws {
        let timer = TimerController(time: ManualTime(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var intent = StartTimerIntent()
        intent.minutes = 10
        _ = try await intent.perform(using: timer)
        #expect(timer.current?.duration == 600)
    }
}
