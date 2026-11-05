import IslandCore
import IslandDesign
import SwiftUI

/// F — Peek / Hover preview (340 × 62 pt): 34×34 cover or leading icon on the left, symbol/status in the right wing,
/// and a single-line title + subtitle row along the bottom; empty while only inviting (B).
struct PeekView: View {
    let layout: IslandLayout
    var notchWidth: CGFloat = 188
    let notchHeight: CGFloat
    @Environment(\.nowPlayingActions) private var nowPlayingActions

    var body: some View {
        if let primary = layout.primary {
            switch primary.content {
            case .nowPlaying(let track):
                nowPlayingPeek(track: track, accent: primary.accent)
            case .timer(let timer):
                genericPeek(
                    leading: { TimerCompactLeading(snapshot: timer) },
                    trailing: { TimerCompactTrailing(snapshot: timer) },
                    title: timer.label ?? "",
                    subtitle: nil)
            case .calendar(let event):
                genericPeek(
                    leading: { CalendarCompactLeading(event: event) },
                    trailing: { CalendarCompactTrailing(event: event) },
                    title: event.title,
                    subtitle: event.location)
            case .custom(let custom):
                genericPeek(
                    leading: { CustomCompactLeading(snapshot: custom, accent: primary.accent) },
                    trailing: { CustomCompactTrailing(snapshot: custom, accent: primary.accent) },
                    title: custom.title,
                    subtitle: custom.subtitle)
            }
        }
    }

    private func nowPlayingPeek(track: NowPlayingSnapshot, accent: RGBAColor?) -> some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Color.clear.frame(width: notchWidth)
                NowPlayingCompactTrailing(snapshot: track, accent: accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, Spacing.expandedPadding)
            .frame(height: notchHeight)

            HStack(alignment: .bottom, spacing: 12) {
                ArtworkImage(snapshot: track, side: 34, radius: Radii.artworkMedium)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    MarqueeText(text: track.title, font: TypeToken.title.font)
                        .foregroundStyle(Palette.textPrimary)
                    Text(track.artist)
                        .font(TypeToken.body.font)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 2) {
                    peekTransportButton("backward.fill", AccessibilityLabels.previous, nowPlayingActions.previous)
                    peekTransportButton(
                        track.isPlaying ? "pause.fill" : "play.fill",
                        AccessibilityLabels.playPause(isPlaying: track.isPlaying),
                        nowPlayingActions.playPause)
                    peekTransportButton("forward.fill", AccessibilityLabels.next, nowPlayingActions.next)
                }
            }
            .padding(Spacing.expandedPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }

    private func peekTransportButton(
        _ symbol: String, _ label: LocalizedStringResource, _ action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24, height: 24)
                .background(Palette.inkPressed, in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
        .accessibilityLabel(Text(label))
    }

    private func genericPeek<Leading: View, Trailing: View>(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        title: String,
        subtitle: String?
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                leading().frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: notchWidth)
                trailing().frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: notchHeight)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if !title.isEmpty {
                    MarqueeText(text: title, font: TypeToken.title.font)
                        .foregroundStyle(Palette.textPrimary)
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(TypeToken.body.font)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.bottom, Spacing.expandedPadding)
        }
        .padding(.horizontal, Spacing.expandedPadding)
    }
}
