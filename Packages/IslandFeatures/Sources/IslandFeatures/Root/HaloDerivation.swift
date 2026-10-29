import AppKit
import IslandCore
import IslandDesign

/// Maps island state to the halo's light language (spec §6.4). Warming colour is owned by HaloStyle.
enum HaloDerivation {
    static let meetingWarmup: TimeInterval = 600

    static func state(phase: IslandPhase, layout: IslandLayout, now: Date) -> HaloState {
        switch phase {
        case .hidden, .idle:
            return .off
        case .transient(let alert):
            return HaloState(mode: .pulse, color: rgba(alert.tint))
        case .compact, .peek, .expanded:
            guard let activity = layout.primary else { return .off }
            return state(for: activity, now: now)
        }
    }

    private static func state(for activity: Activity, now: Date) -> HaloState {
        switch activity.content {
        case .nowPlaying(let track):
            guard track.isPlaying else { return .off }
            return HaloState(mode: .ambient(breathing: true), color: activity.accent ?? rgba(.neutral))
        case .timer(let timer):
            guard let endsAt = timer.endsAt, timer.duration > 0 else { return .off }
            let fraction = min(max(1 - endsAt.timeIntervalSince(now) / timer.duration, 0), 1)
            return HaloState(mode: .progress(fraction: fraction, endsAt: endsAt), color: rgba(.orange))
        case .calendar(let event):
            let remaining = event.start.timeIntervalSince(now)
            guard remaining > 0, remaining <= meetingWarmup else { return .off }
            return HaloState(mode: .warming(fraction: 1 - remaining / meetingWarmup), color: rgba(.neutral))
        case .custom:
            return .off
        }
    }

    static func rgba(_ tint: SignalTint) -> RGBAColor {
        if case .accent(let rgba) = tint { return rgba }
        let color: NSColor =
            switch tint {
            case .accent, .neutral: NSColor(srgbRed: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255, alpha: 1)
            case .green: .systemGreen
            case .orange: .systemOrange
            case .red: .systemRed
            }
        // The island is always dark, so resolve dynamic system colours in the dark appearance.
        var c = color
        NSAppearance(named: .darkAqua)?.performAsCurrentDrawingAppearance {
            c = color.usingColorSpace(.sRGB) ?? color
        }
        return RGBAColor(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent, alpha: c.alphaComponent)
    }
}
