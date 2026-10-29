import CoreAudio
import CoreMediaIO
import Foundation

public protocol DeviceUsageReading: AnyObject {
    var onChange: (() -> Void)? { get set }
    func cameraInUse() -> Bool
    func microphoneInUse() -> Bool
    func start()
    func stop()
}

/// "Running somewhere" flags from CoreAudio (inputs) and CoreMediaIO (cameras). Reading these hardware properties
/// needs no camera/microphone permission and shows no prompt (spike: docs/qa/spikes/camera-microphone-indicator.md).
public final class SystemDeviceUsageReader: DeviceUsageReading {
    public var onChange: (() -> Void)?
    private var audioListeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
    private var cameraListeners: [(CMIOObjectID, CMIOObjectPropertyAddress, CMIOObjectPropertyListenerBlock)] = []

    public init() {}

    public func start() {
        stop()
        let notify: () -> Void = { [weak self] in self?.onChange?() }
        let rescan: () -> Void = { [weak self] in
            self?.start()
            self?.onChange?()
        }
        listenAudio(AudioObjectID(kAudioObjectSystemObject), Self.audio(kAudioHardwarePropertyDevices), rescan)
        for device in inputDevices() {
            listenAudio(device, Self.audio(kAudioDevicePropertyDeviceIsRunningSomewhere), notify)
        }
        listenCamera(
            CMIOObjectID(kCMIOObjectSystemObject), Self.cmio(CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices)),
            rescan)
        for device in cameras() {
            listenCamera(
                device, Self.cmio(CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere)), notify)
        }
    }

    public func stop() {
        for (id, address, block) in audioListeners {
            var a = address
            AudioObjectRemovePropertyListenerBlock(id, &a, .main, block)
        }
        for (id, address, block) in cameraListeners {
            var a = address
            CMIOObjectRemovePropertyListenerBlock(id, &a, .main, block)
        }
        audioListeners = []
        cameraListeners = []
    }

    public func microphoneInUse() -> Bool {
        inputDevices().contains { audioUInt32($0, Self.audio(kAudioDevicePropertyDeviceIsRunningSomewhere)) != 0 }
    }

    public func cameraInUse() -> Bool {
        cameras().contains {
            var address = Self.cmio(CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere))
            var value: UInt32 = 0
            var used: UInt32 = 0
            return CMIOObjectGetPropertyData($0, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &used, &value)
                == noErr && value != 0
        }
    }

    // MARK: - CoreAudio

    private static func audio(
        _ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    )
        -> AudioObjectPropertyAddress
    {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    private func inputDevices() -> [AudioObjectID] {
        var address = Self.audio(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.filter { id in
            var streams = Self.audio(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeInput)
            var streamSize: UInt32 = 0
            return AudioObjectGetPropertyDataSize(id, &streams, 0, nil, &streamSize) == noErr && streamSize > 0
        }
    }

    private func audioUInt32(_ id: AudioObjectID, _ address: AudioObjectPropertyAddress) -> UInt32 {
        var a = address
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(id, &a, 0, nil, &size, &value) == noErr ? value : 0
    }

    private func listenAudio(_ id: AudioObjectID, _ address: AudioObjectPropertyAddress, _ action: @escaping () -> Void)
    {
        var a = address
        let block: AudioObjectPropertyListenerBlock = { _, _ in action() }
        if AudioObjectAddPropertyListenerBlock(id, &a, .main, block) == noErr {
            audioListeners.append((id, address, block))
        }
    }

    // MARK: - CoreMediaIO

    private static func cmio(_ selector: CMIOObjectPropertySelector) -> CMIOObjectPropertyAddress {
        CMIOObjectPropertyAddress(
            mSelector: selector, mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    }

    private func cameras() -> [CMIOObjectID] {
        var address = Self.cmio(CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices))
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, size, &used, &ids) == noErr else { return [] }
        return ids
    }

    private func listenCamera(_ id: CMIOObjectID, _ address: CMIOObjectPropertyAddress, _ action: @escaping () -> Void)
    {
        var a = address
        let block: CMIOObjectPropertyListenerBlock = { _, _ in action() }
        if CMIOObjectAddPropertyListenerBlock(id, &a, .main, block) == noErr {
            cameraListeners.append((id, address, block))
        }
    }
}
