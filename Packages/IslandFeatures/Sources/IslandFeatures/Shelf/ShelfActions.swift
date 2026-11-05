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
    public var convertImage: @MainActor (UUID, String) -> Void = { _, _ in }
    public var compressToZip: @MainActor ([UUID]) -> Void = { _ in }
    public var expandArchive: @MainActor (UUID) -> Void = { _ in }
    public var copyTextOCR: @MainActor (UUID) -> Void = { _ in }
    public var stageClipboardImage: @MainActor () -> Void = {}

    public init(
        items: @escaping @MainActor () -> [ShelfItemModel], add: @escaping @MainActor ([URL]) -> Void,
        remove: @escaping @MainActor (UUID) -> Void, reveal: @escaping @MainActor (UUID) -> Void,
        airDrop: @escaping @MainActor ([UUID]) -> Void, share: @escaping @MainActor ([UUID]) -> Void,
        dragItem: @escaping @MainActor (UUID) -> NSItemProvider?,
        convertImage: @escaping @MainActor (UUID, String) -> Void = { _, _ in },
        compressToZip: @escaping @MainActor ([UUID]) -> Void = { _ in },
        expandArchive: @escaping @MainActor (UUID) -> Void = { _ in },
        copyTextOCR: @escaping @MainActor (UUID) -> Void = { _ in },
        stageClipboardImage: @escaping @MainActor () -> Void = {}
    ) {
        self.items = items
        self.add = add
        self.remove = remove
        self.reveal = reveal
        self.airDrop = airDrop
        self.share = share
        self.dragItem = dragItem
        self.convertImage = convertImage
        self.compressToZip = compressToZip
        self.expandArchive = expandArchive
        self.copyTextOCR = copyTextOCR
        self.stageClipboardImage = stageClipboardImage
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var shelfActions = ShelfActions()
}
