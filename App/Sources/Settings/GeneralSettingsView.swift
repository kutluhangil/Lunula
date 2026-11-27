import IslandCore
import IslandDesign
import IslandServices
import KeyboardShortcuts
import SwiftUI

public struct GeneralSettingsView: View {
    let settings: SettingsStore
    let launchAtLogin: LaunchAtLoginService
    var onDisplayModeChanged: ((DisplayMode) -> Void)?
    var onResetDefaults: (() -> Void)?

    @State private var loginError = false
    @State private var confirmingReset = false
    @State private var didReset = false

    public init(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        onDisplayModeChanged: ((DisplayMode) -> Void)? = nil,
        onResetDefaults: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.onDisplayModeChanged = onDisplayModeChanged
        self.onResetDefaults = onResetDefaults
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - System & startup
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.general.section.system")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.launchAtLogin")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.launchAtLogin.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { launchAtLogin.isEnabled },
                                set: { on in
                                    do { try launchAtLogin.setEnabled(on) } catch { loginError = true }
                                }
                            )
                        )
                        .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    if launchAtLogin.requiresApproval || loginError {
                        Divider()
                            .background(Palette.hairline)

                        HStack(spacing: 12) {
                            Circle()
                                .fill(Palette.amberGold)
                                .frame(width: 6, height: 6)

                            Text("settings.general.loginApproval")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.amberGold)

                            Spacer()

                            Button {
                                launchAtLogin.openSystemSettings()
                            } label: {
                                Text("settings.general.openLoginItemsButton")
                            }
                            .buttonStyle(.lunulaSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }

                    Divider()
                        .background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.showMenuBarIcon")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.showMenuBarIcon.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.showMenuBarIcon))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Displays
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.general.section.displays")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                HStack(spacing: 8) {
                    displayModeCard(
                        titleKey: "settings.displayMode.notchedOnly",
                        subtitleKey: "settings.displayMode.notchedOnly.subtitle",
                        mode: .notchedOnly,
                        illustration: AnyView(notchedOnlyIllustration)
                    )

                    displayModeCard(
                        titleKey: "settings.displayMode.allDisplays",
                        subtitleKey: "settings.displayMode.allDisplays.subtitle",
                        mode: .allDisplays,
                        illustration: AnyView(allDisplaysIllustration)
                    )

                    displayModeCard(
                        titleKey: "settings.displayMode.mainDisplay",
                        subtitleKey: "settings.displayMode.mainDisplay.subtitle",
                        mode: .mainDisplay,
                        illustration: AnyView(mainDisplayIllustration)
                    )
                }
                .padding(12)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Full screen
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.general.section.fullscreen")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.hideInFullscreen")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.hideInFullscreen.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.hideInFullscreen))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    Divider()
                        .background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.criticalAlertsInFullscreen")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.criticalAlertsInFullscreen.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.criticalAlertsInFullscreen))
                            .toggleStyle(.lunulaSwitch)
                            .disabled(!settings.settings.hideInFullscreen)
                            .opacity(settings.settings.hideInFullscreen ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Shortcuts
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.general.section.shortcuts")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.toggleIsland")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.toggleIsland.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        KeyboardShortcuts.Recorder(for: .toggleIsland)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    Divider()
                        .background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.appearance.doubleTapOption")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.doubleTapOption.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.doubleTapOptionToToggle))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Gestures
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.general.section.gestures")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.hoverToPeek")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.hoverToPeek.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.hoverToPeekEnabled))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    Divider()
                        .background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.general.swipeGestures")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.general.swipeGestures.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.swipeGesturesEnabled))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Reset
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.general.section.reset")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.general.reset.title")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Palette.textPrimary)
                        if didReset && !confirmingReset {
                            Text("settings.general.resetDone")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.signalGreen)
                        } else {
                            Text("settings.general.reset.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                    }

                    Spacer()

                    if confirmingReset {
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.smooth(duration: 0.20)) {
                                    confirmingReset = false
                                }
                            } label: {
                                Text("settings.general.resetCancel")
                            }
                            .buttonStyle(.lunulaSecondary)

                            Button {
                                withAnimation(.smooth(duration: 0.20)) {
                                    if let onResetDefaults {
                                        onResetDefaults()
                                    } else {
                                        settings.update {
                                            var d = IslandSettings.default
                                            d.hasCompletedOnboarding = true
                                            $0 = d
                                        }
                                    }
                                    confirmingReset = false
                                    didReset = true
                                }
                            } label: {
                                Text("settings.general.resetConfirm")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Palette.signalRed)
                                    .frame(height: 24)
                                    .padding(.horizontal, 10)
                                    .background(Palette.inkPressed)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Palette.signalRed.opacity(0.45), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            withAnimation(.smooth(duration: 0.20)) {
                                didReset = false
                                confirmingReset = true
                            }
                        } label: {
                            Text("settings.general.resetButton")
                        }
                        .buttonStyle(.lunulaSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }
        }
        .onAppear { launchAtLogin.refresh() }
    }

    // MARK: - Display Mode Card

    private func displayModeCard(
        titleKey: LocalizedStringKey,
        subtitleKey: LocalizedStringKey,
        mode: DisplayMode,
        illustration: AnyView
    ) -> some View {
        let isSelected = settings.settings.displayMode == mode

        return Button {
            withAnimation(.smooth(duration: 0.20)) {
                settings.update { $0.displayMode = mode }
                onDisplayModeChanged?(mode)
            }
        } label: {
            VStack(spacing: 6) {
                illustration
                    .frame(height: 56)

                Text(titleKey)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Palette.textPrimary)
                    .lineLimit(1)

                Text(subtitleKey)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Palette.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Palette.inkPressed : Palette.obsidian)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Palette.textSecondary : Palette.hairline, lineWidth: isSelected ? 1.0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Illustrations

    private var notchedOnlyIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Palette.inkPressed)
                .frame(width: 60, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                )

            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 2.5, bottomTrailingRadius: 2.5, topTrailingRadius: 0
            )
            .fill(Palette.obsidian)
            .frame(width: 16, height: 4)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 2.5, bottomTrailingRadius: 2.5, topTrailingRadius: 0
                )
                .stroke(Palette.amberGold.opacity(0.7), lineWidth: 0.75)
            )
            .offset(y: -17)

            RoundedRectangle(cornerRadius: 1)
                .fill(Palette.inkPressed)
                .frame(width: 76, height: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                )
                .offset(y: 20)
        }
    }

    private var allDisplaysIllustration: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkPressed)
                    .frame(width: 44, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                    )
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 0
                )
                .fill(Palette.obsidian)
                .frame(width: 10, height: 3)
                .offset(y: -12.5)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkPressed)
                    .frame(width: 54, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                    )

                Capsule()
                    .fill(Palette.textPrimary.opacity(0.85))
                    .frame(width: 16, height: 3.5)
                    .offset(y: -13.5)
            }
        }
    }

    private var mainDisplayIllustration: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkPressed)
                    .frame(width: 52, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Palette.textPrimary, lineWidth: 1)
                    )

                Rectangle()
                    .fill(Palette.textPrimary)
                    .frame(width: 48, height: 2)
                    .offset(y: -13)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkRaised)
                    .frame(width: 48, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.38), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
            }
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<IslandSettings, T>) -> Binding<T> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in settings.update { $0[keyPath: keyPath] = value } })
    }
}
