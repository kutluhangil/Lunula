import SwiftUI

/// One screen: what Lunula is, launch-at-login (off by default), Start. No permission is requested here (spec §7).
struct OnboardingView: View {
    @State private var launchAtLogin = false
    let onStart: @MainActor (Bool) -> Void

    var body: some View {
        VStack(spacing: 20) {
            OnboardingLightAnimation()
            Text("onboarding.title").font(.title2.weight(.semibold))
            Text("onboarding.body")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Toggle("settings.general.launchAtLogin", isOn: $launchAtLogin)
            Button {
                onStart(launchAtLogin)
            } label: {
                Text("onboarding.start").frame(minWidth: 120)
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 420)
        .background(Color.black)
        .environment(\.colorScheme, .dark)
    }
}
