import AppKit
import IslandDesign
import SwiftUI
import UniformTypeIdentifiers

/// Four-column grid of shelved files; drop files to add, drag out to use, context menu for Finder/AirDrop/Share.
struct ShelfPage: View {
    let items: [ShelfItemModel]
    @Environment(\.shelfActions) private var actions
    @State private var selection = ShelfSelection()
    @State private var targeted = false

    init(items: [ShelfItemModel]) { self.items = items }

    var body: some View {
        Group {
            if items.isEmpty {
                ShelfEmptyView()
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(items) { item in
                            ShelfItemView(item: item, isSelected: selection.ids.contains(item.id)) {
                                actions.remove(item.id)
                            }
                            .onTapGesture {
                                selection.click(item.id, command: NSEvent.modifierFlags.contains(.command))
                            }
                            .onDrag { actions.dragItem(item.id) ?? NSItemProvider() }
                            .contextMenu { menu(for: item) }
                        }
                    }
                }
                .scrollIndicators(.never)
            }
        }
        .background(
            targeted ? Palette.inkPressed : .clear, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
        )
        .onDrop(of: [.fileURL], isTargeted: $targeted) { providers in
            Task { @MainActor in actions.add(await Self.urls(from: providers)) }
            return true
        }
    }

    @ViewBuilder private func menu(for item: ShelfItemModel) -> some View {
        let ids = selection.ids.contains(item.id) ? Array(selection.ids) : [item.id]
        Button {
            actions.reveal(item.id)
        } label: {
            Text("shelf.reveal", bundle: .module)
        }
        Button {
            actions.airDrop(ids)
        } label: {
            Text("shelf.airDrop", bundle: .module)
        }
        Button {
            actions.share(ids)
        } label: {
            Text("shelf.share", bundle: .module)
        }
        Divider()
        Button(role: .destructive) {
            ids.forEach(actions.remove)
            selection.clear()
        } label: {
            Text("shelf.remove", bundle: .module)
        }
    }

    private static func urls(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                urls.append(url)
            } else if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil)
            {
                urls.append(url)
            }
        }
        return urls
    }
}
