import IslandCore
import IslandDesign
import SwiftUI

struct NowPlayingExpandedCard: View {
    let snapshot: NowPlayingSnapshot
    let accent: RGBAColor?
    @Environment(\.nowPlayingActions) private var actions
    @Environment(\.quickTools) private var quickTools
    @Environment(\.calendarActions) private var calendarActions

    init(snapshot: NowPlayingSnapshot, accent: RGBAColor?) {
        self.snapshot = snapshot
        self.accent = accent
    }

    var body: some View {
        let style = quickTools.visualStyle()
        let bands = quickTools.audioSpectrumBands()

        HStack(alignment: .center, spacing: style == .boring ? 10 : 12) {
            ArtworkImage(snapshot: snapshot, side: 64, radius: Radii.artworkLarge, morphID: "hero-artwork")
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.title)
                            .font(TypeToken.title.font)
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(style == .boring ? 1 : 2)
                            .truncationMode(.tail)
                        Text(snapshot.artist)
                            .font(TypeToken.body.font)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if quickTools.liveAudioSpectrumEnabled() || style == .boring {
                        AudioSpectrumBarsView(
                            levels: bands,
                            isPlaying: snapshot.isPlaying,
                            accent: accent,
                            barWidth: 3,
                            height: 18
                        )
                    }
                }
                NowPlayingProgressBar(snapshot: snapshot, accent: accent)
                    .padding(.top, style == .boring ? 4 : 6)
                if let pair = quickTools.activeLyricLines(snapshot)
                    ?? quickTools.activeLyricLine(snapshot).map({ ($0, nil) }),
                    !pair.active.isEmpty
                {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Image(systemName: "music.mic")
                                .font(.system(size: 11, weight: .medium))
                            Text(pair.active)
                                .font(TypeToken.body.font)
                                .foregroundStyle(Palette.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        if let next = pair.next, !next.isEmpty {
                            Text(next)
                                .font(TypeToken.caption.font)
                                .foregroundStyle(Palette.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 15)
                        }
                    }
                    .padding(.top, 2)
                }
                if style == .boring {
                    boringInlineTransportRow
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if style == .boring {
                boringTodayAgendaCard
            } else {
                trailingTransportColumn(style: style)
            }
        }
        .frame(maxWidth: .infinity)
        .contextMenu {
            if snapshot.source == .music {
                Button(action: actions.toggleFavorite) {
                    Text("nowPlaying.favorite", bundle: .module)
                }
            }
            Button(action: actions.toggleShuffle) {
                Text("nowPlaying.shuffle", bundle: .module)
            }
            Button(action: actions.cycleRepeat) {
                Text("nowPlaying.repeat", bundle: .module)
            }
            Menu {
                ForEach([25, 50, 75, 100], id: \.self) { level in
                    Button("\(level)%") {
                        actions.setVolume(level)
                    }
                }
            } label: {
                Text("nowPlaying.appVolume", bundle: .module)
            }
        }
    }

    private var boringInlineTransportRow: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                if snapshot.source == .music {
                    favoriteButton(side: 24)
                }
                secondaryControl("shuffle", "nowPlaying.shuffle", side: 24, actions.toggleShuffle)
                control("backward.fill", AccessibilityLabels.previous, side: 28, actions.previous)
                playPauseFilledButton(side: 30)
                control("forward.fill", AccessibilityLabels.next, side: 28, actions.next)
                secondaryControl("repeat", "nowPlaying.repeat", side: 24, actions.cycleRepeat)
            }
            if let volume = snapshot.soundVolume {
                Spacer(minLength: 4)
                NowPlayingVolumeSlider(volume: volume, accent: accent)
            }
        }
    }

    private func trailingTransportColumn(style: IslandVisualStyle) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 4) {
                if snapshot.source == .music {
                    favoriteButton(side: 26)
                }
                control("backward.fill", AccessibilityLabels.previous, actions.previous)
                if style == .lunula {
                    playPauseFilledButton(side: 32)
                } else {
                    control(
                        snapshot.isPlaying ? "pause.fill" : "play.fill",
                        AccessibilityLabels.playPause(isPlaying: snapshot.isPlaying), actions.playPause)
                }
                control("forward.fill", AccessibilityLabels.next, actions.next)
            }
            if let volume = snapshot.soundVolume {
                NowPlayingVolumeSlider(volume: volume, accent: accent)
            }
        }
    }

    private func favoriteButton(side: CGFloat) -> some View {
        Button(action: actions.toggleFavorite) {
            Image(systemName: "heart")
                .font(.system(size: 12, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .frame(width: side, height: side)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textSecondary)
        .accessibilityLabel(Text("nowPlaying.favorite", bundle: .module))
    }

    private func playPauseFilledButton(side: CGFloat = 32) -> some View {
        Button(action: actions.playPause) {
            Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.obsidian)
                .frame(width: side, height: side)
                .background(Palette.textPrimary, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(AccessibilityLabels.playPause(isPlaying: snapshot.isPlaying)))
    }

    private func secondaryControl(
        _ symbol: String, _ key: LocalizedStringKey, side: CGFloat = 26, _ action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .frame(width: side, height: side)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textSecondary)
        .accessibilityLabel(Text(key, bundle: .module))
    }

    private var boringTodayAgendaCard: some View {
        let upcoming = calendarActions.upcomingToday()
        let fallback = calendarActions.nextEvent().map { [$0] } ?? []
        let events = Array((upcoming.isEmpty ? fallback : upcoming).prefix(2))

        return VStack(alignment: .leading, spacing: 4) {
            Text("calendar.today", bundle: .module)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.amberGold)
                .lineLimit(1)

            if events.isEmpty {
                Text("calendar.agenda.empty", bundle: .module)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            } else {
                ForEach(events, id: \.eventID) { event in
                    boringAgendaEventRow(event)
                }
            }
        }
        .padding(8)
        .frame(width: 126, alignment: .leading)
        .islandCard()
    }

    @ViewBuilder
    private func boringAgendaEventRow(_ event: EventSnapshot) -> some View {
        let row = VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Circle()
                    .fill(event.calendarColor.map(Palette.color) ?? Palette.signalOrange)
                    .frame(width: 5, height: 5)
                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            if event.isAllDay {
                Text("calendar.agenda.allDay", bundle: .module)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            } else {
                Text(event.start, format: .dateTime.hour().minute())
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())

        if let url = event.meetingLink?.url {
            Button {
                calendarActions.join(url)
            } label: {
                row
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AccessibilityLabels.join))
        } else {
            row
        }
    }

    private func control(
        _ symbol: String, _ label: LocalizedStringResource, side: CGFloat = 32,
        _ action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(TypeToken.title.font)
                .symbolRenderingMode(.hierarchical)
                .frame(width: side, height: side)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
        .accessibilityLabel(Text(label))
    }
}
