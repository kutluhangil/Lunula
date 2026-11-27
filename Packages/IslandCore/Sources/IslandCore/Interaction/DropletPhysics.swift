import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// High-level aesthetic personality of the island shell and inner accents.
public enum IslandVisualStyle: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case lunula
    case alcove
    case boring
}

/// Outer shell material of the island surface.
public enum IslandSurfaceMaterial: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case obsidian
    case liquidGlass
}

/// Elastic surface-tension deformation state of the island in response to pointer proximity and velocity.
public struct DropletTension: Equatable, Sendable {
    /// Horizontal shear/bulge in points (`-6.0 ... 6.0`).
    public var pullX: Double
    /// Downward meniscus sag in points (`0.0 ... 5.0`); never negative so the top bezel stays flush.
    public var pullY: Double
    /// Normalized horizontal cursor focus across the island (`0.0 ... 1.0`, default `0.5`).
    public var focusX: Double
    /// Proximity/hover strength (`0.0 ... 1.0`) driving the specular highlight and rim.
    public var intensity: Double

    public static let zero = DropletTension(pullX: 0, pullY: 0, focusX: 0.5, intensity: 0)

    public init(pullX: Double, pullY: Double, focusX: Double = 0.5, intensity: Double = 0) {
        self.pullX = pullX
        self.pullY = pullY
        self.focusX = focusX
        self.intensity = intensity
    }
}

/// Pure water-droplet pointer physics for subtle meniscus pull and specular focus on the island shell.
public enum DropletPhysics: Sendable {
    /// Outer surface-tension influence halo around `islandRect` in points.
    public static let haloMargin: Double = 28.0
    public static let maxPullX: Double = 6.0
    public static let maxPullY: Double = 5.0

    public static func compute(
        pointer: CGPoint?,
        islandRect: CGRect,
        velocity: CGSize = .zero
    ) -> DropletTension {
        guard let p = pointer, islandRect.width > 0, islandRect.height > 0 else {
            return .zero
        }

        let dx = max(islandRect.minX - p.x, 0, p.x - islandRect.maxX)
        let dy = max(islandRect.minY - p.y, 0, p.y - islandRect.maxY)
        let distance = (Double(dx * dx + dy * dy)).squareRoot()

        guard distance < haloMargin else {
            return .zero
        }

        let intensity: Double
        if distance <= 0 {
            intensity = 1.0
        } else {
            let u = 1.0 - (distance / haloMargin)
            intensity = u * u * (3.0 - 2.0 * u)
        }

        let focusX = min(max(Double((p.x - islandRect.minX) / islandRect.width), 0.08), 0.92)
        let normX = (focusX - 0.5) * 2.0
        let normY = min(max(Double((p.y - islandRect.minY) / max(islandRect.height, 1)), 0.0), 1.3)

        let velX = min(max(Double(velocity.width) * 0.004, -3.5), 3.5)
        let velY = min(max(Double(velocity.height) * 0.003, -2.5), 2.5)

        let rawPullX = (normX * 4.2 + velX) * intensity
        let rawPullY = (normY * 3.4 + velY) * intensity

        let pullX = min(max(rawPullX, -maxPullX), maxPullX)
        let pullY = min(max(rawPullY, 0.0), maxPullY)

        return DropletTension(
            pullX: pullX == 0 ? 0 : pullX,
            pullY: pullY == 0 ? 0 : pullY,
            focusX: focusX,
            intensity: intensity
        )
    }
}
