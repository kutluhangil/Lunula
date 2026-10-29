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

/// Compact transient alert: symbol in the left wing (tint colour), title in the right wing; a finished download
/// also gets two buttons under the notch band (the island uses peek size for it).
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

    var body: some View {
        let p = AlertPresentations.make(alert)
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Image(systemName: p.symbol)
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.tint(alert.tint))
                    .frame(maxWidth: .infinity)
                Color.clear.frame(width: notchWidth)
                VStack(alignment: .leading, spacing: 0) {
                    title(p).font(TypeToken.caption.font).foregroundStyle(Palette.textPrimary)
                    if let subtitle = p.subtitle {
                        Text(subtitle).font(TypeToken.caption.font).foregroundStyle(Palette.textSecondary)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: notchHeight)

            if case .file(_, let url) = alert.detail, Self.needsButtons(alert) {
                HStack(spacing: 8) {
                    button("alert.download.reveal") { actions.revealInFinder(url) }
                    button("alert.download.addToShelf") { actions.addToShelf(url) }
                }
            }
        }
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
                .font(TypeToken.caption.font)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Palette.inkPressed, in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
    }
}
