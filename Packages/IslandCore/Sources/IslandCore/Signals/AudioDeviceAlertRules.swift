import Foundation

public enum AudioDeviceTransport: String, Codable, Equatable, Sendable {
    case builtIn, bluetooth, usb, airPlay, hdmi, virtual, other
}

public struct AudioDeviceInfo: Equatable, Sendable {
    public var id: UInt32
    public var name: String
    public var transport: AudioDeviceTransport
    public var batteryLevel: Int?

    public init(id: UInt32, name: String, transport: AudioDeviceTransport, batteryLevel: Int? = nil) {
        self.id = id
        self.name = name
        self.transport = transport
        self.batteryLevel = batteryLevel.map { min(max($0, 0), 100) }
    }
}

/// Pure rules for external/Bluetooth audio device connect transient alerts (zero polling, Linux-testable).
public enum AudioDeviceAlertRules {
    private static let alertableTransports: Set<AudioDeviceTransport> = [.bluetooth, .usb, .airPlay]

    /// Devices present in `current` that were absent in `previous` and use an external/wireless transport.
    public static func newlyConnected(
        previous: [AudioDeviceInfo], current: [AudioDeviceInfo]
    ) -> [AudioDeviceInfo] {
        let oldIDs = Set(previous.map(\.id))
        let oldNames = Set(previous.map { $0.name.lowercased() })
        return current.filter { device in
            alertableTransports.contains(device.transport)
                && !oldIDs.contains(device.id)
                && !oldNames.contains(device.name.lowercased())
        }
    }

    public static func symbol(for device: AudioDeviceInfo) -> String {
        let lower = device.name.lowercased()
        if lower.contains("airpods max") { return "airpodsmax" }
        if lower.contains("airpods pro") { return "airpodspro" }
        if lower.contains("airpods") { return "airpods.gen3" }
        if lower.contains("homepod") || lower.contains("speaker") || lower.contains("hoparlör") {
            return "hifispeaker.fill"
        }
        switch device.transport {
        case .bluetooth: return "headphones"
        case .airPlay: return "airplayaudio"
        case .usb: return "hifispeaker.2.fill"
        default: return "speaker.wave.2.fill"
        }
    }

    /// Best-effort match between an audio device name and IOKit wireless battery readings.
    public static func matchBattery(deviceName: String, batteries: [String: Int]) -> Int? {
        let needle = deviceName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return nil }
        for (name, level) in batteries {
            if name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == needle {
                return min(max(level, 0), 100)
            }
        }
        for (name, level) in batteries {
            let candidate = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !candidate.isEmpty && (needle.contains(candidate) || candidate.contains(needle)) {
                return min(max(level, 0), 100)
            }
        }
        return nil
    }

    public static func alert(for device: AudioDeviceInfo, connectedSubtitle: String) -> TransientAlert {
        let subtitle =
            if let battery = device.batteryLevel {
                "\(connectedSubtitle) · \(battery)%"
            } else {
                connectedSubtitle
            }
        return TransientAlert(
            id: UUID(), kind: .custom,
            detail: .text(title: device.name, subtitle: subtitle, symbol: symbol(for: device)),
            tint: .green, duration: 2.6, priority: .normal)
    }
}
