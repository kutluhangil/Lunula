import Foundation

/// What has already been announced: "full" once per plug-in, each low threshold once until the next plug-in.
public struct BatteryAlertSession: Equatable, Sendable {
    public var fullShownThisPlug = false
    public var lowShown: Set<Int> = []

    public init(fullShownThisPlug: Bool = false, lowShown: Set<Int> = []) {
        self.fullShownThisPlug = fullShownThisPlug
        self.lowShown = lowShown
    }
}

public enum BatteryAlertRules {
    static let lowThresholds: [(level: Int, priority: ActivityPriority)] = [(20, .high), (10, .critical)]

    public static func alerts(from old: BatterySnapshot?, to new: BatterySnapshot, session: inout BatteryAlertSession)
        -> [TransientAlert]
    {
        guard new.hasBattery, let old else { return [] }
        var out: [TransientAlert] = []
        if new.isPluggedIn, !old.isPluggedIn {
            session.lowShown = []
            out.append(alert(.charging, new.level, .green, 2.6, .normal))
        } else if !new.isPluggedIn, old.isPluggedIn {
            session.fullShownThisPlug = false
            out.append(alert(.unplugged, new.level, .neutral, 2.0, .normal))
        }
        if !new.isPluggedIn {
            for t in lowThresholds
            where old.level > t.level && new.level <= t.level && !session.lowShown.contains(t.level) {
                session.lowShown.insert(t.level)
                out.append(alert(.batteryLow, new.level, .orange, 2.6, t.priority))
            }
        } else if (new.isCharged || new.level == 100) && !session.fullShownThisPlug {
            session.fullShownThisPlug = true
            out.append(alert(.batteryFull, new.level, .green, 2.0, .normal))
        }
        return out
    }

    private static func alert(
        _ kind: AlertKind, _ level: Int, _ tint: SignalTint, _ duration: TimeInterval, _ priority: ActivityPriority
    ) -> TransientAlert {
        TransientAlert(
            id: UUID(), kind: kind, detail: .batteryLevel(level), tint: tint, duration: duration, priority: priority)
    }
}
