import IslandCore
import IslandDesign
import SwiftUI

public struct AppearanceSettingsView: View {
    let settings: SettingsStore
    var onHaloChanged: ((Double) -> Void)?
    var onPillOffsetChanged: ((Double) -> Void)?
    var onGlassChanged: ((Bool) -> Void)?
    var onBarChanged: ((Bool) -> Void)?
    var onMascotChanged: ((TimerMascot) -> Void)?

    public init(
        settings: SettingsStore,
        onHaloChanged: ((Double) -> Void)? = nil,
        onPillOffsetChanged: ((Double) -> Void)? = nil,
        onGlassChanged: ((Bool) -> Void)? = nil,
        onBarChanged: ((Bool) -> Void)? = nil,
        onMascotChanged: ((TimerMascot) -> Void)? = nil
    ) {
        self.settings = settings
        self.onHaloChanged = onHaloChanged
        self.onPillOffsetChanged = onPillOffsetChanged
        self.onGlassChanged = onGlassChanged
        self.onBarChanged = onBarChanged
        self.onMascotChanged = onMascotChanged
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Halo & light
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.appearance.section.halo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.appearance.halo")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Palette.textPrimary)
                                Text("settings.appearance.halo.subtitle")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Palette.textSecondary)
                            }
                            Spacer()
                            Text(settings.settings.haloIntensity, format: .percent.precision(.fractionLength(0)))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(Palette.textPrimary)
                        }

                        LunulaHaloSlider(
                            value: Binding(
                                get: { settings.settings.haloIntensity },
                                set: { v in
                                    settings.update { $0.haloIntensity = v }
                                    onHaloChanged?(v)
                                }
                            )
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider().background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.appearance.useGlassCards")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.appearance.useGlassCards.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { settings.settings.useGlassCards },
                                set: { v in
                                    settings.update { $0.useGlassCards = v }
                                    onGlassChanged?(v)
                                }
                            )
                        )
                        .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    Divider().background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.appearance.hideNotchBar")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.appearance.hideNotchBar.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { settings.settings.hideNotchBar },
                                set: { v in
                                    settings.update { $0.hideNotchBar = v }
                                    onBarChanged?(v)
                                }
                            )
                        )
                        .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    Divider().background(Palette.hairline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.appearance.pillOffset")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Palette.textPrimary)
                                Text("settings.appearance.pillOffset.subtitle")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Palette.textSecondary)
                            }
                            Spacer()
                            Text("\(Int(settings.settings.pillVerticalOffset)) pt")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(Palette.textPrimary)
                        }

                        LunulaTickedSlider(
                            value: Binding(
                                get: { settings.settings.pillVerticalOffset },
                                set: { v in
                                    settings.update { $0.pillVerticalOffset = v }
                                    onPillOffsetChanged?(v)
                                }
                            )
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider().background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.appearance.expandedWidth")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.appearance.expandedWidth.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        LunulaSegmentPicker(
                            selection: Binding(
                                get: { Int(settings.settings.expandedWidth.rounded()) },
                                set: { v in settings.update { $0.expandedWidth = Double(v) } }
                            ),
                            items: [
                                (value: 520, label: "520 pt"),
                                (value: 560, label: "560 pt"),
                                (value: 600, label: "600 pt"),
                            ]
                        )
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

            // MARK: - Timer mascot
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.appearance.timerMascot")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                HStack(spacing: 8) {
                    mascotCard(titleKey: "settings.appearance.mascot.default", symbol: "timer", mascot: .none)
                    mascotCard(titleKey: "settings.appearance.mascot.hare", symbol: "hare.fill", mascot: .hare)
                    mascotCard(
                        titleKey: "settings.appearance.mascot.tortoise", symbol: "tortoise.fill", mascot: .tortoise)
                    mascotCard(titleKey: "settings.appearance.mascot.cat", symbol: "cat.fill", mascot: .cat)
                    mascotCard(titleKey: "settings.appearance.mascot.bird", symbol: "bird.fill", mascot: .bird)
                    mascotCard(titleKey: "settings.appearance.mascot.flame", symbol: "flame.fill", mascot: .flame)
                }
                .padding(12)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Feedback
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.appearance.section.feedback")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.appearance.haptics")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.appearance.haptics.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.hapticsEnabled))
                            .toggleStyle(.lunulaSwitch)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                    Divider().background(Palette.hairline)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.appearance.sounds")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("settings.appearance.sounds.subtitle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(\.soundsEnabled))
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
        }
    }

    // MARK: - Mascot Card

    private func mascotCard(titleKey: LocalizedStringKey, symbol: String, mascot: TimerMascot) -> some View {
        let isSelected = settings.settings.timerMascot == mascot

        return Button {
            withAnimation(.smooth(duration: 0.20)) {
                settings.update { $0.timerMascot = mascot }
                onMascotChanged?(mascot)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? Palette.amberGold : Palette.textSecondary)
                    .frame(height: 24)

                Text(titleKey)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Palette.amberGold : Palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(isSelected ? Palette.inkPressed : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Palette.amberGold : Palette.hairline, lineWidth: isSelected ? 1.0 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func binding<T>(_ keyPath: WritableKeyPath<IslandSettings, T>) -> Binding<T> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in settings.update { $0[keyPath: keyPath] = value } })
    }
}
