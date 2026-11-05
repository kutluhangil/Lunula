import Foundation
import IslandCore
import Testing

@testable import IslandServices

@Suite struct ShelfConverterTests {
    @Test func convertsPNGToJPEGAndPDFAndCreatesZip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let srcURL = dir.appendingPathComponent("sample.png")
        try ImageFixtures.png(color: RGBAColor(red: 0.8, green: 0.4, blue: 0.2)).write(to: srcURL)

        let jpegURL = try ShelfConverter.convertImage(at: srcURL, to: .jpeg, in: dir)
        #expect(FileManager.default.fileExists(atPath: jpegURL.path()))
        #expect(jpegURL.pathExtension == "jpeg")

        let pdfURL = try ShelfConverter.convertImage(at: srcURL, to: .pdf, in: dir)
        #expect(FileManager.default.fileExists(atPath: pdfURL.path()))
        #expect(pdfURL.pathExtension == "pdf")

        let zipURL = try ShelfConverter.createArchive(from: [srcURL, jpegURL], in: dir)
        #expect(FileManager.default.fileExists(atPath: zipURL.path()))
        #expect(zipURL.pathExtension == "zip")

        let extractedDir = try ShelfConverter.extractArchive(at: zipURL, in: dir)
        #expect(FileManager.default.fileExists(atPath: extractedDir.path()))
    }
}
