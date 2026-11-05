import IslandCore
import IslandDesign
import SwiftUI

/// Pure rendering of one island state inside the fixed panel (spec §4.1): island at top centre, halo above the
/// fill and outside the clip, detached activities as bubbles to the right.
struct IslandSurface: View {
    static let expandedWidth: CGFloat = 520
    static let expandedBodyHeight: CGFloat = IslandMetrics.expandedBodyHome

    let state: IslandState
    let notch: NotchMetrics
    let home: HomeInputs
    let now: Date
    let send: @MainActor (IslandEvent) -> Void
    let openSettings: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.weatherInfo) private var weather
    @Environment(\.haloIntensity) private var haloIntensity
    @Environment(\.shelfActions) private var shelfActions
    @Environment(\.privacyInfo) private var privacyInfo
    @Environment(\.quickTools) private var quickTools
    @State private var budID: ActivityID?
    @State private var budProgress = 0.0

    var body: some View {
        let size = Self.islandSize(state: state, notch: notch, shelfIsEmpty: shelfActions.items().isEmpty)
        let island = Self.islandRect(
            size: size, notch: notch, phase: state.phase, pillOffset: CGFloat(quickTools.pillVerticalOffset()))
        let shape = Self.islandShape(phase: state.phase, hasPrimary: state.layout.primary != nil, notch: notch)
        let halo = scaled(homeHalo(HaloDerivation.state(phase: state.phase, layout: state.layout, now: now)))
        let privacy = privacyInfo.current()
        let isHidden = state.phase == .hidden || (!notch.hasHardwareNotch && state.phase == .idle)

        ZStack(alignment: .topLeading) {
            if quickTools.hideNotchBar(), notch.hasHardwareNotch {
                Palette.obsidian
                    .frame(width: IslandMetrics.panelSize.width, height: notch.size.height)
                    .allowsHitTesting(false)
            }
            ZStack {
                Palette.obsidian
                content(size: size)
                    .environment(\.islandCardGlass, quickTools.useGlassCards())
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .contentShape(shape)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(AccessibilityLabels.island(summary: Self.summary(state))))
            .accessibilityAddTraits(.isButton)
            // While open or peeking the panel takes the mouse instead of the hot zone; the reducer ignores clicks
            // where they mean nothing (expanded), and controls inside keep their own taps.
            .onTapGesture { send(.clicked(.island)) }
            .offset(x: island.minX, y: island.minY)

            if halo.mode != .off {
                let pad = HaloStyle.glowRadius
                HaloView(
                    state: halo,
                    outline: shape.path(in: CGRect(x: pad, y: pad, width: size.width, height: size.height)).cgPath,
                    lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
                )
                .frame(width: size.width + 2 * pad, height: size.height + 2 * pad)
                .offset(x: island.minX - pad, y: island.minY - pad)
                .allowsHitTesting(false)
            }

            ForEach(Array(state.layout.detached.enumerated()), id: \.element.id) { index, activity in
                let rect = Self.bubbleRect(index: index, island: island, side: notch.size.height)
                BubbleView(activity: activity, side: rect.width)
                    .onTapGesture { send(.clicked(.bubble(activity.id))) }
                    .offset(x: rect.minX, y: rect.minY)
                    .opacity(activity.id == budID ? 0 : 1)
                    .transition(reduceMotion ? MotionToken.reducedTransition : .opacity)
            }

            if privacy != .none {
                let lastBubble = state.layout.detached.indices.last.map {
                    Self.bubbleRect(index: $0, island: island, side: notch.size.height)
                }
                let rightEdge = lastBubble?.maxX ?? island.maxX
                PrivacyDotView(privacy: privacy)
                    .offset(x: rightEdge + 8, y: island.minY + (notch.size.height - 6) / 2)
                    .allowsHitTesting(false)
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
        .opacity(isHidden ? 0 : 1)
        .animation(
            MotionToken.animation(Self.motionToken(for: state.phase), reduceMotion: reduceMotion), value: state.phase
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
                    CompactLayoutView(
                        activity: primary, notchWidth: notch.size.width, hasHardwareNotch: notch.hasHardwareNotch)
                }
            case .transient(let alert):
                TransientAlertView(alert: alert, notchWidth: notch.size.width, notchHeight: notch.size.height)
            case .peek:
                PeekView(layout: state.layout, notchWidth: notch.size.width, notchHeight: notch.size.height)
            case .expanded(let page):
                ExpandedView(
                    page: page, layout: state.layout, home: home, notch: notch, send: send, openSettings: openSettings)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .transition(reduceMotion ? MotionToken.reducedTransition : Self.contentTransition)
    }

    /// Content settles in just behind the shape (slight lift from the top edge) and leaves quickly.
    private static let contentTransition = AnyTransition.asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
            .animation(.smooth(duration: 0.35).delay(0.08)),
        removal: .opacity.animation(.smooth(duration: 0.12)))

    /// Applies the user's halo intensity; zero turns the halo off entirely.
    private func scaled(_ halo: HaloState) -> HaloState {
        var halo = halo
        halo.intensityScale *= haloIntensity.current()
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

    static func motionToken(for phase: IslandPhase) -> MotionToken {
        switch phase {
        case .expanded: .open
        case .peek: .peek
        case .transient(let alert) where TransientAlertView.needsButtons(alert): .peek
        default: .close
        }
    }

    static func islandShape(phase: IslandPhase, hasPrimary: Bool = true, notch: NotchMetrics) -> IslandShape {
        switch phase {
        case .expanded:
            return .expanded
        case .peek where hasPrimary:
            return .expanded
        case .transient(let alert) where TransientAlertView.needsButtons(alert):
            return .expanded
        default:
            return notch.hasHardwareNotch ? .closed : .pill
        }
    }

    static func compactWing(for activity: Activity) -> CGFloat {
        switch activity.kind {
        case .nowPlaying: IslandMetrics.wingNowPlaying
        case .timer, .calendar, .custom: IslandMetrics.wingTimer
        }
    }

    static func compactWing(for alert: TransientAlert) -> CGFloat {
        switch alert.kind {
        case .charging, .unplugged, .batteryLow, .batteryFull:
            IslandMetrics.wingNowPlaying
        default:
            IslandMetrics.wingMax
        }
    }

    static func islandSize(state: IslandState, notch: NotchMetrics, shelfIsEmpty: Bool = false) -> CGSize {
        let request: IslandSizeRequest =
            switch state.phase {
            case .hidden, .idle:
                .idle
            case .compact:
                if let primary = state.layout.primary {
                    .compact(wing: compactWing(for: primary))
                } else {
                    .idle
                }
            case .transient(let alert):
                TransientAlertView.needsButtons(alert) ? .downloadAlert : .compact(wing: compactWing(for: alert))
            case .peek:
                state.layout.primary == nil ? .invite : .peek
            case .expanded(let page):
                switch page {
                case .home:
                    .expanded(width: expandedWidth, bodyHeight: IslandMetrics.expandedBodyHome)
                case .shelf:
                    .expanded(
                        width: expandedWidth,
                        bodyHeight: shelfIsEmpty
                            ? IslandMetrics.expandedBodyCompact : IslandMetrics.expandedBodyShelf)
                case .activity:
                    .expanded(width: expandedWidth, bodyHeight: IslandMetrics.expandedBodyCompact)
                }
            }
        return IslandMetrics.size(for: request, notch: notch)
    }

    /// Panel-local rect; the panel is centred on the notch, so the island is horizontally centred at the top.
    static func islandRect(
        size: CGSize, notch: NotchMetrics? = nil, phase: IslandPhase = .idle, pillOffset: CGFloat = 0
    ) -> CGRect {
        let isPill =
            if let notch, !notch.hasHardwareNotch {
                switch phase {
                case .idle, .compact, .transient: true
                default: false
                }
            } else {
                false
            }
        return CGRect(
            x: (IslandMetrics.panelSize.width - size.width) / 2,
            y: isPill ? 1 + max(0, pillOffset) : 0,
            width: size.width,
            height: size.height)
    }

    static func bubbleRect(index: Int, island: CGRect, side: CGFloat) -> CGRect {
        CGRect(
            x: island.maxX + IslandMetrics.bubbleGap + CGFloat(index) * (side + IslandMetrics.bubbleGap), y: 0,
            width: side, height: side)
    }
}

public struct HaloIntensity {
    public var current: @MainActor () -> Double = { 1 }
    public init(current: @escaping @MainActor () -> Double) { self.current = current }
    init() {}
}

extension EnvironmentValues {
    /// User's halo intensity (Settings › Appearance, 0…1); read in the body so changes apply live.
    @Entry public var haloIntensity = HaloIntensity()
}
