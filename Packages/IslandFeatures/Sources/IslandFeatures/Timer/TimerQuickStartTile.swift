import IslandDesign
import SwiftUI

/// Home tile: 5 / 15 / 25 minute presets, Pomodoro and a custom duration.
struct TimerQuickStartTile: View {
    static let presetMinutes: [Double] = [5, 15, 25]
    @Environment(\.timerActions) private var actions
    @State private var customMinutes = 10.0
    @State private var showsCustom = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("timer.title", bundle: .module)
            } icon: {
                Image(systemName: "timer")
            }
            .font(TypeToken.caption.font)
            .foregroundStyle(Palette.textSecondary)
            HStack(spacing: 6) {
                ForEach(Self.presetMinutes, id: \.self) { minutes in
                    chip(Text("timer.minutes \(Int(minutes))", bundle: .module)) { actions.start(minutes) }
                }
            }
            HStack(spacing: 6) {
                chip(Text("timer.pomodoro", bundle: .module)) { actions.startPomodoro() }
                chip(Text("timer.custom", bundle: .module)) { showsCustom.toggle() }
                    .popover(isPresented: $showsCustom) {
                        VStack(spacing: 10) {
                            Stepper(value: $customMinutes, in: 1...180, step: 1) {
                                Text("timer.minutes \(Int(customMinutes))", bundle: .module).monospacedDigit()
                            }
                            Button {
                                showsCustom = false
                                actions.start(customMinutes)
                            } label: {
                                Text("timer.start", bundle: .module)
                            }
                            .keyboardShortcut(.defaultAction)
                        }
                        .padding(12)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(Palette.inkRaised, in: RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
    }

    private func chip(_ title: Text, action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            title.font(TypeToken.caption.font).monospacedDigit()
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Palette.inkPressed, in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.textPrimary)
    }
}
