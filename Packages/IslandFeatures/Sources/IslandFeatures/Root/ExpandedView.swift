import IslandCore
import IslandDesign
import SwiftUI

/// Expanded island: top band beside the camera (hero symbol left, tabs and settings right), then the page.
struct ExpandedView: View {
    let page: IslandPage
    let layout: IslandLayout
    let home: HomeInputs
    let notch: NotchMetrics
    let send: @MainActor (IslandEvent) -> Void
    let openSettings: @MainActor () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Group {
                    if let primary = layout.primary {
                        ActivityContentView(activity: primary, slot: .compactLeading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: notch.size.width)
                HStack(spacing: 10) {
                    tab("island.tab.home", .home)
                    tab("island.tab.shelf", .shelf)
                    Button(action: openSettings) { Image(systemName: "gearshape") }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("island.settings", bundle: .module))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(TypeToken.caption.font)
            .foregroundStyle(Palette.textSecondary)
            .frame(height: notch.size.height)

            content.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.top, 8)
        }
        .padding(.horizontal, Spacing.expandedPadding)
        .padding(.bottom, Spacing.expandedPadding)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(.escape) {
            send(.escapePressed)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            send(.pageSelected(PageCycler.previous(before: page)))
            return .handled
        }
        .onKeyPress(.rightArrow) {
            send(.pageSelected(PageCycler.next(after: page)))
            return .handled
        }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .home:
            HomePageView(inputs: home).environment(\.islandLayout, layout)
        case .shelf:
            Text("shelf.empty", bundle: .module).font(TypeToken.body.font).foregroundStyle(Palette.textTertiary)
        case .activity(let id):
            if let activity = layout.activity(id) {
                ActivityContentView(activity: activity, slot: .expanded)
            }
        }
    }

    private func tab(_ key: LocalizedStringKey, _ target: IslandPage) -> some View {
        Button {
            send(.pageSelected(target))
        } label: {
            Text(key, bundle: .module).foregroundStyle(page == target ? Palette.textPrimary : Palette.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
