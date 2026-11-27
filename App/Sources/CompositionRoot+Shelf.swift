import AppKit
import IslandCore
import IslandFeatures
import IslandServices
import OSLog

extension CompositionRoot {
    var shelfActions: ShelfActions {
        ShelfActions(
            items: { [unowned self] in shelfModels },
            add: { [unowned self] urls in
                guard !urls.isEmpty else { return }
                do {
                    try shelf.add(urls)
                    feedback.play(.levelChange)
                } catch {
                    logger.error("shelf add failed: \(error.localizedDescription, privacy: .public)")
                }
            },
            remove: { [unowned self] id in
                shelf.remove(id)
                shelfIcons[id] = nil
            },
            reveal: { [unowned self] id in
                guard let item = shelf.items.first(where: { $0.id == id }) else { return }
                _ = shelf.withAccess(to: item) { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
            },
            airDrop: { [unowned self] ids in shareFiles(ids, via: NSSharingService(named: .sendViaAirDrop)) },
            share: { [unowned self] ids in shareFiles(ids, via: nil) },
            dragItem: { [unowned self] id in
                guard let item = shelf.items.first(where: { $0.id == id }),
                    case .available(let url) = shelf.status(of: item)
                else { return nil }
                return NSItemProvider(contentsOf: url)
            },
            convertImage: { [unowned self] id, rawFormat in
                convertShelfImage(id: id, rawFormat: rawFormat)
            },
            compressToZip: { [unowned self] ids in
                compressShelfItems(ids: ids)
            },
            expandArchive: { [unowned self] id in
                expandShelfArchive(id: id)
            },
            copyTextOCR: { [unowned self] id in
                copyShelfItemOCR(id: id)
            },
            stageClipboardImage: { [unowned self] in
                stageClipboardImageToShelf()
            })
    }

    var shelfModels: [ShelfItemModel] {
        shelf.items.map { item in
            let status = shelf.status(of: item)
            let icon =
                shelfIcons[item.id]
                ?? shelf.withAccess(to: item) { NSWorkspace.shared.icon(forFile: $0.path()) }
                ?? NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!
            if case .available = status { shelfIcons[item.id] = icon }
            let isReference = if case .reference = item.storage { true } else { false }
            return ShelfItemModel(
                id: item.id, name: item.displayName, icon: icon, isReference: isReference, isMissing: status == .missing
            )
        }
    }

    func shareFiles(_ ids: [UUID], via service: NSSharingService?) {
        let urls = ids.compactMap { id -> URL? in
            guard let item = shelf.items.first(where: { $0.id == id }),
                case .available(let url) = shelf.status(of: item)
            else { return nil }
            return url
        }
        guard !urls.isEmpty else { return }
        let scoped = urls.filter { $0.startAccessingSecurityScopedResource() }
        defer { for url in scoped { url.stopAccessingSecurityScopedResource() } }
        if let service {
            service.perform(withItems: urls)
        } else if let view = activeIsland().flatMap({ windows.controller(for: $0.screen.id)?.container }) {
            NSSharingServicePicker(items: urls).show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
    }

    private func expandShelfArchive(id: UUID) {
        guard let item = shelf.items.first(where: { $0.id == id }),
            case .available(let url) = shelf.status(of: item)
        else { return }
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfExpanded")
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let expanded = try? ShelfConverter.extractArchive(at: url, in: outDir) else { return }
            await MainActor.run {
                try? self?.shelf.add([expanded])
                self?.feedback.play(.levelChange)
            }
        }
    }

    private func stageClipboardImageToShelf() {
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfScreenshots")
        guard let staged = try? ShelfConverter.stageClipboardImage(from: .general, in: outDir) else { return }
        try? shelf.add([staged])
        feedback.play(.levelChange)
    }

    private func convertShelfImage(id: UUID, rawFormat: String) {
        guard let format = ShelfImageFormat(rawValue: rawFormat),
            let item = shelf.items.first(where: { $0.id == id }),
            case .available(let url) = shelf.status(of: item)
        else { return }
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfConverted")
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let converted = try? ShelfConverter.convertImage(at: url, to: format, in: outDir) else { return }
            await MainActor.run {
                try? self?.shelf.add([converted])
                self?.feedback.play(.levelChange)
            }
        }
    }

    private func compressShelfItems(ids: [UUID]) {
        let urls = ids.compactMap { id -> URL? in
            guard let item = shelf.items.first(where: { $0.id == id }),
                case .available(let url) = shelf.status(of: item)
            else { return nil }
            return url
        }
        guard !urls.isEmpty else { return }
        let outDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ShelfArchives")
        let scoped = urls.filter { $0.startAccessingSecurityScopedResource() }
        Task.detached { [weak self] in
            defer { for url in scoped { url.stopAccessingSecurityScopedResource() } }
            guard let archive = try? ShelfConverter.createArchive(from: urls, in: outDir) else { return }
            await MainActor.run {
                try? self?.shelf.add([archive])
                self?.feedback.play(.levelChange)
            }
        }
    }

    private func copyShelfItemOCR(id: UUID) {
        guard let item = shelf.items.first(where: { $0.id == id }),
            case .available(let url) = shelf.status(of: item)
        else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let text = try? ShelfConverter.extractText(from: url) else { return }
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                self?.feedback.play(.alignment)
                self?.broadcast(
                    .alertRaised(
                        TransientAlert(
                            id: UUID(), kind: .custom,
                            detail: .text(
                                title: String(localized: "alert.ocrCopied"),
                                subtitle: String(text.prefix(42)),
                                symbol: "text.viewfinder"),
                            tint: .neutral, duration: 2.2, priority: .normal)))
            }
        }
    }
}
