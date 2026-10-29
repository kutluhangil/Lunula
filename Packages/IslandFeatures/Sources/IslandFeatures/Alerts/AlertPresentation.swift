import AppKit
import IslandCore

/// What a transient alert shows: a symbol, a localization key (or, for custom alerts, the requested text) and an
/// optional second line.
struct AlertPresentation: Equatable {
    var symbol: String
    var titleKey: String
    var subtitle: String?
    /// Custom alerts carry their own text instead of a catalog key.
    var titleIsVerbatim = false
}

enum AlertPresentations {
    static func make(_ alert: TransientAlert) -> AlertPresentation {
        let level: Int? = if case .batteryLevel(let l) = alert.detail { l } else { nil }
        switch alert.kind {
        case .charging:
            return .init(
                symbol: BatterySymbol.name(level: level ?? 100, charging: true), titleKey: "alert.charging",
                subtitle: level.map { "\($0)%" })
        case .unplugged:
            return .init(
                symbol: BatterySymbol.name(level: level ?? 100, charging: false), titleKey: "alert.unplugged",
                subtitle: level.map { "\($0)%" })
        case .batteryLow:
            return .init(
                symbol: BatterySymbol.name(level: level ?? 10, charging: false), titleKey: "alert.batteryLow",
                subtitle: level.map { "\($0)%" })
        case .batteryFull:
            return .init(symbol: "battery.100percent", titleKey: "alert.batteryFull", subtitle: nil)
        case .downloadFinished:
            let name: String? = if case .file(let name, _) = alert.detail { name } else { nil }
            return .init(symbol: "arrow.down.circle.fill", titleKey: "alert.downloadFinished", subtitle: name)
        case .timerFinished:
            guard case .timer(let label, let phase) = alert.detail else {
                return .init(symbol: "timer", titleKey: "alert.timerFinished", subtitle: nil)
            }
            switch phase {
            case .simple: return .init(symbol: "timer", titleKey: "alert.timerFinished", subtitle: label)
            case .focus: return .init(symbol: "cup.and.saucer.fill", titleKey: "alert.breakStarted", subtitle: label)
            case .shortBreak, .longBreak:
                return .init(symbol: "brain.head.profile", titleKey: "alert.focusStarted", subtitle: label)
            }
        case .trackChanged:
            let line: String? =
                if case .track(let title, let artist, _) = alert.detail { "\(title) — \(artist)" } else { nil }
            return .init(symbol: "music.note", titleKey: "alert.trackChanged", subtitle: line)
        case .permissionNeeded:
            return .init(symbol: "lock.fill", titleKey: "alert.permissionNeeded", subtitle: nil)
        case .custom:
            guard case .text(let title, let subtitle, let symbol) = alert.detail else {
                return .init(symbol: "bell.fill", titleKey: "", subtitle: nil, titleIsVerbatim: true)
            }
            let valid = symbol.flatMap {
                NSImage(systemSymbolName: $0, accessibilityDescription: nil) == nil ? nil : $0
            }
            return .init(symbol: valid ?? "bell.fill", titleKey: title, subtitle: subtitle, titleIsVerbatim: true)
        }
    }
}
