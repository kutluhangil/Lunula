import IslandCore
import IslandDesign
import SwiftUI

/// I — Expanded Meeting (520 × 160 pt): title + time/service subtitle on top, full-width 36 pt #F5F5F7 Join button below.
struct CalendarExpandedCard: View {
    let event: EventSnapshot
    @Environment(\.calendarActions) private var actions

    var showsJoinButton: Bool { event.meetingLink != nil }

    var body: some View {
        let laterEvents = actions.upcomingToday().filter { $0.eventID != event.eventID }.prefix(2)
        VStack(alignment: .leading, spacing: 8) {
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
            if !laterEvents.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(laterEvents), id: \.eventID) { next in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(next.calendarColor.map(Palette.color) ?? Palette.signalOrange)
                                .frame(width: 5, height: 5)
                            Text(next.start, format: .dateTime.hour().minute())
                                .font(TypeToken.caption.font.monospacedDigit())
                                .foregroundStyle(Palette.textSecondary)
                            Text(next.title)
                                .font(TypeToken.caption.font)
                                .foregroundStyle(Palette.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            if let link = next.meetingLink {
                                Button {
                                    actions.join(link.url)
                                } label: {
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(AccessibilityLabels.join))
                            }
                        }
                    }
                }
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
