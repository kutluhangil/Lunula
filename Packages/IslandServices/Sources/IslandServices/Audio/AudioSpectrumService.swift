import Accelerate
import AudioToolbox
import CoreAudio
import Foundation
import IslandCore
import Observation
import os

public enum AudioSpectrumMath {
    public static let bandCount = 8

    /// Windowed `vDSP` DFT magnitude spectrum bucketed logarithmically into 8 normalized `0...1` bands.
    public static func computeBands(samples: [Float]) -> [Double] {
        let fftLength: Int
        if samples.count >= 512 {
            fftLength = 512
        } else if samples.count >= 256 {
            fftLength = 256
        } else {
            return Array(repeating: 0, count: bandCount)
        }

        let slice = Array(samples.suffix(fftLength))
        var peakSample: Float = 0
        vDSP_maxmgv(slice, 1, &peakSample, vDSP_Length(fftLength))
        guard peakSample > 1e-6, peakSample.isFinite else {
            return Array(repeating: 0, count: bandCount)
        }

        guard let dftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftLength), .FORWARD) else {
            return Array(repeating: 0, count: bandCount)
        }
        defer { vDSP_DFT_DestroySetup(dftSetup) }

        var window = [Float](repeating: 0, count: fftLength)
        vDSP_hann_window(&window, vDSP_Length(fftLength), Int32(vDSP_HANN_NORM))

        var windowed = [Float](repeating: 0, count: fftLength)
        vDSP_vmul(slice, 1, window, 1, &windowed, 1, vDSP_Length(fftLength))

        let zeroImag = [Float](repeating: 0, count: fftLength)
        var outReal = [Float](repeating: 0, count: fftLength)
        var outImag = [Float](repeating: 0, count: fftLength)
        vDSP_DFT_Execute(dftSetup, windowed, zeroImag, &outReal, &outImag)

        let halfCount = fftLength / 2
        var magnitudes = [Float](repeating: 0, count: halfCount)
        vDSP_vdist(outReal, 1, outImag, 1, &magnitudes, 1, vDSP_Length(halfCount))

        var scale = 2.0 / Float(fftLength)
        vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(halfCount))

        var result = [Double](repeating: 0, count: bandCount)
        var previousBin = 1
        for band in 0..<bandCount {
            let startBin = min(previousBin, halfCount - 1)
            let rawUpper = Int(pow(Double(halfCount), Double(band + 1) / Double(bandCount)).rounded())
            let endBin =
                band == bandCount - 1
                ? halfCount
                : min(max(startBin + 1, rawUpper), halfCount)
            previousBin = endBin

            var bandMax: Float = 0
            let count = endBin - startBin
            if count > 0 {
                magnitudes.withUnsafeBufferPointer { buf in
                    if let base = buf.baseAddress {
                        vDSP_maxv(base.advanced(by: startBin), 1, &bandMax, vDSP_Length(count))
                    }
                }
            }

            // Gentle high-frequency tilt compensates natural ~3 dB/octave musical roll-off.
            let tilt = 1.0 + Double(band) * 0.22
            let boosted = Double(bandMax) * tilt
            guard boosted > 1e-6 else {
                result[band] = 0
                continue
            }
            let decibels = 20.0 * log10(boosted)
            let normalized = (decibels + 46.0) / 44.0
            result[band] = min(max(normalized, 0.0), 1.0)
        }
        return result
    }

    /// Deterministic organic 8-bar fallback wave used when live audio tap is disabled or silent.
    public static func simulatedBands(at timestamp: TimeInterval, isPlaying: Bool) -> [Double] {
        guard isPlaying else {
            return Array(repeating: 0, count: bandCount)
        }
        let envelope: [Double] = [0.72, 0.90, 1.00, 0.86, 0.78, 0.68, 0.56, 0.44]
        return (0..<bandCount).map { index in
            let phase = Double(index) * 0.73
            let primary = sin(timestamp * 4.2 + phase) * 0.5 + 0.5
            let secondary = sin(timestamp * 6.7 - phase * 1.35 + 1.1) * 0.5 + 0.5
            let shimmer = cos(timestamp * 2.3 + Double(index) * 1.15) * 0.5 + 0.5
            let blended = (primary * 0.50 + secondary * 0.32 + shimmer * 0.18) * envelope[index]
            return min(max(0.14 + blended * 0.82, 0.0), 1.0)
        }
    }
}

private struct TapHandles: @unchecked Sendable {
    var tapID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    var aggregateDeviceID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    var ioProcID: AudioDeviceIOProcID?

    var isInstalled: Bool {
        tapID != kAudioObjectUnknown && aggregateDeviceID != kAudioObjectUnknown && ioProcID != nil
    }
}

/// CoreAudio Process Tap + `vDSP` live 8-band spectrum analyzer with automatic organic fallback and zero idle CPU.
@MainActor @Observable public final class AudioSpectrumService {
    private static let sampleCapacity = 512
    private static let refreshInterval: TimeInterval = 0.08
    private static let silenceFloor = 0.005

    @ObservationIgnored private let time: any IslandTime
    @ObservationIgnored private let sampleLock = OSAllocatedUnfairLock<[Float]>(
        initialState: Array(repeating: 0, count: AudioSpectrumService.sampleCapacity))
    @ObservationIgnored private let handlesLock = OSAllocatedUnfairLock<TapHandles>(initialState: TapHandles())
    @ObservationIgnored private var tickToken: ScheduledToken?

    public private(set) var bands: [Double] = Array(repeating: 0, count: AudioSpectrumMath.bandCount)
    public private(set) var isUsingLiveTap = false
    public private(set) var isActive = false
    public var isPlaying: Bool = false

    public init(time: any IslandTime = SystemTime()) {
        self.time = time
    }

    deinit {
        let handles = handlesLock.withLock { state -> TapHandles in
            let current = state
            state = TapHandles()
            return current
        }
        Self.teardownHandles(handles)
    }

    public func updatePlayback(isPlaying: Bool) {
        self.isPlaying = isPlaying
        if !isPlaying {
            bands = Array(repeating: 0, count: AudioSpectrumMath.bandCount)
            isUsingLiveTap = false
        } else if isActive {
            refreshBands()
        }
    }

    public func start(liveTapAllowed: Bool, isPlaying: Bool = true) {
        self.isPlaying = isPlaying
        if liveTapAllowed {
            let alreadyInstalled = handlesLock.withLock { $0.isInstalled }
            if !alreadyInstalled {
                installLiveTap()
            }
        } else {
            teardownTapIfNeeded()
        }

        isActive = true
        refreshBands()
        if tickToken == nil {
            scheduleNextTick()
        }
    }

    public func stop() {
        tickToken?.cancel()
        tickToken = nil
        isActive = false
        isUsingLiveTap = false
        bands = Array(repeating: 0, count: AudioSpectrumMath.bandCount)
        teardownTapIfNeeded()
        sampleLock.withLock { storage in
            for index in storage.indices {
                storage[index] = 0
            }
        }
    }

    // MARK: - Refresh Loop

    private func scheduleNextTick() {
        guard isActive else { return }
        tickToken = time.schedule(after: Self.refreshInterval) { [weak self] in
            guard let self, self.isActive else { return }
            self.refreshBands()
            self.scheduleNextTick()
        }
    }

    private func refreshBands() {
        guard isPlaying else {
            bands = Array(repeating: 0, count: AudioSpectrumMath.bandCount)
            isUsingLiveTap = false
            return
        }

        let tapInstalled = handlesLock.withLock { $0.isInstalled }
        if tapInstalled {
            let snapshot = sampleLock.withLock { $0 }
            let computed = AudioSpectrumMath.computeBands(samples: snapshot)
            if (computed.max() ?? 0) >= Self.silenceFloor {
                bands = zip(bands, computed).map { previous, current in
                    min(max(previous * 0.30 + current * 0.70, 0.0), 1.0)
                }
                isUsingLiveTap = true
                return
            }
        }

        isUsingLiveTap = false
        bands = AudioSpectrumMath.simulatedBands(
            at: time.now.timeIntervalSinceReferenceDate,
            isPlaying: true)
    }

    // MARK: - CoreAudio Process Tap

    private func installLiveTap() {
        let tapDescription = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
        tapDescription.name = "Lunula Spectrum Tap"

        var createdTapID = AudioObjectID(kAudioObjectUnknown)
        guard AudioHardwareCreateProcessTap(tapDescription, &createdTapID) == noErr,
            createdTapID != kAudioObjectUnknown
        else {
            return
        }

        let tapUID = Self.readTapUID(tapID: createdTapID) ?? tapDescription.uuid.uuidString
        let aggregateUID = "com.kutluhangul.lunula.spectrum.\(UUID().uuidString)"
        let subTap: [String: Any] = [
            kAudioSubTapUIDKey: tapUID,
            kAudioSubTapDriftCompensationKey: true,
        ]
        let aggregateDescription: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Lunula Spectrum Aggregate",
            kAudioAggregateDeviceUIDKey: aggregateUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceTapListKey: [subTap],
        ]

        var createdAggregateID = AudioObjectID(kAudioObjectUnknown)
        guard
            AudioHardwareCreateAggregateDevice(aggregateDescription as CFDictionary, &createdAggregateID) == noErr,
            createdAggregateID != kAudioObjectUnknown
        else {
            AudioHardwareDestroyProcessTap(createdTapID)
            return
        }

        let sampleBuffer = sampleLock
        let capacity = Self.sampleCapacity
        var createdIOProcID: AudioDeviceIOProcID?
        let ioStatus = AudioDeviceCreateIOProcIDWithBlock(&createdIOProcID, createdAggregateID, nil) {
            _, inInputData, _, _, _ in
            let bufferList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inInputData))
            guard
                let first = bufferList.first,
                let rawData = first.mData,
                first.mDataByteSize >= UInt32(MemoryLayout<Float>.size)
            else { return }

            let totalFloats = Int(first.mDataByteSize) / MemoryLayout<Float>.size
            let copyCount = min(totalFloats, capacity)
            guard copyCount > 0 else { return }

            let floatPtr = rawData.assumingMemoryBound(to: Float.self)
            let startOffset = totalFloats - copyCount
            _ = sampleBuffer.withLockIfAvailableUnchecked { ring in
                if copyCount == capacity {
                    for index in 0..<copyCount {
                        ring[index] = floatPtr[startOffset + index]
                    }
                } else {
                    let keep = capacity - copyCount
                    for index in 0..<keep {
                        ring[index] = ring[index + copyCount]
                    }
                    for index in 0..<copyCount {
                        ring[keep + index] = floatPtr[startOffset + index]
                    }
                }
            }
        }

        guard ioStatus == noErr, let ioProcID = createdIOProcID else {
            AudioHardwareDestroyAggregateDevice(createdAggregateID)
            AudioHardwareDestroyProcessTap(createdTapID)
            return
        }

        guard AudioDeviceStart(createdAggregateID, ioProcID) == noErr else {
            AudioDeviceDestroyIOProcID(createdAggregateID, ioProcID)
            AudioHardwareDestroyAggregateDevice(createdAggregateID)
            AudioHardwareDestroyProcessTap(createdTapID)
            return
        }

        let tapID = createdTapID
        let aggregateID = createdAggregateID
        handlesLock.withLock { state in
            state = TapHandles(
                tapID: tapID,
                aggregateDeviceID: aggregateID,
                ioProcID: ioProcID)
        }
    }

    private func teardownTapIfNeeded() {
        let handles = handlesLock.withLock { state -> TapHandles in
            let current = state
            state = TapHandles()
            return current
        }
        Self.teardownHandles(handles)
    }

    private nonisolated static func teardownHandles(_ handles: TapHandles) {
        if handles.aggregateDeviceID != kAudioObjectUnknown, let ioProcID = handles.ioProcID {
            _ = AudioDeviceStop(handles.aggregateDeviceID, ioProcID)
            _ = AudioDeviceDestroyIOProcID(handles.aggregateDeviceID, ioProcID)
        }
        if handles.aggregateDeviceID != kAudioObjectUnknown {
            _ = AudioHardwareDestroyAggregateDevice(handles.aggregateDeviceID)
        }
        if handles.tapID != kAudioObjectUnknown {
            _ = AudioHardwareDestroyProcessTap(handles.tapID)
        }
    }

    private nonisolated static func readTapUID(tapID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var cfUID: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard
            AudioObjectGetPropertyData(tapID, &address, 0, nil, &size, &cfUID) == noErr,
            let resolved = cfUID?.takeRetainedValue() as String?
        else {
            return nil
        }
        return resolved
    }
}
