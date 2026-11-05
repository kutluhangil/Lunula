import IslandCore
import IslandDesign
import SwiftUI

/// I — Expanded Meeting (520 × 160 pt): title + time/service subtitle on top, full-width 36 pt #F5F5F7 Join button below.
struct CalendarExpandedCard: View {
    let event: EventSnapshot
    @Environment(\.calendarActions) private var actions

    var showsJoinButton: Bool { event.meetingLink != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(TypeToken.title.font)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(event.start, format: .dateTime.hour().minute())
                    Text(verbatim: "–")
                    Text(event.end, format: .dateTime.hour().minute())
                    if let detail = subtitleDetail {
                        Text(verbatim: "·")
                        Text(detail)
                    }
                }
                .font(TypeToken.body.font)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
            if let link = event.meetingLink {
                Button {
                    actions.join(link.url)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 13, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text("calendar.join", bundle: .module)
                            .font(TypeToken.title.font)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Palette.textPrimary, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
                    .foregroundStyle(Palette.obsidian)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(AccessibilityLabels.join))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var subtitleDetail: String? {
        if let service = event.meetingLink?.service {
            switch service {
            case .zoom: return "Zoom"
            case .googleMeet: return "Google Meet"
            case .teams: return "Teams"
            case .facetime: return "FaceTime"
            case .webex: return "Webex"
            }
        }
        if let location = event.location, !location.isEmpty { return location }
        return nil
    }
}
