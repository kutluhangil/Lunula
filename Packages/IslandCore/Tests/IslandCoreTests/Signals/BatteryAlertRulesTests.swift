import Foundation
import Testing

@testable import IslandCore

@Suite struct BatteryAlertRulesTests {
    func b(_ level: Int, plugged: Bool, charged: Bool = false, hasBattery: Bool = true) -> BatterySnapshot {
        .init(
            level: level, isCharging: plugged && !charged, isPluggedIn: plugged, isCharged: charged,
            isLowPowerMode: false, hasBattery: hasBattery)
    }

    @Test func firstSnapshotEmitsNothing() {
        var s = BatteryAlertSession()
        #expect(BatteryAlertRules.alerts(from: nil, to: b(50, plugged: true), session: &s).isEmpty)
    }

    @Test func pluggingInRaisesChargingAlert() {
        var s = BatteryAlertSession()
        #expect(
            BatteryAlertRules.alerts(from: b(50, plugged: false), to: b(50, plugged: true), session: &s).map(\.kind)
                == [.charging])
    }

    @Test func unpluggingRaisesUnpluggedAlert() {
        var s = BatteryAlertSession()
        #expect(
            BatteryAlertRules.alerts(from: b(50, plugged: true), to: b(50, plugged: false), session: &s).map(\.kind)
                == [.unplugged])
    }

    @Test func crossing20DownRaisesLowOnce() {
        var s = BatteryAlertSession()
        #expect(
            BatteryAlertRules.alerts(from: b(21, plugged: false), to: b(20, plugged: false), session: &s).map(\.kind)
                == [.batteryLow])
        #expect(BatteryAlertRules.alerts(from: b(20, plugged: false), to: b(19, plugged: false), session: &s).isEmpty)
    }

    @Test func crossing10DownRaisesCriticalLow() {
        var s = BatteryAlertSession(lowShown: [20])
        #expect(
            BatteryAlertRules.alerts(from: b(11, plugged: false), to: b(10, plugged: false), session: &s).first?
                .priority == .critical)
    }

    @Test func noLowAlertWhileCharging() {
        var s = BatteryAlertSession()
        #expect(BatteryAlertRules.alerts(from: b(21, plugged: true), to: b(20, plugged: true), session: &s).isEmpty)
    }

    @Test func fullAlertOncePerPlugSession() {
        var s = BatteryAlertSession()
        #expect(
            BatteryAlertRules.alerts(from: b(99, plugged: true), to: b(100, plugged: true, charged: true), session: &s)
                .map(\.kind) == [.batteryFull])
        #expect(
            BatteryAlertRules.alerts(
                from: b(100, plugged: true, charged: true), to: b(100, plugged: true, charged: true), session: &s
            ).isEmpty)
    }

    @Test func desktopWithoutBatteryEmitsNothing() {
        var s = BatteryAlertSession()
        #expect(
            BatteryAlertRules.alerts(
                from: b(0, plugged: false, hasBattery: false), to: b(0, plugged: true, hasBattery: false), session: &s
            ).isEmpty)
    }
}
