import IslandCore
import IslandDesign
import SwiftUI

struct CustomCompactLeading: View {
    let snapshot: CustomActivitySnapshot
    let accent: RGBAColor?

    var body: some View {
        Image(systemName: CustomSymbol.resolve(snapshot.symbol))
            .font(TypeToken.body.font)
            .foregroundStyle(accent.map(Palette.color) ?? Palette.textPrimary)
    }
}

/// Live recording timer, progress ring, or a system-clock countdown when the activity has an end time; otherwise empty.
struct CustomCompactTrailing: View {
    let snapshot: CustomActivitySnapshot
    let accent: RGBAColor?
    @Environment(\.quickTools) private var quickTools

    var body: some View {
        if snapshot.symbol == "record.circle.fill", let startedAt = quickTools.recordingStartedAt() {
            Text(timerInterval: min(startedAt, .now)...Date.distantFuture, countsDown: false)
                .font(TypeToken.numeralCompact.font.monospacedDigit())
                .foregroundStyle(Palette.signalRed)
                .lineLimit(1)
        } else if let progress = snapshot.progress {
            ZStack {
                Circle().stroke(Palette.inkPressed, lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accent.map(Palette.color) ?? Palette.textPrimary, style: .init(lineWidth: 2.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 14, height: 14)
        } else if let endsAt = snapshot.endsAt {
            Text(timerInterval: Date.now...max(endsAt, .now), countsDown: true)
                .font(TypeToken.numeralCompact.font).monospacedDigit().foregroundStyle(Palette.textPrimary)
        }
    }
}
