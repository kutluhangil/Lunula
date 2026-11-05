import IslandDesign
import SwiftUI

/// H′ — Empty Shelf (520 × 160 pt): #111113 card with a 24 pt tray icon and 13 pt secondary prompt; highlights with a
/// dashed border when a file drag is hovering over the drop zone.
struct ShelfEmptyView: View {
    var isTargeted = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "tray.and.arrow.down" : "tray")
                .font(.system(size: 20, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isTargeted ? Palette.textPrimary : Palette.textTertiary)
                .frame(width: 24, height: 24)
            Text("shelf.empty", bundle: .module)
                .font(TypeToken.body.font)
                .foregroundStyle(isTargeted ? Palette.textPrimary : Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            let shape = RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
            shape.fill(isTargeted ? Palette.inkPressed : Palette.inkRaised)
                .overlay {
                    if isTargeted {
                        shape.strokeBorder(
                            Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    } else {
                        shape.strokeBorder(Palette.hairline, lineWidth: 0.5)
                    }
                }
        }
    }
}
