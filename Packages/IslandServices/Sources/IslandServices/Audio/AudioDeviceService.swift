import CoreAudio
import Foundation
import Observation

public struct AudioOutputDevice: Identifiable, Equatable, Sendable {
    public var id: UInt32
    public var name: String
    public var isCurrent: Bool

    public init(id: UInt32, name: String, isCurrent: Bool) {
        self.id = id
        self.name = name
        self.isCurrent = isCurrent
    }
}

/// CoreAudio adapter for system-wide microphone mute and default audio output device switching.
@MainActor @Observable public final class AudioDeviceService {
    public private(set) var isInputMuted = false
    public private(set) var outputDevices: [AudioOutputDevice] = []

    public init() {
        refresh()
    }

    public func refresh() {
        isInputMuted = Self.readDefaultInputMute()
        outputDevices = Self.readOutputDevices()
    }

    @discardableResult
    public func toggleInputMute() -> Bool {
        let next = !Self.readDefaultInputMute()
        Self.setDefaultInputMute(next)
        isInputMuted = Self.readDefaultInputMute()
        return isInputMuted
    }

    public func selectOutputDevice(_ id: UInt32) {
        var deviceID = AudioDeviceID(id)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size), &deviceID)
        outputDevices = Self.readOutputDevices()
    }

    // MARK: - CoreAudio Helpers

    private static func defaultDevice(selector: AudioObjectPropertySelector) -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return status == noErr && deviceID != 0 ? deviceID : nil
    }

    private static func readDefaultInputMute() -> Bool {
        guard let input = defaultDevice(selector: kAudioHardwarePropertyDefaultInputDevice) else { return false }
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: element)
            if AudioObjectHasProperty(input, &address),
                AudioObjectGetPropertyData(input, &address, 0, nil, &size, &muted) == noErr
            {
                return muted != 0
            }
        }
        return false
    }

    private static func setDefaultInputMute(_ mute: Bool) {
        guard let input = defaultDevice(selector: kAudioHardwarePropertyDefaultInputDevice) else { return }
        var value: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: element)
            if AudioObjectHasProperty(input, &address) {
                AudioObjectSetPropertyData(input, &address, 0, nil, size, &value)
            }
        }
    }

    private static func readOutputDevices() -> [AudioOutputDevice] {
        let currentOutput = defaultDevice(selector: kAudioHardwarePropertyDefaultOutputDevice)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        guard
            AudioObjectGetPropertyDataSize(
                AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr,
            dataSize > 0
        else { return [] }
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &ids) == noErr
        else { return [] }
        return ids.compactMap { id -> AudioOutputDevice? in
            guard hasOutputStreams(id), let name = deviceName(id) else { return nil }
            return AudioOutputDevice(id: id, name: name, isCurrent: id == currentOutput)
        }
    }

    private static func hasOutputStreams(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr && size > 0
    }

    private static func deviceName(_ id: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name) == noErr,
            let resolved = name?.takeUnretainedValue() as String?
        else { return nil }
        return resolved
    }
}
