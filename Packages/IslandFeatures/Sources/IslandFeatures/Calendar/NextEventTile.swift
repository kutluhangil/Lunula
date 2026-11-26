import IslandCore
import IslandDesign
import SwiftUI

struct NextEventTile: View {
    let event: EventSnapshot
    @Environment(\.calendarActions) private var actions
    @State private var showAgenda = false

    var body: some View {
        let upcoming = actions.upcomingToday()
        let extraCount = max(0, upcoming.count - 1)
        Button {
            showAgenda.toggle()
        } label: {
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
                    HStack(spacing: 6) {
                        Text(event.start, format: .dateTime.hour().minute())
                            .font(TypeToken.caption.font.monospacedDigit())
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                        if extraCount > 0 {
                            Text(verbatim: "+\(extraCount)")
                                .font(TypeToken.caption.font.monospacedDigit())
                                .foregroundStyle(Palette.signalOrange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .islandCard()
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showAgenda, arrowEdge: .bottom) {
            CalendarAgendaPopover()
        }
    }
}

/// Full-day agenda popover showing today's all-day items and remaining chronological schedule.
struct CalendarAgendaPopover: View {
    @Environment(\.calendarActions) private var actions

    var body: some View {
        let allDay = actions.allDayToday()
        let upcoming = actions.upcomingToday()
        VStack(alignment: .leading, spacing: 8) {
            Text("calendar.agenda.title", bundle: .module)
                .font(TypeToken.title.font)
                .foregroundStyle(Palette.textPrimary)

            if allDay.isEmpty && upcoming.isEmpty {
                Text("calendar.agenda.empty", bundle: .module)
                    .font(TypeToken.caption.font)
                    .foregroundStyle(Palette.textSecondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(allDay, id: \.eventID) { item in
                            agendaRow(item: item, isAllDay: true)
                        }
                        ForEach(upcoming, id: \.eventID) { item in
                            agendaRow(item: item, isAllDay: false)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    private func agendaRow(item: EventSnapshot, isAllDay: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.calendarColor.map(Palette.color) ?? Palette.signalOrange)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(TypeToken.body.font)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                if isAllDay {
                    Text("calendar.agenda.allDay", bundle: .module)
                        .font(TypeToken.caption.font)
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    HStack(spacing: 3) {
                        Text(item.start, format: .dateTime.hour().minute())
                        Text(verbatim: "–")
                        Text(item.end, format: .dateTime.hour().minute())
                    }
                    .font(TypeToken.caption.font.monospacedDigit())
                    .foregroundStyle(Palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let link = item.meetingLink {
                Button {
                    actions.join(link.url)
                } label: {
                    Text("calendar.join", bundle: .module)
                        .font(TypeToken.caption.font)
                        .foregroundStyle(Palette.obsidian)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Palette.textPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
