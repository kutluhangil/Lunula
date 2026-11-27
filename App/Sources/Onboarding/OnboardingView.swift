import IslandCore
import IslandDesign
import SwiftUI

/// Single-screen first-launch setup: style, surface material, launch-at-login (off by default), and Start button.
/// Dimensions: strictly 420 × 320 pt, continuous 16 pt corner radius, #08080A basalt background.
/// Zero TCC permission prompts (spec §7).
struct OnboardingView: View {
    @State private var launchAtLogin = false
    @State private var selectedStyle: IslandVisualStyle
    @State private var selectedMaterial: IslandSurfaceMaterial
    let onStart: @MainActor (Bool, IslandVisualStyle, IslandSurfaceMaterial) -> Void

    init(
        initialStyle: IslandVisualStyle = .lunula,
        initialMaterial: IslandSurfaceMaterial = .obsidian,
        onStart: @escaping @MainActor (Bool, IslandVisualStyle, IslandSurfaceMaterial) -> Void
    ) {
        _selectedStyle = State(initialValue: initialStyle)
        _selectedMaterial = State(initialValue: initialMaterial)
        self.onStart = onStart
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingLightAnimation(
                visualStyle: selectedStyle,
                surfaceMaterial: selectedMaterial
            )

            VStack(alignment: .leading, spacing: 0) {
                Text("onboarding.title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)

                Text("onboarding.subtitle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .padding(.top, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Text("settings.appearance.visualStyle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        LunulaSegmentPicker(
                            selection: $selectedStyle,
                            items: [
                                (value: IslandVisualStyle.lunula, label: "Lunula"),
                                (value: IslandVisualStyle.alcove, label: "Alcove"),
                                (value: IslandVisualStyle.boring, label: "Boring"),
                            ]
                        )
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)

                    Divider().background(Palette.hairline)

                    HStack(spacing: 8) {
                        Text("settings.appearance.surfaceMaterial")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        LunulaSegmentPicker(
                            selection: $selectedMaterial,
                            items: [
                                (
                                    value: IslandSurfaceMaterial.obsidian,
                                    label: String(localized: "settings.appearance.material.obsidian")
                                ),
                                (
                                    value: IslandSurfaceMaterial.liquidGlass,
                                    label: String(localized: "settings.appearance.material.liquidGlass")
                                ),
                            ]
                        )
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)

                    Divider().background(Palette.hairline)

                    HStack(spacing: 8) {
                        Text("settings.general.launchAtLogin")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.lunulaSwitch)
                            .labelsHidden()
                            .fixedSize()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
                .padding(.top, 10)

                Spacer(minLength: 8)

                Button {
                    onStart(launchAtLogin, selectedStyle, selectedMaterial)
                } label: {
                    Text("onboarding.start")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Palette.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 14)
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
