import IslandCore
import IslandDesign
import SwiftUI

struct NextEventTile: View {
    let event: EventSnapshot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.signalOrange)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                Text(event.start, format: .dateTime.hour().minute())
                    .font(TypeToken.caption.font.monospacedDigit())
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .islandCard()
    }
}
