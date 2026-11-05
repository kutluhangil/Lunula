import IslandCore
import IslandDesign
import IslandServices
import KeyboardShortcuts
import SwiftUI

public struct GeneralSettingsView: View {
    let settings: SettingsStore
    let launchAtLogin: LaunchAtLoginService
    var onDisplayModeChanged: ((DisplayMode) -> Void)?
    @State private var loginError = false
    @State private var inputMonitoringState: PermissionState = .notRequested

    public init(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        onDisplayModeChanged: ((DisplayMode) -> Void)? = nil
    ) {
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.onDisplayModeChanged = onDisplayModeChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Sistem ve başlangıç
            VStack(alignment: .leading, spacing: 8) {
                Text("Sistem ve başlangıç")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    // Girişte başlat
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Girişte başlat")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Mac açıldığında Lunula sessizce başlar.")
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

                            Text("Etkinleştirmek için Sistem Ayarları › Giriş Öğeleri’nde Lunula’ya izin ver.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.amberGold)

                            Spacer()

                            Button("Giriş Öğeleri’ni Aç") {
                                launchAtLogin.openSystemSettings()
                            }
                            .buttonStyle(.lunulaSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }

                    Divider()
                        .background(Palette.hairline)

                    // Menü çubuğu simgesini göster
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Menü çubuğu simgesini göster")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Adadan ayrı, küçük bir menü çubuğu penceresi açar.")
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

            // MARK: - Ekranlar
            VStack(alignment: .leading, spacing: 8) {
                Text("Ekranlar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                HStack(spacing: 8) {
                    displayModeCard(
                        title: "Yalnızca çentikli ekranlar",
                        subtitle: "Harici ekranda ada yok",
                        mode: .notchedOnly,
                        illustration: AnyView(notchedOnlyIllustration)
                    )

                    displayModeCard(
                        title: "Tüm ekranlar",
                        subtitle: "Harici ekranda 180 × 22 kapsül",
                        mode: .allDisplays,
                        illustration: AnyView(allDisplaysIllustration)
                    )

                    displayModeCard(
                        title: "Yalnızca ana ekran",
                        subtitle: "Menü çubuğunun olduğu ekran",
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

            // MARK: - Tam ekran
            VStack(alignment: .leading, spacing: 8) {
                Text("Tam ekran")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tam ekranda gizle")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Oyun, film ve sunumda ada çekilir.")
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
                            Text("Tam ekranda önemli uyarılara izin ver")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Toplantı başlangıcı, biten zamanlayıcı, %10 pil ve ajan onayları.")
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

            // MARK: - Kısayollar
            VStack(alignment: .leading, spacing: 8) {
                Text("Kısayollar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Adayı aç/kapat")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Tıkla, yeni kısayola bas. Esc vazgeçer, ⌫ siler.")
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
                            Text("Çift Option (⌥) ile adayı aç/kapat")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Option’a hızla iki kez bas. Giriş İzleme izni ister.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.doubleTapOptionToToggle))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    if settings.settings.doubleTapOptionToToggle {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Palette.signalGreen)
                                .frame(width: 6, height: 6)
                            Text("Giriş İzleme · İzin verildi")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                    }
                }
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
        title: String,
        subtitle: String,
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

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Palette.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
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
            // Laptop screen
            RoundedRectangle(cornerRadius: 4)
                .fill(Palette.inkPressed)
                .frame(width: 60, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                )

            // Notch at top center
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

            // Laptop base
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
            // Laptop
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkPressed)
                    .frame(width: 44, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                    )
                // Notch
                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 0
                )
                .fill(Palette.obsidian)
                .frame(width: 10, height: 3)
                .offset(y: -12.5)
            }

            // External monitor
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkPressed)
                    .frame(width: 54, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.38), lineWidth: 0.75)
                    )

                // 180 × 22 pill at top
                Capsule()
                    .fill(Palette.textPrimary.opacity(0.85))
                    .frame(width: 16, height: 3.5)
                    .offset(y: -13.5)
            }
        }
    }

    private var mainDisplayIllustration: some View {
        HStack(spacing: 6) {
            // Main display with menu bar highlight
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.inkPressed)
                    .frame(width: 52, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Palette.textPrimary, lineWidth: 1)
                    )

                // Menu bar highlight line
                Rectangle()
                    .fill(Palette.textPrimary)
                    .frame(width: 48, height: 2)
                    .offset(y: -13)
            }

            // Secondary display dashed
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
