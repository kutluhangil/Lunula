import Foundation
import IslandCore
import Observation

@MainActor @Observable public final class DeviceUsageMonitor {
    @ObservationIgnored private let reader: DeviceUsageReading
    public private(set) var privacy: PrivacySnapshot = .none

    public init(reader: DeviceUsageReading) { self.reader = reader }

    public func start() {
        // Listener blocks run on the main queue.
        reader.onChange = { [weak self] in MainActor.assumeIsolated { self?.refresh() } }
        reader.start()
        refresh()
    }

    public func stop() {
        reader.stop()
        reader.onChange = nil
        privacy = .none
    }

    private func refresh() {
        let new = PrivacySnapshot(cameraInUse: reader.cameraInUse(), microphoneInUse: reader.microphoneInUse())
        if new != privacy { privacy = new }
    }
}
