import Foundation

public enum IslandReducer {
    public static func reduce(_ state: IslandState, _ event: IslandEvent) -> IslandTransition {
        var s = state
        var fx: [IslandEffect] = []
        let phase = state.phase

        switch event {
        case .pointerEnteredHotZone:
            switch phase {
            case .idle, .compact:
                s.pointerInside = true
                fx = [.schedule(.dwell, after: IslandTiming.dwell)]
            case .peek, .expanded, .transient:
                s.pointerInside = true
                fx = [.cancel(.exitGrace)]
            case .hidden: break
            }

        case .pointerDwellElapsed(let speed):
            guard phase == .idle || phase == .compact, s.pointerInside else { break }
            if speed < IslandTiming.maxPeekSpeed {
                s.phase = .peek
                fx = [.setMouseEventsIgnored(false)]
            } else {
                fx = [.schedule(.dwell, after: IslandTiming.dwell)]
            }

        case .pointerExitedIsland:
            switch phase {
            case .idle, .compact:
                s.pointerInside = false
                fx = [.cancel(.dwell)]
            case .peek, .expanded:
                s.pointerInside = false
                fx = [.schedule(.exitGrace, after: IslandTiming.exitGrace)]
            case .transient, .hidden:
                s.pointerInside = false
            }

        case .exitGraceElapsed:
            guard phase.isOpen, !s.pointerInside else { break }
            fx = collapse(&s)

        case .clicked(let target):
            switch phase {
            case .idle, .compact, .peek, .transient:
                if case .bubble(let id) = target {
                    s.phase = .expanded(.activity(id))
                } else {
                    s.phase = .expanded(.home)
                }
                // Expanded takes keyboard focus (Esc, arrows); the panel is non-activating, so the app stays inactive.
                fx = [
                    .cancel(.dwell), .cancel(.alertExpiry), .playHaptic(.alignment), .setMouseEventsIgnored(false),
                    .makePanelKey(true),
                ]
            default: break
            }

        case .swipedDown:
            switch phase {
            case .idle, .compact, .peek:
                s.phase = .expanded(.home)
                fx = [.cancel(.dwell), .setMouseEventsIgnored(false), .makePanelKey(true)]
            default: break
            }

        case .swipedUp, .clickedOutside:
            guard phase.isOpen else { break }
            fx = [.cancel(.exitGrace)] + collapse(&s)

        case .escapePressed:
            if phase.isOpen {
                fx = [.cancel(.exitGrace)] + collapse(&s)
            } else if case .transient = phase {
                fx = [.cancel(.alertExpiry)] + collapse(&s)
            }

        case .toggleRequested:
            switch phase {
            case .expanded:
                fx = collapse(&s)
            case .idle, .compact, .peek, .transient:
                s.phase = .expanded(.home)
                fx = [.cancel(.dwell), .cancel(.alertExpiry), .setMouseEventsIgnored(false), .makePanelKey(true)]
            case .hidden: break
            }

        case .pageSelected(let page):
            if case .expanded = phase { s.phase = .expanded(page) }

        case .fileDragApproached:
            guard phase != .hidden else { break }
            if case .transient(let a) = phase { enqueue(a, atFront: true, in: &s) }
            s.phase = .expanded(.shelf)
            fx = [.cancel(.dwell), .cancel(.exitGrace), .cancel(.alertExpiry), .setMouseEventsIgnored(false)]

        case .fileDragLeft:
            guard phase == .expanded(.shelf), !s.pointerInside else { break }
            fx = collapse(&s)

        case .activitiesChanged(let layout):
            s.layout = layout
            switch phase {
            case .idle, .compact: s.phase = s.restingPhase
            case .expanded(.activity(let id)) where !layout.contains(id): s.phase = .expanded(.home)
            default: break
            }

        case .alertRaised(let a):
            switch phase {
            case .idle, .compact, .peek:
                fx = show(a, in: &s)
            case .expanded:
                enqueue(a, atFront: false, in: &s)
                if a.kind == .timerFinished { fx = [.playSound(.timerFinished)] }
            case .transient(let current):
                if a.priority > current.priority {
                    fx = show(a, in: &s)
                    enqueue(current, atFront: true, in: &s)
                } else {
                    enqueue(a, atFront: false, in: &s)
                }
            case .hidden:
                guard a.priority == .critical, s.options.criticalAlertsInFullscreen else { break }
                s.phase = .transient(a)
                fx = [.schedule(.alertExpiry, after: IslandTiming.fullscreenCriticalAlert)]
                if a.kind == .timerFinished { fx.append(.playSound(.timerFinished)) }
            }

        case .alertExpired:
            if case .transient = phase { fx = collapse(&s) }

        case .fullscreenChanged(true):
            guard phase != .hidden else { break }
            s.isFullscreen = true
            guard s.options.hideInFullscreen else { break }
            s.phase = .hidden
            fx = cancelAll + [.setMouseEventsIgnored(true), .makePanelKey(false)]

        case .fullscreenChanged(false):
            s.isFullscreen = false
            if phase == .hidden { fx = collapse(&s) }

        case .displayConfigurationChanged, .systemWillSleep:
            s.pointerInside = false
            s.phase = s.restingPhase
            fx = cancelAll + [.setMouseEventsIgnored(true), .makePanelKey(false)]

        case .systemDidWake:
            s.pointerInside = false
            fx = collapse(&s)

        case .optionsChanged(let o):
            s.options = o
            if s.isFullscreen, !o.hideInFullscreen, phase == .hidden {
                s.phase = s.restingPhase
            } else if s.isFullscreen, o.hideInFullscreen, phase == .idle || phase == .compact {
                s.phase = .hidden
                fx = cancelAll + [.setMouseEventsIgnored(true), .makePanelKey(false)]
            }
        }

        return IslandTransition(state: s, effects: fx)
    }

    private static let cancelAll: [IslandEffect] = [.cancel(.dwell), .cancel(.exitGrace), .cancel(.alertExpiry)]

    /// Shows the next pending alert, or falls back to the resting phase.
    private static func collapse(_ s: inout IslandState) -> [IslandEffect] {
        if s.restingPhase == .hidden {
            // Fullscreen: only critical alerts may surface, briefly; the rest stay queued for later.
            guard s.options.criticalAlertsInFullscreen,
                let i = s.pendingAlerts.firstIndex(where: { $0.priority == .critical })
            else {
                s.phase = .hidden
                return [.setMouseEventsIgnored(true), .makePanelKey(false)]
            }
            let a = s.pendingAlerts.remove(at: i)
            s.phase = .transient(a)
            var fx: [IslandEffect] = [.schedule(.alertExpiry, after: IslandTiming.fullscreenCriticalAlert)]
            if a.kind == .timerFinished { fx.append(.playSound(.timerFinished)) }
            fx.append(.setMouseEventsIgnored(false))
            return fx
        }
        guard !s.pendingAlerts.isEmpty else {
            s.phase = s.restingPhase
            return [.setMouseEventsIgnored(true), .makePanelKey(false)]
        }
        let a = s.pendingAlerts.removeFirst()
        s.phase = .transient(a)
        var fx: [IslandEffect] = [.schedule(.alertExpiry, after: a.duration)]
        if a.kind == .timerFinished { fx.append(.playSound(.timerFinished)) }
        fx.append(.setMouseEventsIgnored(false))
        return fx
    }

    private static func show(_ a: TransientAlert, in s: inout IslandState) -> [IslandEffect] {
        s.phase = .transient(a)
        var fx: [IslandEffect] = [
            .cancel(.dwell), .schedule(.alertExpiry, after: a.duration), .setMouseEventsIgnored(false),
        ]
        if a.kind == .timerFinished { fx.append(.playSound(.timerFinished)) }
        return fx
    }

    private static func enqueue(_ a: TransientAlert, atFront: Bool, in s: inout IslandState) {
        s.pendingAlerts.insert(a, at: atFront ? 0 : s.pendingAlerts.endIndex)
        while s.pendingAlerts.count > IslandTiming.maxQueuedAlerts {
            // min(by:) keeps the first of equals, i.e. the oldest.
            if let i = s.pendingAlerts.indices.min(by: { s.pendingAlerts[$0].priority < s.pendingAlerts[$1].priority })
            {
                s.pendingAlerts.remove(at: i)
            }
        }
    }
}
