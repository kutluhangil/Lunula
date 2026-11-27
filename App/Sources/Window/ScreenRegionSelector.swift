import AppKit
import IslandDesign
import SwiftUI

struct SelectedScreenRegion: Equatable, Sendable {
    let displayID: CGDirectDisplayID?
    let cropRect: CGRect
    let backingScaleFactor: CGFloat
}

/// Interactive full-screen region picker on the active display under the cursor for Retina `ScreenRecorderService` captures.
@MainActor
final class ScreenRegionSelector {
    private static let minimumSelectionDimension: CGFloat = 32

    private var overlayWindow: RegionOverlayPanel?
    private var continuation: CheckedContinuation<SelectedScreenRegion?, Never>?
    private var keyMonitor: Any?

    var instructionText: String = "Drag to select area · Esc to cancel"

    func selectRegion() async -> SelectedScreenRegion? {
        cancel()
        let mouse = NSEvent.mouseLocation
        guard
            let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) })
                ?? NSScreen.screens.first
        else { return nil }

        let screenFrame = screen.frame
        let displayID = screen.cgDirectDisplayID
        let scaleFactor = screen.backingScaleFactor
        let topSafeInset = max(screen.safeAreaInsets.top, 28) + 24
        let model = RegionOverlayModel(
            instructionText: instructionText,
            topInset: topSafeInset
        )

        let panel = RegionOverlayPanel(contentRect: screenFrame)
        let localBounds = NSRect(origin: .zero, size: screenFrame.size)
        let container = NSView(frame: localBounds)

        let hosting = NSHostingView(
            rootView: RegionOverlayView(model: model).allowsHitTesting(false)
        )
        hosting.sizingOptions = []
        hosting.frame = localBounds
        hosting.autoresizingMask = [.width, .height]

        let interactionView = RegionInteractionView(frame: localBounds)
        interactionView.autoresizingMask = [.width, .height]
        interactionView.onSelectionChange = { selectionInView in
            if let selectionInView {
                model.selectionRect = Self.toDisplayTopLeftFluidRect(
                    viewSelection: selectionInView,
                    screenHeight: screenFrame.height
                )
            } else {
                model.selectionRect = nil
            }
        }
        interactionView.onSelectionComplete = { [weak self] selectionInView in
            guard let self else { return }
            let cropRect = Self.toDisplayTopLeftRect(
                viewSelection: selectionInView,
                screenHeight: screenFrame.height
            )
            guard
                selectionInView.width >= Self.minimumSelectionDimension,
                selectionInView.height >= Self.minimumSelectionDimension,
                cropRect.width >= Self.minimumSelectionDimension,
                cropRect.height >= Self.minimumSelectionDimension
            else {
                self.finish(with: nil)
                return
            }
            self.finish(
                with: SelectedScreenRegion(
                    displayID: displayID,
                    cropRect: cropRect,
                    backingScaleFactor: scaleFactor
                )
            )
        }
        interactionView.onCancel = { [weak self] in
            self?.cancel()
        }

        container.addSubview(hosting)
        container.addSubview(interactionView)
        panel.contentView = container
        overlayWindow = panel

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            Task { @MainActor [weak self] in
                self?.cancel()
            }
            return nil
        }

        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(interactionView)
        NSCursor.crosshair.set()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    tearDownOverlay()
                    continuation.resume(returning: nil)
                    return
                }
                self.continuation = continuation
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel()
            }
        }
    }

    func cancel() {
        finish(with: nil)
    }

    /// Converts an AppKit bottom-left view selection rect into `SCStreamConfiguration.sourceRect`'s
    /// display-local top-left coordinate space in points.
    nonisolated static func toDisplayTopLeftRect(viewSelection: CGRect, screenHeight: CGFloat) -> CGRect {
        CGRect(
            x: viewSelection.minX.rounded(),
            y: (screenHeight - viewSelection.maxY).rounded(),
            width: viewSelection.width.rounded(),
            height: viewSelection.height.rounded()
        )
    }

    private nonisolated static func toDisplayTopLeftFluidRect(
        viewSelection: CGRect,
        screenHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: viewSelection.minX,
            y: screenHeight - viewSelection.maxY,
            width: viewSelection.width,
            height: viewSelection.height
        )
    }

    private func finish(with result: SelectedScreenRegion?) {
        tearDownOverlay()
        guard let pending = continuation else { return }
        continuation = nil
        pending.resume(returning: result)
    }

    private func tearDownOverlay() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let panel = overlayWindow {
            overlayWindow = nil
            panel.ignoresMouseEvents = true
            panel.alphaValue = 0
            panel.contentView = nil
            panel.orderOut(nil)
            panel.close()
        }
        NSCursor.arrow.set()
    }
}

private final class RegionOverlayPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isFloatingPanel = true
        // Set after isFloatingPanel, which resets the panel level to .floating.
        level = .screenSaver
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class RegionInteractionView: NSView {
    var onSelectionChange: (@MainActor (CGRect?) -> Void)?
    var onSelectionComplete: (@MainActor (CGRect) -> Void)?
    var onCancel: (@MainActor () -> Void)?

    private var dragOrigin: CGPoint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addTrackingArea(
            NSTrackingArea(
                rect: .zero,
                options: [.cursorUpdate, .mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                owner: self
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.crosshair.set()
        let point = clampedPoint(for: event)
        dragOrigin = point
        onSelectionChange?(CGRect(origin: point, size: .zero))
    }

    override func mouseDragged(with event: NSEvent) {
        NSCursor.crosshair.set()
        guard let origin = dragOrigin else { return }
        let current = clampedPoint(for: event)
        onSelectionChange?(Self.rect(from: origin, to: current))
    }

    override func mouseUp(with event: NSEvent) {
        guard let origin = dragOrigin else {
            onCancel?()
            return
        }
        dragOrigin = nil
        let current = clampedPoint(for: event)
        onSelectionComplete?(Self.rect(from: origin, to: current))
    }

    override func rightMouseDown(with event: NSEvent) {
        dragOrigin = nil
        onSelectionChange?(nil)
        onCancel?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dragOrigin = nil
            onSelectionChange?(nil)
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        dragOrigin = nil
        onSelectionChange?(nil)
        onCancel?()
    }

    private func clampedPoint(for event: NSEvent) -> CGPoint {
        let local = convert(event.locationInWindow, from: nil)
        return CGPoint(
            x: min(max(local.x, bounds.minX), bounds.maxX),
            y: min(max(local.y, bounds.minY), bounds.maxY)
        )
    }

    private static func rect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }
}

@MainActor
@Observable
private final class RegionOverlayModel {
    var instructionText: String
    var topInset: CGFloat
    var selectionRect: CGRect?

    init(instructionText: String, topInset: CGFloat) {
        self.instructionText = instructionText
        self.topInset = topInset
    }
}

private struct ScrimCutoutShape: Shape {
    var cutout: CGRect?

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        if let cutout, cutout.width > 0, cutout.height > 0 {
            path.addRect(cutout)
        }
        return path
    }
}

private struct RegionOverlayView: View {
    let model: RegionOverlayModel

    private var pillBorderColor: Color {
        NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
            ? Palette.hairlineContrast
            : Palette.hairline
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ScrimCutoutShape(cutout: model.selectionRect)
                    .fill(Color.black.opacity(0.28), style: FillStyle(eoFill: true))

                if let selection = model.selectionRect, selection.width >= 1, selection.height >= 1 {
                    Path(selection)
                        .stroke(Palette.amberGold, lineWidth: 1.5)

                    dimensionPill(for: selection, in: proxy.size)
                }

                Text(model.instructionText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Palette.obsidian, in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(pillBorderColor, lineWidth: 1)
                    }
                    .padding(.top, model.topInset)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private func dimensionPill(for selection: CGRect, in containerSize: CGSize) -> some View {
        let widthPoints = Int(selection.width.rounded())
        let heightPoints = Int(selection.height.rounded())
        let clampedX = min(max(selection.midX, 54), max(54, containerSize.width - 54))
        let prefersAbove = selection.maxY + 34 > containerSize.height
        let rawY = prefersAbove ? selection.minY - 18 : selection.maxY + 18
        let clampedY = min(max(rawY, 20), max(20, containerSize.height - 20))

        return Text("\(widthPoints) × \(heightPoints)")
            .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(Palette.amberGold)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Palette.obsidian, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(pillBorderColor, lineWidth: 1)
            }
            .position(x: clampedX, y: clampedY)
    }
}
