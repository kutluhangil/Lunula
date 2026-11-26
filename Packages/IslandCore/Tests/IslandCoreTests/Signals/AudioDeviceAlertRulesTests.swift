import Foundation
import Testing

@testable import IslandCore

@Suite struct AudioDeviceAlertRulesTests {
    @Test func newlyConnectedFiltersBuiltInVirtualAndExisting() {
        let builtIn = AudioDeviceInfo(id: 1, name: "MacBook Pro Speakers", transport: .builtIn)
        let existingBT = AudioDeviceInfo(id: 2, name: "AirPods Pro", transport: .bluetooth)
        let newBT = AudioDeviceInfo(id: 3, name: "WH-1000XM5", transport: .bluetooth, batteryLevel: 85)
        let newVirtual = AudioDeviceInfo(id: 4, name: "BlackHole 2ch", transport: .virtual)
        let newUSB = AudioDeviceInfo(id: 5, name: "USB DAC", transport: .usb)

        let added = AudioDeviceAlertRules.newlyConnected(
            previous: [builtIn, existingBT],
            current: [builtIn, existingBT, newBT, newVirtual, newUSB])
        #expect(added == [newBT, newUSB])
    }

    @Test func symbolsMatchDeviceNamesAndTransports() {
        #expect(
            AudioDeviceAlertRules.symbol(for: AudioDeviceInfo(id: 1, name: "AirPods Max", transport: .bluetooth))
                == "airpodsmax")
        #expect(
            AudioDeviceAlertRules.symbol(
                for: AudioDeviceInfo(id: 2, name: "Kutluhan's AirPods Pro", transport: .bluetooth))
                == "airpodspro")
        #expect(
            AudioDeviceAlertRules.symbol(for: AudioDeviceInfo(id: 3, name: "AirPods", transport: .bluetooth))
                == "airpods.gen3")
        #expect(
            AudioDeviceAlertRules.symbol(for: AudioDeviceInfo(id: 4, name: "Living Room", transport: .airPlay))
                == "airplayaudio")
        #expect(
            AudioDeviceAlertRules.symbol(for: AudioDeviceInfo(id: 5, name: "Sony WH-1000XM5", transport: .bluetooth))
                == "headphones")
    }

    @Test func batteryMatcherMatchesExactAndSubstringCaseInsensitively() {
        let batteries = ["AirPods Pro": 92, "Magic Keyboard": 74]
        #expect(AudioDeviceAlertRules.matchBattery(deviceName: "airpods pro", batteries: batteries) == 92)
        #expect(AudioDeviceAlertRules.matchBattery(deviceName: "Kutluhan's AirPods Pro", batteries: batteries) == 92)
        #expect(AudioDeviceAlertRules.matchBattery(deviceName: "Unknown Headset", batteries: batteries) == nil)
    }

    @Test func alertIncludesBatteryWhenAvailable() {
        let device = AudioDeviceInfo(id: 9, name: "AirPods Pro", transport: .bluetooth, batteryLevel: 88)
        let alert = AudioDeviceAlertRules.alert(for: device, connectedSubtitle: "Bağlandı")
        #expect(alert.kind == .custom && alert.tint == .green)
        if case .text(let title, let subtitle, let symbol) = alert.detail {
            #expect(title == "AirPods Pro" && subtitle == "Bağlandı · 88%" && symbol == "airpodspro")
        } else {
            Issue.record("Expected text alert detail")
        }
    }
}
