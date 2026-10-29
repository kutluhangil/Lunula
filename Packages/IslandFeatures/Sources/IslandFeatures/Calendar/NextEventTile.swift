import IslandCore
import IslandDesign
import SwiftUI

struct NextEventTile: View {
    let event: EventSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("calendar.next", bundle: .module).font(TypeToken.caption.font).foregroundStyle(Palette.textSecondary)
            Text(event.start, format: .dateTime.hour().minute())
                .font(TypeToken.title.font).monospacedDigit().foregroundStyle(Palette.textPrimary)
            Text(event.title).font(TypeToken.caption.font).foregroundStyle(Palette.textPrimary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }
}
