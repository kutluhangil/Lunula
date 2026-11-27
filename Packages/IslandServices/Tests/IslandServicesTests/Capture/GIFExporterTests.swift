import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import IslandServices

@Suite struct GIFExporterTests {
    @Test func encodesThreeFrameAnimatedGIF() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let frames = try [
            Self.makeSolidFrame(red: 1.0, green: 0.2, blue: 0.2),
            Self.makeSolidFrame(red: 0.2, green: 0.9, blue: 0.4),
            Self.makeSolidFrame(red: 0.2, green: 0.4, blue: 1.0),
        ]

        let outputURL = tempDir.appendingPathComponent("test.gif")
        try GIFExporter.encodeGIF(frames: frames, frameDelay: 0.08, to: outputURL)

        #expect(FileManager.default.fileExists(atPath: outputURL.path()))
        let data = try Data(contentsOf: outputURL)
        #expect(!data.isEmpty)

        let source = try #require(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        #expect(CGImageSourceGetCount(source) == 3)
        let typeIdentifier = try #require(CGImageSourceGetType(source) as String?)
        #expect(UTType(typeIdentifier) == .gif)
    }

    private static func makeSolidFrame(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        side: Int = 16
    ) throws -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = try #require(
            CGContext(
                data: nil,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        )
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        return try #require(context.makeImage())
    }
}
