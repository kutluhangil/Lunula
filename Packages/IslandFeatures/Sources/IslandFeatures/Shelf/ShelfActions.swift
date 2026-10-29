import AppKit
import SwiftUI

public struct ShelfItemModel: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var icon: NSImage
    public var isReference: Bool
    public var isMissing: Bool

    public init(id: UUID, name: String, icon: NSImage, isReference: Bool, isMissing: Bool) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isReference = isReference
        self.isMissing = isMissing
    }
}

/// ⌘-click adds or removes; a plain click selects one. Selected items are dragged, AirDropped and removed together.
public struct ShelfSelection: Equatable {
    public private(set) var ids: Set<UUID> = []

    public init() {}

    public mutating func click(_ id: UUID, command: Bool) {
        if command {
            if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        } else {
            ids = [id]
        }
    }

    public mutating func clear() { ids = [] }
}

/// Shelf commands and contents, injected by the App; read inside view bodies so the page stays live.
public struct ShelfActions {
    public var items: @MainActor () -> [ShelfItemModel] = { [] }
    public var add: @MainActor ([URL]) -> Void = { _ in }
    public var remove: @MainActor (UUID) -> Void = { _ in }
    public var reveal: @MainActor (UUID) -> Void = { _ in }
    public var airDrop: @MainActor ([UUID]) -> Void = { _ in }
    public var share: @MainActor ([UUID]) -> Void = { _ in }
    public var dragItem: @MainActor (UUID) -> NSItemProvider? = { _ in nil }

    public init(
        items: @escaping @MainActor () -> [ShelfItemModel], add: @escaping @MainActor ([URL]) -> Void,
        remove: @escaping @MainActor (UUID) -> Void, reveal: @escaping @MainActor (UUID) -> Void,
        airDrop: @escaping @MainActor ([UUID]) -> Void, share: @escaping @MainActor ([UUID]) -> Void,
        dragItem: @escaping @MainActor (UUID) -> NSItemProvider?
    ) {
        self.items = items
        self.add = add
        self.remove = remove
        self.reveal = reveal
        self.airDrop = airDrop
        self.share = share
        self.dragItem = dragItem
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var shelfActions = ShelfActions()
}
