import IslandCore
import IslandDesign
import SwiftUI

struct CalendarExpandedCard: View {
    let event: EventSnapshot
    @Environment(\.calendarActions) private var actions

    var showsJoinButton: Bool { event.meetingLink != nil }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.calendarColor.map(Palette.color) ?? Palette.textSecondary)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(TypeToken.title.font).foregroundStyle(Palette.textPrimary).lineLimit(2)
                HStack(spacing: 4) {
                    Text(event.start, format: .dateTime.hour().minute())
                    Text(verbatim: "–")
                    Text(event.end, format: .dateTime.hour().minute())
                }
                .font(TypeToken.body.font)
                .foregroundStyle(Palette.textSecondary)
                if let location = event.location, !location.isEmpty {
                    Text(location).font(TypeToken.caption.font).foregroundStyle(Palette.textTertiary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if let link = event.meetingLink {
                Button {
                    actions.join(link.url)
                } label: {
                    Label {
                        Text("calendar.join", bundle: .module)
                    } icon: {
                        Image(systemName: "video.fill")
                    }
                    .font(TypeToken.body.font)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Palette.signalGreen.opacity(0.25), in: Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityLabel(Text(AccessibilityLabels.join))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }
}
