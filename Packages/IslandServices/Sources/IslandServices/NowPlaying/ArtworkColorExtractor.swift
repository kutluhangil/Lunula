import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import IslandCore

/// Dominant artwork colours: downscale to 64 px, k-means (4 clusters, 5 passes, perceptual), read the 4×1 result.
public enum ArtworkColorExtractor {
    private static let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])

    public static func weightedColors(from imageData: Data) -> [WeightedColor] {
        guard let image = CIImage(data: imageData), image.extent.width > 0 else { return [] }
        let scale = CIFilter.lanczosScaleTransform()
        scale.inputImage = image
        scale.scale = Float(64 / max(image.extent.width, image.extent.height))
        let kMeans = CIFilter.kMeans()
        kMeans.inputImage = scale.outputImage
        kMeans.extent = scale.outputImage?.extent ?? image.extent
        kMeans.count = 4
        kMeans.passes = 5
        kMeans.perceptual = true
        guard let output = kMeans.outputImage else { return [] }

        var pixels = [Float](repeating: 0, count: 16)
        context.render(
            output, toBitmap: &pixels, rowBytes: 4 * 4 * MemoryLayout<Float>.size,
            bounds: CGRect(x: 0, y: 0, width: 4, height: 1), format: .RGBAf,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
        return (0..<4).map { i in
            let p = pixels[(i * 4)..<(i * 4 + 4)].map(Double.init)
            // k-means stores the cluster weight in alpha (colour channels are not premultiplied).
            return WeightedColor(
                color: RGBAColor(red: p[0], green: p[1], blue: p[2]), weight: p[3] == 0 ? 1 : p[3])
        }
    }
}
