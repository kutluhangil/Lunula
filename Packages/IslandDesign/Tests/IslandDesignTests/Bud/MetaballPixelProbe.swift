import CoreGraphics

enum PixelProbe {
    /// True when every pixel with alpha > 0 has r, g, b at or below `tolerance` (0...1).
    static func allPixelsAreBlackOrTransparent(_ image: CGImage, tolerance: Double) -> Bool {
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
        guard drew else { return false }
        let limit = UInt8((tolerance * 255).rounded(.up))
        for i in stride(from: 0, to: buffer.count, by: 4) where buffer[i + 3] > 0 {
            if buffer[i] > limit || buffer[i + 1] > limit || buffer[i + 2] > limit { return false }
        }
        return true
    }
}
