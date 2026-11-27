import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import Observation
import ScreenCaptureKit
import os

private final class RecordingDelegateRelay: NSObject, SCRecordingOutputDelegate, SCStreamDelegate, @unchecked Sendable {
    private struct State: Sendable {
        var didFinish = false
        var failureMessage: String?
        var continuation: CheckedContinuation<String?, Never>?
    }

    private let stateLock = OSAllocatedUnfairLock<State>(initialState: State())

    func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        complete(errorMessage: nil)
    }

    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: any Error) {
        complete(errorMessage: error.localizedDescription)
    }

    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        complete(errorMessage: error.localizedDescription)
    }

    func waitForCompletion(timeoutSeconds: Double = 2.5) async -> String? {
        let timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeoutSeconds))
            self?.complete(errorMessage: nil)
        }
        defer { timeoutTask.cancel() }

        return await withCheckedContinuation { continuation in
            let immediateResult: (alreadyFinished: Bool, message: String?) = stateLock.withLock { state in
                if state.didFinish {
                    return (true, state.failureMessage)
                }
                state.continuation = continuation
                return (false, nil)
            }
            if immediateResult.alreadyFinished {
                continuation.resume(returning: immediateResult.message)
            }
        }
    }

    private func complete(errorMessage: String?) {
        let pending = stateLock.withLock { state -> (CheckedContinuation<String?, Never>?, String?) in
            guard !state.didFinish else { return (nil, state.failureMessage) }
            state.didFinish = true
            if let errorMessage, state.failureMessage == nil {
                state.failureMessage = errorMessage
            }
            let cont = state.continuation
            state.continuation = nil
            return (cont, state.failureMessage)
        }
        pending.0?.resume(returning: pending.1)
    }
}

private enum ScreenCaptureStartError: LocalizedError, Sendable {
    case noShareableDisplay

    var errorDescription: String? {
        switch self {
        case .noShareableDisplay:
            "No shareable display available."
        }
    }
}

private final class CaptureSessionBox: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock<(stream: SCStream?, output: SCRecordingOutput?)>(
        uncheckedState: (nil, nil)
    )

    func start(cropRect: CGRect?, mp4URL: URL, relay: RecordingDelegateRelay) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw ScreenCaptureStartError.noShareableDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let streamConfig = SCStreamConfiguration()
        if let cropRect, cropRect.width >= 16, cropRect.height >= 16 {
            streamConfig.sourceRect = cropRect
            streamConfig.width = Self.evenDimension(Int(cropRect.width.rounded()))
            streamConfig.height = Self.evenDimension(Int(cropRect.height.rounded()))
        } else {
            streamConfig.width = Self.evenDimension(display.width)
            streamConfig.height = Self.evenDimension(display.height)
        }
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        streamConfig.showsCursor = true
        streamConfig.capturesAudio = false

        let recordingConfig = SCRecordingOutputConfiguration()
        recordingConfig.outputURL = mp4URL
        recordingConfig.outputFileType = .mp4

        let output = SCRecordingOutput(configuration: recordingConfig, delegate: relay)
        let createdStream = SCStream(filter: filter, configuration: streamConfig, delegate: relay)
        try createdStream.addRecordingOutput(output)
        try await createdStream.startCapture()

        lock.withLockUnchecked { state in
            state = (createdStream, output)
        }
    }

    func stop() async throws {
        let activeStream = lock.withLockUnchecked { state -> SCStream? in
            let current = state.stream
            state = (nil, nil)
            return current
        }
        guard let activeStream else { return }
        try await activeStream.stopCapture()
    }

    private static func evenDimension(_ raw: Int) -> Int {
        let clamped = max(2, raw)
        return clamped.isMultiple(of: 2) ? clamped : clamped + 1
    }
}

/// On-demand ScreenCaptureKit MP4 & animated GIF recorder. Never triggers TCC prompts until `startRecording` is called.
@MainActor @Observable public final class ScreenRecorderService: NSObject {
    public enum RecordingFormat: String, Codable, Equatable, Sendable, CaseIterable {
        case mp4
        case gif
    }

    private struct ActiveSession {
        let box: CaptureSessionBox
        let relay: RecordingDelegateRelay
        let mp4URL: URL
        let format: RecordingFormat
    }

    @ObservationIgnored private var activeSession: ActiveSession?

    public nonisolated static var hasScreenCaptureAccess: Bool {
        CGPreflightScreenCaptureAccess()
    }

    public private(set) var isRecording = false
    public private(set) var startedAt: Date?
    public private(set) var lastError: String?
    public private(set) var activeFormat: RecordingFormat = .mp4

    public override init() {
        super.init()
    }

    public func startRecording(format: RecordingFormat, cropRect: CGRect? = nil) async -> Bool {
        guard !isRecording else { return false }
        lastError = nil

        let mp4URL = Self.makeTemporaryRecordingURL()
        let relay = RecordingDelegateRelay()
        let box = CaptureSessionBox()
        do {
            try await box.start(cropRect: cropRect, mp4URL: mp4URL, relay: relay)
            activeSession = ActiveSession(
                box: box,
                relay: relay,
                mp4URL: mp4URL,
                format: format
            )
            activeFormat = format
            startedAt = Date()
            isRecording = true
            return true
        } catch {
            try? FileManager.default.removeItem(at: mp4URL)
            activeSession = nil
            isRecording = false
            startedAt = nil
            lastError = error.localizedDescription
            return false
        }
    }

    public func stopRecording() async -> URL? {
        guard isRecording, let session = activeSession else { return nil }
        activeSession = nil
        isRecording = false
        startedAt = nil

        do {
            try await session.box.stop()
        } catch {
            // Even if stopCapture reports an already-stopped stream, wait briefly for output finalization.
            lastError = error.localizedDescription
        }

        if let relayFailure = await session.relay.waitForCompletion() {
            lastError = relayFailure
        }

        guard FileManager.default.fileExists(atPath: session.mp4URL.path()) else {
            return nil
        }

        switch session.format {
        case .mp4:
            return session.mp4URL
        case .gif:
            do {
                let gifURL = try await GIFExporter.convertVideoToGIF(videoURL: session.mp4URL)
                try? FileManager.default.removeItem(at: session.mp4URL)
                return gifURL
            } catch {
                try? FileManager.default.removeItem(at: session.mp4URL)
                lastError = error.localizedDescription
                return nil
            }
        }
    }

    private static func makeTemporaryRecordingURL() -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let token = UUID().uuidString.prefix(6)
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("Lunula-Recording-\(stamp)-\(token).mp4")
    }
}
