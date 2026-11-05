import IslandDesign
import SwiftUI

/// H — Shelf cell (117 × 70 pt, cornerRadius 12): 32×32 icon with bottom-right 14×14 link badge for references,
/// 11 pt medium centered name (2 lines max), #1C1C1F background and top-left 16×16 remove button on hover.
struct ShelfItemView: View {
    let item: ShelfItemModel
    let isSelected: Bool
    let onRemove: @MainActor () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                if item.isMissing {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Palette.signalOrange)
                        .offset(x: 4, y: 4)
                } else if item.isReference {
                    ZStack {
                        Circle()
                            .fill(Palette.inkPressed)
                            .overlay { Circle().strokeBorder(Palette.obsidian, lineWidth: 1.5) }
                        Image(systemName: "link")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .frame(width: 14, height: 14)
                    .offset(x: 4, y: 4)
                }
            }
            Text(item.name)
                .font(TypeToken.caption.font)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .opacity(item.isMissing ? 0.45 : 1)
        .padding(4)
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            hovering || isSelected ? Palette.inkPressed : .clear,
            in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
        )
        .overlay(alignment: .topLeading) {
            if hovering {
                Button(action: onRemove) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.62))
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Palette.obsidian)
                    }
                    .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding(4)
                .accessibilityLabel(Text(AccessibilityLabels.removeShelfItem))
            }
        }
        .onHover { hovering = $0 }
    }
}
