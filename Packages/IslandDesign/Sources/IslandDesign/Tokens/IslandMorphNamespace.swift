import SwiftUI

extension EnvironmentValues {
    /// Shared namespace injected by `IslandSurface` so hero artwork and icons smoothly morph across compact, peek, and expanded phases.
    @Entry public var islandMorphNamespace: Namespace.ID? = nil
}
