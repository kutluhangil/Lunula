import AppKit
import IslandDesign
import SwiftUI

/// Shown while calendar access is undetermined; tapping is the only path to the system prompt.
struct CalendarAccessTile: View {
    @Environment(\.calendarActions) private var actions

    var body: some View {
        Button {
            NSApp.activate()
            actions.requestAccess()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "calendar.badge.plus").font(TypeToken.title.font)
                Text("calendar.connect", bundle: .module).font(TypeToken.caption.font)
            }
            .foregroundStyle(Palette.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12)
            .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
