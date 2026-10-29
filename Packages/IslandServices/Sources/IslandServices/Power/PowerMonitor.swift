import Foundation
import IOKit.ps
import IslandCore
import Observation

/// Battery state from IOKit power-source notifications (no polling, no permission) plus Low Power Mode.
@MainActor @Observable public final class PowerMonitor: AlertProviding {
    @ObservationIgnored public var onAlert: (@MainActor (TransientAlert) -> Void)?
    @ObservationIgnored private var source: CFRunLoopSource?
    @ObservationIgnored private var session = BatteryAlertSession()
    @ObservationIgnored private var lowPowerObserver: NSObjectProtocol?

    public private(set) var battery: BatterySnapshot?
    public private(set) var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    public init() {}

    public func start() {
        guard source == nil else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let created = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context else { return }
                let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated { monitor.update() }
            }, context)?.takeRetainedValue()
        {
            source = created
            CFRunLoopAddSource(CFRunLoopGetMain(), created, .defaultMode)
        }
        lowPowerObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update() }
        }
        update()
    }

    public func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode) }
        source = nil
        if let lowPowerObserver { NotificationCenter.default.removeObserver(lowPowerObserver) }
        lowPowerObserver = nil
    }

    private func update() {
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let providing = IOPSGetProvidingPowerSourceType(info).takeUnretainedValue() as String
        let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        let battery = list.lazy
            .compactMap { IOPSGetPowerSourceDescription(info, $0)?.takeUnretainedValue() as? [String: Any] }
            .first { $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType }
        let new = PowerSourceParser.snapshot(
            from: battery ?? [:], providingSource: providing, lowPowerMode: isLowPowerMode)
        for alert in BatteryAlertRules.alerts(from: self.battery, to: new, session: &session) { onAlert?(alert) }
        self.battery = new
    }
}
