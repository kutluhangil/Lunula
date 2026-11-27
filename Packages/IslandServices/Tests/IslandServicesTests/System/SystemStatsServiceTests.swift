import Foundation
import Testing

@testable import IslandServices

@Suite struct SystemStatsServiceTests {
    @Test func readNetworkCountersReturnsValidValues() {
        let first = SystemStatsService.readNetworkCounters()
        let second = SystemStatsService.readNetworkCounters()
        #expect(first.rxBytes >= 0)
        #expect(first.txBytes >= 0)
        #expect(second.rxBytes >= 0)
        #expect(second.txBytes >= 0)
    }

    @Test func formatRateFormatsZeroKilobytesAndMegabytes() {
        #expect(SystemStatsService.formatRate(0) == "0 KB/s")
        #expect(SystemStatsService.formatRate(512) == "0 KB/s")
        #expect(SystemStatsService.formatRate(51_200) == "50 KB/s")
        #expect(SystemStatsService.formatRate(15_728_640) == "15.0 MB/s")
    }

    @Test @MainActor func refreshPopulatesSnapshotCleanly() async throws {
        let service = SystemStatsService()
        let initial = service.refresh()
        #expect(initial.cpuPercent >= 0 && initial.cpuPercent <= 100)
        #expect(initial.memoryPercent >= 0 && initial.memoryPercent <= 100)
        #expect(initial.memoryTotalGB > 0)
        #expect(initial.downloadBytesPerSec == 0)
        #expect(initial.uploadBytesPerSec == 0)

        try await Task.sleep(for: .milliseconds(220))
        let followUp = service.refresh()
        #expect(followUp.downloadBytesPerSec >= 0)
        #expect(followUp.uploadBytesPerSec >= 0)
        #expect(service.snapshot == followUp)
    }
}
