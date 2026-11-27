import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum GIFExporterError: Error, Sendable {
    case emptyFrames
    case destinationCreationFailed
    case finalizeFailed
    case noFramesExtracted
}

public enum GIFExporter {
    private static let maxClipDurationSeconds = 15.0

    public static func encodeGIF(
        frames: [CGImage],
        frameDelay: Double = 0.1,
        to destinationURL: URL
    ) throws {
        guard !frames.isEmpty else {
            throw GIFExporterError.emptyFrames
        }
        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard
            let destination = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                UTType.gif.identifier as CFString,
                frames.count,
                nil
            )
        else {
            throw GIFExporterError.destinationCreationFailed
        }

        let fileProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        let clampedDelay = max(0.02, frameDelay)
        let frameProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFUnclampedDelayTime: clampedDelay,
                kCGImagePropertyGIFDelayTime: clampedDelay,
            ]
        ]

        for frame in frames {
            CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFExporterError.finalizeFailed
        }
    }

    public static func convertVideoToGIF(
        videoURL: URL,
        maxFPS: Int = 10,
        maxDimension: CGFloat = 640
    ) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let rawDuration = try await asset.load(.duration)
        let rawSeconds = CMTimeGetSeconds(rawDuration)
        let durationSeconds: Double
        if rawSeconds.isFinite && rawSeconds > 0 {
            durationSeconds = min(rawSeconds, maxClipDurationSeconds)
        } else {
            durationSeconds = 1.0
        }

        let fps = max(1, min(maxFPS, 30))
        let frameDelay = 1.0 / Double(fps)
        let sampleCount = max(1, Int((durationSeconds * Double(fps)).rounded(.up)))

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)
        let tolerance = CMTime(seconds: frameDelay * 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance

        let requestedTimes = (0..<sampleCount).map { index -> CMTime in
            let timestamp = min(Double(index) * frameDelay, max(0, durationSeconds - 0.01))
            return CMTime(seconds: timestamp, preferredTimescale: 600)
        }

        var frames: [CGImage] = []
        frames.reserveCapacity(sampleCount)

        for await element in generator.images(for: requestedTimes) {
            try Task.checkCancellation()
            if case .success(_, let cgImage, _) = element {
                frames.append(cgImage)
            }
        }

        guard !frames.isEmpty else {
            throw GIFExporterError.noFramesExtracted
        }

        let baseName = videoURL.deletingPathExtension().lastPathComponent
        let safeBaseName = baseName.isEmpty ? "Lunula-Recording" : baseName
        let capturedFrames = frames
        return try await Task.detached(priority: .userInitiated) {
            let outputURL = Self.uniqueTemporaryGIFURL(baseName: safeBaseName)
            try Self.encodeGIF(frames: capturedFrames, frameDelay: frameDelay, to: outputURL)
            return outputURL
        }.value
    }

    private static func uniqueTemporaryGIFURL(baseName: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        var candidate = tempDir.appendingPathComponent("\(baseName).gif")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path()) {
            candidate = tempDir.appendingPathComponent("\(baseName)-\(suffix).gif")
            suffix += 1
        }
        return candidate
    }
}
