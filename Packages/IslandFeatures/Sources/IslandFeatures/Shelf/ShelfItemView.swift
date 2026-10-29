import IslandDesign
import SwiftUI

struct ShelfItemView: View {
    let item: ShelfItemModel
    let isSelected: Bool
    let onRemove: @MainActor () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: item.icon).resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 40)
                if item.isMissing {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.signalOrange)
                } else if item.isReference {
                    Image(systemName: "link").font(TypeToken.caption.font).foregroundStyle(Palette.textSecondary)
                }
            }
            Text(item.name)
                .font(TypeToken.caption.font)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .opacity(item.isMissing ? 0.45 : 1)
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Palette.inkPressed : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if hovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(AccessibilityLabels.removeShelfItem))
            }
        }
        .onHover { hovering = $0 }
    }
}
