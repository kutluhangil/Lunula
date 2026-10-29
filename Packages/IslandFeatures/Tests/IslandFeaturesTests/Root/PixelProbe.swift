import CoreGraphics

enum PixelProbe {
    /// RGBA8 premultiplied pixels, top row first (matches SwiftUI's y-down coordinates).
    static func rgba(_ image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let drew = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard
                let context = CGContext(
                    data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drew ? buffer : nil
    }

    /// True when every pixel with alpha > 0 has r, g, b at or below `tolerance` (0...1).
    static func allPixelsAreBlackOrTransparent(_ image: CGImage, tolerance: Double) -> Bool {
        guard let buffer = rgba(image) else { return false }
        let limit = UInt8((tolerance * 255).rounded(.up))
        for i in stride(from: 0, to: buffer.count, by: 4) where buffer[i + 3] > 0 {
            if buffer[i] > limit || buffer[i + 1] > limit || buffer[i + 2] > limit { return false }
        }
        return true
    }

    static func alpha(_ image: CGImage, x: Int, y: Int) -> UInt8 {
        rgba(image)?[(y * image.width + x) * 4 + 3] ?? 0
    }

    static func hasOpaqueContent(_ image: CGImage) -> Bool {
        guard let buffer = rgba(image) else { return false }
        return stride(from: 3, to: buffer.count, by: 4).contains { buffer[$0] > 0 }
    }
}
