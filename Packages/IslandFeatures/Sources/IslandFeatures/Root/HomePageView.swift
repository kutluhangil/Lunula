import IslandCore
import IslandDesign
import SwiftUI

/// G — Expanded Home: vertical stack with the unpadded hero row on top and a 2-column 56 pt tile grid below.
struct HomePageView: View {
    let inputs: HomeInputs
    @Environment(\.quickTools) private var quickTools
    @Environment(\.calendarActions) private var calendar

    var body: some View {
        let composed = HomeComposer.compose(inputs)
        let style = quickTools.visualStyle()

        if style == .alcove, let hero = composed.hero {
            HomeCardView(card: hero)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 12) {
                if let hero = composed.hero {
                    HomeCardView(card: hero).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if !composed.tiles.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(composed.tiles, id: \.self) { tile in
                            HomeCardView(card: tile)
                                .frame(maxWidth: .infinity)
                                .frame(height: composed.hero == nil ? nil : 56)
                        }
                        if style == .lunula, composed.hero != nil {
                            networkSpeedTile(stats: quickTools.systemStats())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func networkSpeedTile(stats: SystemStatsItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: "↓ \(stats.downloadRateText)")
                .font(TypeToken.caption.font.monospacedDigit())
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
            Text(verbatim: "↑ \(stats.uploadRateText)")
                .font(TypeToken.caption.font.monospacedDigit())
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 96, idealWidth: 108, maxWidth: 118, maxHeight: .infinity, alignment: .leading)
        .frame(height: 56)
        .islandCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("tools.stats.network", bundle: .module))
    }
}
