import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

public enum IslandHitTesting {
    /// Bubbles sit beside the island and are checked first.
    public static func target(at point: CGPoint, island: CGRect, bubbles: [(ActivityID, CGRect)]) -> IslandHitTarget? {
        if let hit = bubbles.first(where: { $0.1.contains(point) }) { return .bubble(hit.0) }
        return island.contains(point) ? .island : nil
    }
}
