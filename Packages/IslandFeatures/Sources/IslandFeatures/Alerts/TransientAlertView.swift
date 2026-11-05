import IslandCore
import IslandDesign
import SwiftUI

/// Actions for alerts that offer buttons (download finished); injected by the App, no-ops by default.
public struct AlertActions {
    public var revealInFinder: @MainActor (URL) -> Void = { _ in }
    public var addToShelf: @MainActor (URL) -> Void = { _ in }

    public init(
        revealInFinder: @escaping @MainActor (URL) -> Void, addToShelf: @escaping @MainActor (URL) -> Void
    ) {
        self.revealInFinder = revealInFinder
        self.addToShelf = addToShelf
    }

    init() {}
}

extension EnvironmentValues {
    @Entry public var alertActions = AlertActions()
}

/// Transient alerts (J1–J4):
/// - Battery alerts (J1/J2, 276 × 32 pt): symbol in the left wing, tinted percentage in the right wing.
/// - Download finished (J3, 380 × 70 pt): 42×42 file box on the left, "Downloaded" in the right wing, and filename +
///   two pill buttons along the bottom row.
/// - Compact text alerts (J4, 316 × 32 pt): symbol in the left wing, 11 pt label in the right wing.
struct TransientAlertView: View {
    let alert: TransientAlert
    var notchWidth: CGFloat = 0
    var notchHeight: CGFloat = 32
    @Environment(\.alertActions) private var actions

    init(alert: TransientAlert) { self.alert = alert }

    init(alert: TransientAlert, notchWidth: CGFloat, notchHeight: CGFloat) {
        self.alert = alert
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
    }

    static func needsButtons(_ alert: TransientAlert) -> Bool {
        if case .file = alert.detail, alert.kind == .downloadFinished { true } else { false }
    }

    private var isBatteryAlert: Bool {
        switch alert.kind {
        case .charging, .unplugged, .batteryLow, .batteryFull: true
        default: false
        }
    }

    var body: some View {
        let p = AlertPresentations.make(alert)
        if case .file(let name, let url) = alert.detail, Self.needsButtons(alert) {
            downloadBody(presentation: p, name: name, url: url)
        } else if isBatteryAlert {
            batteryBody(presentation: p)
        } else {
            compactTextBody(presentation: p)
        }
    }

    private func batteryBody(presentation p: AlertPresentation) -> some View {
        let tintColor = Palette.tint(alert.tint)
        let percentText =
            if case .batteryLevel(let level) = alert.detail {
                "%\(level)"
            } else {
                "%100"
            }
        return HStack(spacing: 0) {
            Image(systemName: p.symbol)
                .font(TypeToken.body.font)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tintColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: notchWidth)
            Text(verbatim: percentText)
                .font(TypeToken.numeralCompact.font)
                .foregroundStyle(tintColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, Radii.closedShoulder + Spacing.compactPadding)
        .frame(height: notchHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(LocalizedStringKey(p.titleKey), bundle: .module))
        .accessibilityValue(Text(verbatim: percentText))
    }

    private func downloadBody(presentation p: AlertPresentation, name: String, url: URL) -> some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Color.clear.frame(width: notchWidth)
                title(p)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, Spacing.expandedPadding)
            .frame(height: notchHeight)

            HStack(alignment: .bottom, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                        .fill(Palette.inkRaised)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                                .strokeBorder(Palette.hairline, lineWidth: 0.5)
                        }
                    Image(systemName: "doc")
                        .font(.system(size: 18, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Palette.textPrimary)
                }
                .frame(width: 42, height: 42)

                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    button("alert.download.reveal") { actions.revealInFinder(url) }
                    button("alert.download.addToShelf") { actions.addToShelf(url) }
                }
                .frame(height: 24)
            }
            .padding(Spacing.expandedPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private func compactTextBody(presentation p: AlertPresentation) -> some View {
        HStack(spacing: 0) {
            Image(systemName: p.symbol)
                .font(TypeToken.body.font)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.tint(alert.tint))
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: notchWidth)
            VStack(alignment: .trailing, spacing: 0) {
                title(p).font(TypeToken.caption.font).foregroundStyle(Palette.textPrimary)
                if let subtitle = p.subtitle {
                    Text(subtitle).font(TypeToken.caption.font).foregroundStyle(Palette.textSecondary)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, Radii.closedShoulder + Spacing.compactPadding)
        .frame(height: notchHeight)
    }

    @ViewBuilder private func title(_ p: AlertPresentation) -> some View {
        if p.titleIsVerbatim {
            Text(verbatim: p.titleKey)
        } else {
            Text(LocalizedStringKey(p.titleKey), bundle: .module)
        }
    }

    private func button(_ key: LocalizedStringKey, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            Text(key, bundle: .module)
                .font(TypeToken.body.font)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(Palette.inkPressed, in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
    }
}
