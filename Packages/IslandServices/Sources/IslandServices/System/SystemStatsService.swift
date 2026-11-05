import Darwin
import Foundation
import IOKit
import IOKit.ps
import Observation

public struct WirelessDeviceBattery: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var level: Int

    public init(id: String, name: String, level: Int) {
        self.id = id
        self.name = name
        self.level = level
    }
}

public struct SystemStatsSnapshot: Equatable, Sendable {
    public var cpuPercent: Int
    public var memoryPercent: Int
    public var memoryUsedGB: Double
    public var memoryTotalGB: Double
    public var wirelessBatteries: [WirelessDeviceBattery]

    public init(
        cpuPercent: Int, memoryPercent: Int, memoryUsedGB: Double, memoryTotalGB: Double,
        wirelessBatteries: [WirelessDeviceBattery]
    ) {
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        self.memoryUsedGB = memoryUsedGB
        self.memoryTotalGB = memoryTotalGB
        self.wirelessBatteries = wirelessBatteries
    }
}

/// On-demand Mach CPU/Memory telemetry and IOKit wireless device battery reader (zero background polling).
@MainActor @Observable public final class SystemStatsService {
    @ObservationIgnored private var previousTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?

    public private(set) var snapshot = SystemStatsSnapshot(
        cpuPercent: 0, memoryPercent: 0, memoryUsedGB: 0, memoryTotalGB: 0, wirelessBatteries: [])

    public init() {}

    @discardableResult
    public func refresh() -> SystemStatsSnapshot {
        let cpu = readCPUPercent()
        let mem = Self.readMemory()
        let devices = Self.readWirelessBatteries()
        let next = SystemStatsSnapshot(
            cpuPercent: cpu,
            memoryPercent: mem.percent,
            memoryUsedGB: mem.usedGB,
            memoryTotalGB: mem.totalGB,
            wirelessBatteries: devices)
        snapshot = next
        return next
    }

    private func readCPUPercent() -> Int {
        var load = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let current = (
            user: UInt64(load.cpu_ticks.0),
            system: UInt64(load.cpu_ticks.1),
            idle: UInt64(load.cpu_ticks.2),
            nice: UInt64(load.cpu_ticks.3)
        )
        defer { previousTicks = current }
        guard let prev = previousTicks else { return 0 }
        let userDiff = current.user - prev.user
        let sysDiff = current.system - prev.system
        let idleDiff = current.idle - prev.idle
        let niceDiff = current.nice - prev.nice
        let total = userDiff + sysDiff + idleDiff + niceDiff
        guard total > 0 else { return 0 }
        return Int(((Double(userDiff + sysDiff + niceDiff) / Double(total)) * 100).rounded())
    }

    private static func readMemory() -> (percent: Int, usedGB: Double, totalGB: Double) {
        let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
        let totalGB = totalBytes / (1024 * 1024 * 1024)
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard status == KERN_SUCCESS, totalBytes > 0 else { return (0, 0, totalGB) }
        var pageSize: vm_size_t = 4096
        host_page_size(mach_host_self(), &pageSize)
        let usedPages =
            UInt64(vmStats.active_count) + UInt64(vmStats.wire_count) + UInt64(vmStats.compressor_page_count)
        let usedBytes = Double(usedPages) * Double(pageSize)
        let usedGB = usedBytes / (1024 * 1024 * 1024)
        let percent = min(max(Int(((usedBytes / totalBytes) * 100).rounded()), 0), 100)
        return (percent, usedGB, totalGB)
    }

    private static func readWirelessBatteries() -> [WirelessDeviceBattery] {
        var found: [WirelessDeviceBattery] = []
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        for source in list {
            guard
                let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                desc[kIOPSTypeKey] as? String != kIOPSInternalBatteryType,
                let name = desc[kIOPSNameKey] as? String,
                let capacity = desc[kIOPSCurrentCapacityKey] as? Int
            else { continue }
            found.append(WirelessDeviceBattery(id: name, name: name, level: min(max(capacity, 0), 100)))
        }
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(
            kIOMainPortDefault, IOServiceMatching("AppleDeviceManagementHIDEventService"), &iterator) == KERN_SUCCESS
        {
            defer { IOObjectRelease(iterator) }
            while case let service = IOIteratorNext(iterator), service != 0 {
                defer { IOObjectRelease(service) }
                let product =
                    IORegistryEntryCreateCFProperty(service, "Product" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? String
                let percent =
                    IORegistryEntryCreateCFProperty(service, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?
                    .takeRetainedValue() as? Int
                if let product, let percent, !found.contains(where: { $0.name == product }) {
                    found.append(
                        WirelessDeviceBattery(id: product, name: product, level: min(max(percent, 0), 100)))
                }
            }
        }
        return found
    }
}
