import AppKit
import IslandCore
import IslandDesign
import QuartzCore
import SwiftUI

/// Non-activating floating drop basket that appears near the cursor's nearest screen edge during a file drag,
/// saving users on large external monitors from dragging files all the way up to the top bezel.
@MainActor final class FloatingShelfBasketController {
    static let panelSize = CGSize(width: 164, height: 116)
    fileprivate static let airDropZoneHeight: CGFloat = 38

    private let onDropURLs: @MainActor ([URL]) -> Void
    private let onAirDropURLs: @MainActor ([URL]) -> Void
    private let model: BasketViewModel
    private var panel: FloatingBasketPanel?
    private var activeScreenID: UInt32?
    private var isShowing = false

    var title: String {
        get { model.title }
        set { model.title = newValue }
    }

    var subtitle: String {
        get { model.subtitle }
        set { model.subtitle = newValue }
    }

    var airDropLabel: String {
        get { model.airDropLabel }
        set { model.airDropLabel = newValue }
    }

    init(
        title: String = "Drop to Shelf",
        subtitle: String = "Release files here",
        airDropLabel: String = "AirDrop",
        onDropURLs: @escaping @MainActor ([URL]) -> Void,
        onAirDropURLs: @escaping @MainActor ([URL]) -> Void
    ) {
        self.onDropURLs = onDropURLs
        self.onAirDropURLs = onAirDropURLs
        self.model = BasketViewModel(title: title, subtitle: subtitle, airDropLabel: airDropLabel)
    }

    func update(isDragging: Bool, mouse: NSPoint, screens: [ScreenDescriptor], enabled: Bool) {
        guard enabled, isDragging,
            let screen = screens.first(where: { $0.frame.contains(mouse) })
                ?? screens.first(where: \.isMain)
                ?? screens.first
        else {
            hide()
            return
        }

        let panel = ensurePanel()
        if !isShowing || activeScreenID != screen.id {
            let wasShowing = isShowing
            isShowing = true
            activeScreenID = screen.id
            panel.setFrame(Self.targetFrame(mouse: mouse, screen: screen), display: true)
            if !wasShowing {
                if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                    panel.alphaValue = 1
                    panel.orderFrontRegardless()
                } else {
                    panel.alphaValue = 0
                    panel.orderFrontRegardless()
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.18
                        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                        panel.animator().alphaValue = 1
                    }
                }
            } else {
                panel.orderFrontRegardless()
            }
        }
    }

    func hide() {
        model.hoveredZone = nil
        guard isShowing else { return }
        isShowing = false
        activeScreenID = nil
        panel?.orderOut(nil)
    }

    static func targetFrame(mouse: NSPoint, screen: ScreenDescriptor) -> CGRect {
        let bounds = screen.visibleFrame.isEmpty ? screen.frame : screen.visibleFrame
        let inset: CGFloat = 24
        let x: CGFloat
        if mouse.x < bounds.midX {
            x = bounds.minX + inset
        } else {
            x = max(bounds.minX, bounds.maxX - panelSize.width - inset)
        }
        let minY = bounds.minY + inset
        let maxY = max(minY, bounds.maxY - panelSize.height - inset)
        let y = min(max(mouse.y - panelSize.height / 2, minY), maxY)
        return CGRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
    }

    private func ensurePanel() -> FloatingBasketPanel {
        if let existing = panel { return existing }
        let rect = NSRect(origin: .zero, size: Self.panelSize)
        let created = FloatingBasketPanel(contentRect: rect)

        let container = NSView(frame: rect)
        let hosting = NSHostingView(
            rootView: FloatingShelfBasketView(model: model).allowsHitTesting(false))
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]

        let dropView = BasketDropDestinationView(frame: container.bounds)
        dropView.autoresizingMask = [.width, .height]
        dropView.onHoverZoneChange = { [weak self] zone in
            self?.model.hoveredZone = zone
        }
        dropView.onPerformDrop = { [weak self] urls, zone in
            guard let self else { return }
            self.hide()
            switch zone {
            case .shelf:
                self.onDropURLs(urls)
            case .airDrop:
                self.onAirDropURLs(urls)
            }
        }

        container.addSubview(hosting)
        container.addSubview(dropView)
        created.contentView = container
        panel = created
        return created
    }
}

private enum BasketDropZone: Equatable {
    case shelf
    case airDrop
}

@MainActor @Observable private final class BasketViewModel {
    var title: String
    var subtitle: String
    var airDropLabel: String
    var hoveredZone: BasketDropZone?

    init(title: String, subtitle: String, airDropLabel: String) {
        self.title = title
        self.subtitle = subtitle
        self.airDropLabel = airDropLabel
    }
}

private final class FloatingBasketPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isFloatingPanel = true
        // Set after isFloatingPanel, which resets level to .floating.
        level = .statusBar
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class BasketDropDestinationView: NSView {
    var onHoverZoneChange: (@MainActor (BasketDropZone?) -> Void)?
    var onPerformDrop: (@MainActor ([URL], BasketDropZone) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(sender) else { return [] }
        onHoverZoneChange?(zone(for: sender))
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(sender) else {
            onHoverZoneChange?(nil)
            return []
        }
        onHoverZoneChange?(zone(for: sender))
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onHoverZoneChange?(nil)
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        onHoverZoneChange?(nil)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls =
            (sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL]) ?? []
        let targetZone = zone(for: sender)
        onHoverZoneChange?(nil)
        guard !urls.isEmpty else { return false }
        onPerformDrop?(urls, targetZone)
        return true
    }

    private func hasFileURLs(_ sender: NSDraggingInfo) -> Bool {
        sender.draggingPasteboard.canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true])
    }

    private func zone(for sender: NSDraggingInfo) -> BasketDropZone {
        let local = convert(sender.draggingLocation, from: nil)
        return local.y <= FloatingShelfBasketController.airDropZoneHeight ? .airDrop : .shelf
    }
}

private struct FloatingShelfBasketView: View {
    let model: BasketViewModel

    private var isHovered: Bool { model.hoveredZone != nil }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        VStack(spacing: 6) {
            VStack(spacing: 3) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(model.hoveredZone == .shelf ? Palette.amberGold : Palette.textPrimary)

                Text(model.title)
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)

                Text(model.subtitle)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 5) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 11, weight: .semibold))
                Text(model.airDropLabel)
                    .font(TypeToken.caption.font)
                    .lineLimit(1)
            }
            .foregroundStyle(model.hoveredZone == .airDrop ? Palette.amberGold : Palette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(
                model.hoveredZone == .airDrop ? Palette.amberGold.opacity(0.18) : Palette.inkRaised,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(8)
        .frame(
            width: FloatingShelfBasketController.panelSize.width,
            height: FloatingShelfBasketController.panelSize.height
        )
        .background(Palette.obsidian, in: shape)
        .overlay {
            if isHovered {
                shape
                    .strokeBorder(Palette.amberGold, style: StrokeStyle(lineWidth: 1.75, dash: [6, 4]))
            } else {
                shape
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            }
        }
    }
}
