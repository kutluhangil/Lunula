import IslandCore
import IslandDesign
import SwiftUI

struct CustomExpandedCard: View {
    let snapshot: CustomActivitySnapshot
    let accent: RGBAColor?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CustomSymbol.resolve(snapshot.symbol))
                .font(TypeToken.title.font)
                .foregroundStyle(accent.map(Palette.color) ?? Palette.textPrimary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.title).font(TypeToken.title.font).foregroundStyle(Palette.textPrimary).lineLimit(1)
                if let subtitle = snapshot.subtitle {
                    Text(subtitle).font(TypeToken.body.font).foregroundStyle(Palette.textSecondary).lineLimit(1)
                }
                if let progress = snapshot.progress {
                    ProgressView(value: progress)
                        .tint(accent.map(Palette.color) ?? Palette.textPrimary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }
}
