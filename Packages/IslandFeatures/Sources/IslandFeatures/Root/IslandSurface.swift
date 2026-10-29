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
    @State private var budID: ActivityID?
    @State private var budProgress = 0.0

    var body: some View {
        let size = Self.islandSize(state: state, notch: notch)
        let island = Self.islandRect(size: size)
        let shape = state.phase.isOpen ? IslandShape.expanded : IslandShape.closed
        let halo = HaloDerivation.state(phase: state.phase, layout: state.layout, now: now)

        ZStack(alignment: .topLeading) {
            ZStack {
                Palette.obsidian
                content(size: size)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
            .contentShape(shape)
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
                TransientRow(alert: alert, notchWidth: notch.size.width)
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

    static func islandSize(state: IslandState, notch: NotchMetrics) -> CGSize {
        let request: IslandSizeRequest =
            switch state.phase {
            case .hidden, .idle: .idle
            case .compact: state.layout.primary == nil ? .idle : .compact(wing: IslandMetrics.wingMax)
            case .transient: .compact(wing: IslandMetrics.wingMax)
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

/// Transient alert in the compact wings: symbol left, nothing right (feature tasks refine it).
private struct TransientRow: View {
    let alert: TransientAlert
    let notchWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "bell.fill").font(TypeToken.body.font).foregroundStyle(Palette.textPrimary)
                .frame(maxWidth: .infinity)
            Color.clear.frame(width: notchWidth)
            Color.clear.frame(maxWidth: .infinity)
        }
    }
}
