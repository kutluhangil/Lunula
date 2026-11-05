import IslandDesign
import SwiftUI

/// One screen: what Lunula is, launch-at-login (off by default), Start button matching Claude Design Artboard 3.
/// Dimensions: strictly 420 × 320 pt, continuous 16 pt corner radius, #08080A basalt background.
/// No permission is requested here (spec §7).
struct OnboardingView: View {
    @State private var launchAtLogin = false
    let onStart: @MainActor (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingLightAnimation()

            VStack(alignment: .leading, spacing: 0) {
                Text("onboarding.title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)

                Text("onboarding.body")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                    .frame(height: 38, alignment: .topLeading)

                // Launch at login card
                HStack {
                    Text("settings.general.launchAtLogin")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(LunulaSwitchStyle())
                        .labelsHidden()
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
                .padding(.top, 16)

                // Start button
                Button {
                    onStart(launchAtLogin)
                } label: {
                    Text("onboarding.start")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Palette.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 420, height: 320)
        .background(Palette.basalt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 0.5)
        )
        .environment(\.colorScheme, .dark)
    }
}
