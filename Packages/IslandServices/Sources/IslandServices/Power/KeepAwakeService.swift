import Foundation
import IOKit.pwr_mgt
import IslandCore
import Observation

/// Prevents idle display sleep via IOKit power assertions (`IOPMAssertionCreateWithName`), with optional auto-expiry.
@MainActor @Observable public final class KeepAwakeService {
    @ObservationIgnored private let time: IslandTime
    @ObservationIgnored private var assertionID: IOPMAssertionID = 0
    @ObservationIgnored private var expiryToken: ScheduledToken?

    public private(set) var isActive = false
    public private(set) var expiresAt: Date?

    public init(time: IslandTime) {
        self.time = time
    }

    public func toggle() {
        if isActive {
            deactivate()
        } else {
            activate(duration: nil)
        }
    }

    /// `duration == nil` keeps the display awake indefinitely until deactivated.
    public func activate(duration: TimeInterval?) {
        deactivate()
        var id: IOPMAssertionID = 0
        let reason = "Lunula Keep Awake" as CFString
        let type = kIOPMAssertPreventUserIdleDisplaySleep as CFString
        let status = IOPMAssertionCreateWithName(type, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &id)
        guard status == kIOReturnSuccess else { return }
        assertionID = id
        isActive = true
        if let duration, duration > 0 {
            let deadline = time.now.addingTimeInterval(duration)
            expiresAt = deadline
            expiryToken = time.schedule(after: duration) { [weak self] in
                self?.deactivate()
            }
        } else {
            expiresAt = nil
        }
    }

    public func deactivate() {
        expiryToken?.cancel()
        expiryToken = nil
        if isActive, assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        isActive = false
        expiresAt = nil
    }
}
