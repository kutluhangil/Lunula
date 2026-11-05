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
            // MARK: - Hâle ve ışık
            VStack(alignment: .leading, spacing: 8) {
                Text("Hâle ve ışık")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    // Hâle yoğunluğu
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hâle yoğunluğu")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Palette.textPrimary)
                                Text(
                                    "%100, durum tokenlarının kendisi (ortam 0.16 · aktif 0.32 · uyarı 0.55). %0 kapalı."
                                )
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            }
                            Spacer()
                            Text("%\(Int(round(settings.settings.haloIntensity * 100)))")
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

                    // İç kartlarda Liquid Glass yansıması
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("İç kartlarda Liquid Glass yansıması")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Ada çekirdeği #000000 kalır; yalnızca #111113 kartlar üstten ışık alır.")
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

                    // Menü çubuğunu siyah şeritle gizle
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Menü çubuğunu siyah şeritle gizle")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text(
                                "Çentikli ekranda menü şeridi siyaha döner; çentik kaybolur, hâle parlamaya devam eder."
                            )
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

                    // Kapsül dikey konumu
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kapsül dikey konumu")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Palette.textPrimary)
                                Text("Çentiksiz ekranlarda 180 × 22 kapsülün üst kenara uzaklığı.")
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
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Zamanlayıcı maskotu
            VStack(alignment: .leading, spacing: 8) {
                Text("Zamanlayıcı maskotu")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                HStack(spacing: 8) {
                    mascotCard(title: "Varsayılan", symbol: "timer", mascot: .none)
                    mascotCard(title: "Tavşan", symbol: "hare.fill", mascot: .hare)
                    mascotCard(title: "Kaplumbağa", symbol: "tortoise.fill", mascot: .tortoise)
                    mascotCard(title: "Kedi", symbol: "cat.fill", mascot: .cat)
                    mascotCard(title: "Kuş", symbol: "bird.fill", mascot: .bird)
                    mascotCard(title: "Alev", symbol: "flame.fill", mascot: .flame)
                }
                .padding(12)
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }

            // MARK: - Geri bildirim
            VStack(alignment: .leading, spacing: 8) {
                Text("Geri bildirim")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dokunsal geri bildirim")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Trackpad’de hafif tık: açılışta ve uyarılarda.")
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
                            Text("Sesler")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                            Text("Zamanlayıcı bitişi ve uyarılar.")
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

    private func mascotCard(title: String, symbol: String, mascot: TimerMascot) -> some View {
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

                Text(title)
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
