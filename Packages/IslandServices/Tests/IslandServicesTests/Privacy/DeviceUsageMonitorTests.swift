import Foundation
import IslandCore
import Testing

@testable import IslandServices

final class FakeUsageReader: DeviceUsageReading {
    var onChange: (() -> Void)?
    var camera = false
    var microphone = false
    func cameraInUse() -> Bool { camera }
    func microphoneInUse() -> Bool { microphone }
    func start() {}
    func stop() {}
}

@MainActor @Suite struct DeviceUsageMonitorTests {
    @Test func monitorPublishesChangesFromReader() {
        let r = FakeUsageReader()
        let m = DeviceUsageMonitor(reader: r)
        m.start()
        r.camera = true
        r.onChange?()
        #expect(m.privacy == PrivacySnapshot(cameraInUse: true, microphoneInUse: false))
    }
}
