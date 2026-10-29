import IslandCore
import IslandDesign
import SwiftUI

/// Pure rendering of one island state inside the fixed panel (spec §4.1): island at top centre, halo above the
/// fill and outside the clip, detached activities as bubbles to the right.
struct IslandSurface: View {
    static let expandedWidth: CGFloat = 560
    static let expandedBodyHeight: CGFloat = 152

    let state: IslandState
    let notch: NotchMetrics
    let home: HomeInputs
    let now: Date
    let send: @MainActor (IslandEvent) -> Void
    let onHover: @MainActor (Bool) -> Void
    let openSettings: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.weatherInfo) private var weather
    @Environment(\.haloIntensity) private var haloIntensity
    @State private var budID: ActivityID?
    @State private var budProgress = 0.0

    var body: some View {
        let size = Self.islandSize(state: state, notch: notch)
        let island = Self.islandRect(size: size)
        let shape = state.phase.isOpen ? IslandShape.expanded : IslandShape.closed
        let halo = scaled(homeHalo(HaloDerivation.state(phase: state.phase, layout: state.layout, now: now)))

        ZStack(alignment: .topLeading) {
            ZStack {
                Palette.obsidian
                content(size: size)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .contentShape(shape)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(AccessibilityLabels.island(summary: Self.summary(state))))
            .accessibilityAddTraits(.isButton)
            .onHover { onHover($0) }
            .offset(x: island.minX)

            if halo.mode != .off {
                let pad = HaloStyle.glowRadius
                HaloView(
                    state: halo,
                    outline: shape.path(in: CGRect(x: pad, y: pad, width: size.width, height: size.height)).cgPath,
                    lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
                )
                .frame(width: size.width + 2 * pad, height: size.height + 2 * pad)
                .offset(x: island.minX - pad, y: -pad)
                .allowsHitTesting(false)
            }

            ForEach(Array(state.layout.detached.enumerated()), id: \.element.id) { index, activity in
                let rect = Self.bubbleRect(index: index, island: island, side: notch.size.height)
                BubbleView(activity: activity, side: rect.width)
                    .offset(x: rect.minX, y: rect.minY)
                    .opacity(activity.id == budID ? 0 : 1)
                    .transition(reduceMotion ? MotionToken.reducedTransition : .opacity)
            }

            if let budID, let index = state.layout.detached.firstIndex(where: { $0.id == budID }) {
                let end = Self.bubbleRect(index: index, island: island, side: notch.size.height)
                MetaballBridge(
                    islandRect: island,
                    bubbleStart: end.offsetBy(dx: island.maxX - end.maxX, dy: 0),
                    bubbleEnd: end, progress: budProgress, islandCornerRadius: shape.cornerRadius
                )
                .allowsHitTesting(false)
            }
        }
        .frame(width: IslandMetrics.panelSize.width, height: IslandMetrics.panelSize.height, alignment: .topLeading)
        .opacity(state.phase == .hidden ? 0 : 1)
        .animation(
            MotionToken.animation(state.phase.isOpen ? .open : .close, reduceMotion: reduceMotion), value: state.phase
        )
        .animation(MotionToken.animation(.morph, reduceMotion: reduceMotion), value: state.layout)
        .onChange(of: state.layout.detached.map(\.id)) { old, new in startBud(old: old, new: new) }
    }

    @ViewBuilder private func content(size: CGSize) -> some View {
        Group {
            switch state.phase {
            case .hidden, .idle:
                EmptyView()
            case .compact:
                if let primary = state.layout.primary {
                    CompactLayoutView(activity: primary, notchWidth: notch.size.width)
                }
            case .transient(let alert):
                TransientAlertView(alert: alert, notchWidth: notch.size.width, notchHeight: notch.size.height)
            case .peek:
                PeekView(layout: state.layout, notchHeight: notch.size.height)
            case .expanded(let page):
                ExpandedView(
                    page: page, layout: state.layout, home: home, notch: notch, send: send, openSettings: openSettings)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .transition(reduceMotion ? MotionToken.reducedTransition : .opacity)
    }

    /// Applies the user's halo intensity; zero turns the halo off entirely.
    private func scaled(_ halo: HaloState) -> HaloState {
        var halo = halo
        halo.intensityScale *= haloIntensity()
        return halo.intensityScale > 0 ? halo : .off
    }

    /// On the home page with nothing else lit, a faint time-of-day tint (spec §6.4 daylight).
    private func homeHalo(_ derived: HaloState) -> HaloState {
        guard derived.mode == .off, state.phase == .expanded(.home), let current = weather.current() else {
            return derived
        }
        let s = current.snapshot
        let phase = DaylightPhase.phase(now: now, sunrise: s.sunrise, sunset: s.sunset, isDaylight: s.isDaylight)
        return HaloState(
            mode: .ambient(breathing: false), color: Daylight.color(phase), intensityScale: Daylight.intensityScale)
    }

    /// Reduce Motion: no metaball bridge, the bubble simply fades in (Phase 2 carry-over).
    private func startBud(old: [ActivityID], new: [ActivityID]) {
        guard !reduceMotion, let added = new.first(where: { !old.contains($0) }) else { return }
        budID = added
        budProgress = 0
        withAnimation(MotionToken.animation(.bud, reduceMotion: false)) {
            budProgress = 1
        } completion: {
            budID = nil
        }
    }

    /// Short spoken summary of what the island shows (VoiceOver).
    static func summary(_ state: IslandState) -> String {
        if case .transient(let alert) = state.phase, case .text(let title, _, _) = alert.detail { return title }
        switch state.layout.primary?.content {
        case .nowPlaying(let track)?: return "\(track.title), \(track.artist)"
        case .timer(let timer)?: return timer.label ?? ""
        case .calendar(let event)?: return event.title
        case .custom(let custom)?: return custom.title
        case nil: return ""
        }
    }

    static func islandSize(state: IslandState, notch: NotchMetrics) -> CGSize {
        let request: IslandSizeRequest =
            switch state.phase {
            case .hidden, .idle: .idle
            case .compact: state.layout.primary == nil ? .idle : .compact(wing: IslandMetrics.wingMax)
            case .transient(let alert):
                TransientAlertView.needsButtons(alert) ? .peek : .compact(wing: IslandMetrics.wingMax)
            case .peek: state.layout.primary == nil ? .invite : .peek
            case .expanded: .expanded(width: expandedWidth, bodyHeight: expandedBodyHeight)
            }
        return IslandMetrics.size(for: request, notch: notch)
    }

    /// Panel-local rect; the panel is centred on the notch, so the island is horizontally centred at the top.
    static func islandRect(size: CGSize) -> CGRect {
        CGRect(x: (IslandMetrics.panelSize.width - size.width) / 2, y: 0, width: size.width, height: size.height)
    }

    static func bubbleRect(index: Int, island: CGRect, side: CGFloat) -> CGRect {
        CGRect(
            x: island.maxX + IslandMetrics.bubbleGap + CGFloat(index) * (side + IslandMetrics.bubbleGap), y: 0,
            width: side, height: side)
    }
}

extension EnvironmentValues {
    /// User's halo intensity (Settings › Appearance, 0…1); read in the body so changes apply live.
    @Entry public var haloIntensity: @MainActor () -> Double = { 1 }
}
