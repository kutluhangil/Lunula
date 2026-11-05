import AppKit
import Compression
import CoreGraphics
import Foundation
import ImageIO
import PDFKit
import UniformTypeIdentifiers
import Vision

public enum ShelfImageFormat: String, CaseIterable, Sendable {
    case png, jpeg, heic, tiff, pdf

    public var utType: UTType {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .heic: .heic
        case .tiff: .tiff
        case .pdf: .pdf
        }
    }

    public var fileExtension: String { rawValue }
}

public enum ShelfConverterError: Error {
    case unreadableSource
    case conversionFailed
    case emptyText
}

/// Offline image conversion (`ImageIO`/`PDFKit`), native ZIP archiving (`NSFileCoordinator`), and Vision OCR.
public enum ShelfConverter {
    public static func convertImage(at sourceURL: URL, to format: ShelfImageFormat, in directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ShelfConverterError.unreadableSource
        }
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let outputURL = uniqueURL(baseName: baseName, ext: format.fileExtension, in: directory)
        if format == .pdf {
            let rep = NSBitmapImageRep(cgImage: cgImage)
            let image = NSImage(size: NSSize(width: cgImage.width, height: cgImage.height))
            image.addRepresentation(rep)
            guard let page = PDFPage(image: image) else { throw ShelfConverterError.conversionFailed }
            let doc = PDFDocument()
            doc.insert(page, at: 0)
            guard doc.write(to: outputURL) else { throw ShelfConverterError.conversionFailed }
            return outputURL
        }
        guard
            let destination = CGImageDestinationCreateWithURL(
                outputURL as CFURL, format.utType.identifier as CFString, 1, nil)
        else {
            throw ShelfConverterError.conversionFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ShelfConverterError.conversionFailed
        }
        return outputURL
    }

    /// Creates a `.zip` archive in `directory` using `NSFileCoordinator.ReadingOptions.forUploading` (in-process).
    public static func createArchive(from urls: [URL], in directory: URL) throws -> URL {
        guard !urls.isEmpty else { throw ShelfConverterError.unreadableSource }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let staging = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: staging) }

        let targetToZip: URL
        let baseName: String
        if urls.count == 1, let single = urls.first {
            targetToZip = single
            baseName = single.deletingPathExtension().lastPathComponent
        } else {
            let bundleFolder = staging.appendingPathComponent("Archive")
            try FileManager.default.createDirectory(at: bundleFolder, withIntermediateDirectories: true)
            for url in urls {
                try FileManager.default.copyItem(
                    at: url, to: bundleFolder.appendingPathComponent(url.lastPathComponent))
            }
            targetToZip = bundleFolder
            baseName = "Archive"
        }

        var coordinatorError: NSError?
        var producedURL: URL?
        let outputURL = uniqueURL(baseName: baseName, ext: "zip", in: directory)
        NSFileCoordinator().coordinate(
            readingItemAt: targetToZip, options: [.forUploading], error: &coordinatorError
        ) { zipURL in
            try? FileManager.default.copyItem(at: zipURL, to: outputURL)
            producedURL = outputURL
        }
        if let coordinatorError { throw coordinatorError }
        guard let producedURL, FileManager.default.fileExists(atPath: producedURL.path()) else {
            throw ShelfConverterError.conversionFailed
        }
        return producedURL
    }

    /// Extracts text from an image file on-device via `VNRecognizeTextRequest`.
    public static func extractText(from url: URL) throws -> String {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        try handler.perform([request])
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let joined = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !joined.isEmpty else { throw ShelfConverterError.emptyText }
        return joined
    }

    /// Stages an image from the pasteboard (e.g. a ⌘⌃⇧4 screenshot) into `directory` as a draggable PNG file.
    public static func stageClipboardImage(from pasteboard: NSPasteboard = .general, in directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard
            let image = NSImage(pasteboard: pasteboard),
            let tiff = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            throw ShelfConverterError.unreadableSource
        }
        let stamp = Int(Date().timeIntervalSince1970)
        let outputURL = uniqueURL(baseName: "Screenshot-\(stamp)", ext: "png", in: directory)
        try png.write(to: outputURL, options: .atomic)
        return outputURL
    }

    /// Extracts a `.zip` archive in-process using local file headers and Darwin `Compression` (`COMPRESSION_ZLIB`).
    public static func extractArchive(at zipURL: URL, in directory: URL) throws -> URL {
        let data = try Data(contentsOf: zipURL)
        guard data.count >= 30 else { throw ShelfConverterError.unreadableSource }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let baseName = zipURL.deletingPathExtension().lastPathComponent
        let destRoot = uniqueFolderURL(baseName: baseName, in: directory)
        try FileManager.default.createDirectory(at: destRoot, withIntermediateDirectories: true)

        var offset = 0
        var extractedCount = 0
        while offset + 30 <= data.count {
            let sig = readUInt32LE(data, at: offset)
            guard sig == 0x0403_4B50 else { break }
            let flags = readUInt16LE(data, at: offset + 6)
            let method = readUInt16LE(data, at: offset + 8)
            var compSize = Int(readUInt32LE(data, at: offset + 18))
            var uncompSize = Int(readUInt32LE(data, at: offset + 22))
            let nameLen = Int(readUInt16LE(data, at: offset + 26))
            let extraLen = Int(readUInt16LE(data, at: offset + 28))
            let nameStart = offset + 30
            let dataStart = nameStart + nameLen + extraLen
            guard dataStart <= data.count else { break }

            let nameData = data.subdata(in: nameStart..<(nameStart + nameLen))
            let rawName = String(data: nameData, encoding: .utf8) ?? ""

            // If bit 3 (data descriptor) is set and sizes are 0 in local header, look up from Central Directory.
            if (flags & 0x0008) != 0 && compSize == 0 {
                if let cdSizes = findCentralDirectorySizes(in: data, fileName: rawName) {
                    compSize = cdSizes.compressed
                    uncompSize = cdSizes.uncompressed
                }
            }
            guard dataStart + compSize <= data.count else { break }

            let cleanComponents = rawName.split(separator: "/").map(String.init).filter {
                !$0.isEmpty && $0 != "." && $0 != ".."
            }
            if !cleanComponents.isEmpty && !rawName.hasPrefix("__MACOSX") {
                var targetURL = destRoot
                for part in cleanComponents {
                    targetURL.appendPathComponent(part)
                }
                if rawName.hasSuffix("/") {
                    try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true)
                } else {
                    try FileManager.default.createDirectory(
                        at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    let payload = data.subdata(in: dataStart..<(dataStart + compSize))
                    if method == 0 {
                        try payload.write(to: targetURL, options: .atomic)
                        extractedCount += 1
                    } else if method == 8 {
                        let decoded = try inflateRawDeflate(payload, expectedSize: max(uncompSize, compSize * 4, 4096))
                        try decoded.write(to: targetURL, options: .atomic)
                        extractedCount += 1
                    }
                }
            }

            offset = dataStart + compSize
            // Skip optional 12- or 16-byte data descriptor if present
            if (flags & 0x0008) != 0 && offset + 4 <= data.count {
                if readUInt32LE(data, at: offset) == 0x0807_4B50 {
                    offset += 16
                } else if readUInt32LE(data, at: offset) != 0x0403_4B50
                    && readUInt32LE(data, at: offset) != 0x0201_4B50
                {
                    offset += 12
                }
            }
        }
        guard extractedCount > 0 else { throw ShelfConverterError.conversionFailed }
        return destRoot
    }

    private static func inflateRawDeflate(_ payload: Data, expectedSize: Int) throws -> Data {
        if payload.isEmpty { return Data() }
        var capacity = max(expectedSize, 4096)
        for _ in 0..<6 {
            var destination = Data(count: capacity)
            let decodedBytes = payload.withUnsafeBytes { srcPtr -> Int in
                guard let srcBase = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
                return destination.withUnsafeMutableBytes { dstPtr -> Int in
                    guard let dstBase = dstPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
                    return compression_decode_buffer(
                        dstBase, capacity, srcBase, payload.count, nil, COMPRESSION_ZLIB)
                }
            }
            if decodedBytes > 0 && decodedBytes < capacity {
                destination.count = decodedBytes
                return destination
            }
            capacity *= 2
        }
        throw ShelfConverterError.conversionFailed
    }

    private static func findCentralDirectorySizes(in data: Data, fileName: String)
        -> (compressed: Int, uncompressed: Int)?
    {
        var idx = max(0, data.count - 65_536)
        while idx + 46 <= data.count {
            if readUInt32LE(data, at: idx) == 0x0201_4B50 {
                let comp = Int(readUInt32LE(data, at: idx + 20))
                let uncomp = Int(readUInt32LE(data, at: idx + 24))
                let nLen = Int(readUInt16LE(data, at: idx + 28))
                let eLen = Int(readUInt16LE(data, at: idx + 30))
                let cLen = Int(readUInt16LE(data, at: idx + 32))
                guard idx + 46 + nLen <= data.count else { break }
                let name = String(data: data.subdata(in: (idx + 46)..<(idx + 46 + nLen)), encoding: .utf8) ?? ""
                if name == fileName {
                    return (comp, uncomp)
                }
                idx += 46 + nLen + eLen + cLen
            } else {
                idx += 1
            }
        }
        return nil
    }

    private static func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }

    private static func uniqueFolderURL(baseName: String, in directory: URL) -> URL {
        var candidate = directory.appendingPathComponent(baseName)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path()) {
            candidate = directory.appendingPathComponent("\(baseName)-\(index)")
            index += 1
        }
        return candidate
    }

    private static func uniqueURL(baseName: String, ext: String, in directory: URL) -> URL {
        var candidate = directory.appendingPathComponent("\(baseName).\(ext)")
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path()) {
            candidate = directory.appendingPathComponent("\(baseName)-\(index).\(ext)")
            index += 1
        }
        return candidate
    }
}
