import AppKit
import IslandCore

enum ImageFixtures {
    /// Solid-colour PNG drawn with CGContext.
    static func png(color: RGBAColor, size: Int = 32) -> Data {
        let context = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: color.alpha))
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        return NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
    }
}

/// Counts loader calls from a @Sendable closure.
final class LoadCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.withLock { value } }
    func increment() { lock.withLock { value += 1 } }
}
