import AppKit
import IslandCore
import IslandDesign
import SwiftUI

private struct HostedCameraPreviewRepresentable: NSViewRepresentable {
    let previewView: NSView

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        mount(previewView, into: container)
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        if previewView.superview !== container {
            for subview in Array(container.subviews) {
                subview.removeFromSuperview()
            }
            mount(previewView, into: container)
        }
    }

    private func mount(_ child: NSView, into container: NSView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            child.topAnchor.constraint(equalTo: container.topAnchor),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }
}

public struct CameraMirrorPopoverView: View {
    public static let viewportWidth: CGFloat = 240
    public static let viewportHeight: CGFloat = 156

    private let isAuthorized: Bool
    private let isDenied: Bool
    private let startPreview: @MainActor () async -> NSView?
    private let stopPreview: @MainActor () -> Void
    private let openSystemSettings: @MainActor () -> Void

    @State private var previewView: NSView?
    @State private var isStarting = false
    @State private var requestDeniedOrUnavailable = false

    public init(
        isAuthorized: Bool,
        isDenied: Bool,
        startPreview: @escaping @MainActor () async -> NSView?,
        stopPreview: @escaping @MainActor () -> Void,
        openSystemSettings: @escaping @MainActor () -> Void
    ) {
        self.isAuthorized = isAuthorized
        self.isDenied = isDenied
        self.startPreview = startPreview
        self.stopPreview = stopPreview
        self.openSystemSettings = openSystemSettings
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .fill(Palette.inkRaised)

            if let previewView {
                HostedCameraPreviewRepresentable(previewView: previewView)
                    .clipShape(RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
            } else if isDenied || requestDeniedOrUnavailable {
                deniedContent
            } else if isStarting {
                ProgressView()
                    .controlSize(.small)
                    .tint(Palette.textSecondary)
            } else {
                enableContent
            }
        }
        .frame(width: Self.viewportWidth, height: Self.viewportHeight)
        .overlay(
            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(8)
        .background(Palette.obsidian)
        .task(id: isAuthorized) {
            guard isAuthorized, previewView == nil else { return }
            await activateMirror()
        }
        .onDisappear {
            previewView = nil
            stopPreview()
        }
    }

    private var enableContent: some View {
        VStack(spacing: 10) {
            Image(systemName: "web.camera.fill")
                .font(TypeToken.title.font)
                .foregroundStyle(Palette.textSecondary)

            Button {
                Task { @MainActor in
                    await activateMirror()
                }
            } label: {
                Text("tools.mirror.enable", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Palette.inkPressed, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private var deniedContent: some View {
        VStack(spacing: 10) {
            Image(systemName: "video.slash.fill")
                .font(TypeToken.title.font)
                .foregroundStyle(Palette.textSecondary)

            Button(action: openSystemSettings) {
                Text("tools.mirror.openSettings", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Palette.inkPressed, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    @MainActor
    private func activateMirror() async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        if let view = await startPreview() {
            previewView = view
            requestDeniedOrUnavailable = false
        } else {
            requestDeniedOrUnavailable = true
        }
    }
}
