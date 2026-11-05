import IslandCore
import IslandDesign
import SwiftUI

public struct ActivitiesSettingsView: View {
    public static let features: [IslandFeature] = Array(IslandFeature.allCases)

    let settings: SettingsStore
    let permission: @MainActor (IslandFeature) -> PermissionState?
    let request: @MainActor (IslandFeature) -> Void

    public init(
        settings: SettingsStore,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState?,
        request: @escaping @MainActor (IslandFeature) -> Void
    ) {
        self.settings = settings
        self.permission = permission
        self.request = request
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                "Lunula ilk açılışta hiçbir izin istemez. İzin, yalnızca o etkinliği açtığında ve gerçekten gerekiyorsa istenir."
            )
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Palette.textSecondary)
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // 1. Şimdi Çalıyor
                activityRow(
                    feature: .nowPlaying,
                    title: "Şimdi Çalıyor",
                    description: "Apple Music ve Spotify; kapak renginde hâle.",
                    symbol: "music.note",
                    permissionState: permission(.nowPlaying) ?? .granted,
                    permissionName: "Otomasyon"
                )

                Divider().background(Palette.hairline)

                // 2. Zamanlayıcı
                activityRow(
                    feature: .timer,
                    title: "Zamanlayıcı",
                    description: "Pomodoro, kronometre ve 7 günlük odak serisi.",
                    symbol: "timer",
                    permissionState: .unavailable,
                    permissionName: nil
                )

                Divider().background(Palette.hairline)

                // 3. Takvim
                activityRow(
                    feature: .calendar,
                    title: "Takvim",
                    description: "Yaklaşan toplantı; Zoom, Meet ve Teams’e tek tıkla katıl.",
                    symbol: "calendar",
                    permissionState: permission(.calendar) ?? .notRequested,
                    permissionName: "Takvim"
                )

                Divider().background(Palette.hairline)

                // 4. Hava
                activityRow(
                    feature: .weather,
                    title: "Hava",
                    description: "Bulunduğun yerin anlık havası ve günün en yüksek–en düşüğü.",
                    symbol: "cloud.sun.fill",
                    permissionState: permission(.weather) ?? .denied,
                    permissionName: "Konum"
                ) {
                    HStack(spacing: 12) {
                        Text("Sıcaklık birimi")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Palette.textSecondary)

                        Spacer()

                        LunulaSegmentPicker(
                            selection: valueBinding(\.temperatureUnit),
                            items: [
                                (value: .system, label: "Sistem"),
                                (value: .celsius, label: "°C"),
                                (value: .fahrenheit, label: "°F"),
                            ]
                        )
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                // 5. Raf
                activityRow(
                    feature: .shelf,
                    title: "Raf",
                    description: "Sürükle-bırak raf, görsel dönüştürme, ZIP aç/sıkıştır, metin tanıma.",
                    symbol: "tray.fill",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Text("Dosyaları rafa kopyala")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            Toggle("", isOn: valueBinding(\.shelfCopiesFiles))
                                .toggleStyle(.lunulaSwitch)
                        }

                        HStack(spacing: 12) {
                            Text("Öğeleri temizle")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            LunulaSegmentPicker(
                                selection: valueBinding(\.shelfRetentionDays),
                                items: [
                                    (value: Optional(1), label: "1 gün"),
                                    (value: Optional(7), label: "7 gün"),
                                    (value: Optional(30), label: "30 gün"),
                                    (value: nil, label: "Asla"),
                                ]
                            )
                        }
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                // 6. Pil uyarıları
                activityRow(
                    feature: .battery,
                    title: "Pil uyarıları",
                    description: "Şarj hâlesi, düşük pil ve tam şarj uyarısı.",
                    symbol: "battery.100.bolt",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    HStack(spacing: 12) {
                        Text("Tam şarj uyarı eşiği")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Palette.textSecondary)

                        Spacer()

                        LunulaSegmentPicker(
                            selection: valueBinding(\.fullChargeThreshold),
                            items: [
                                (value: 80, label: "%80"),
                                (value: 85, label: "%85"),
                                (value: 90, label: "%90"),
                                (value: 95, label: "%95"),
                                (value: 100, label: "%100"),
                            ]
                        )
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                // 7. İndirme uyarıları
                activityRow(
                    feature: .downloads,
                    title: "İndirme uyarıları",
                    description: "Biten indirmeyi adada göster, rafa ekle.",
                    symbol: "arrow.down.circle.fill",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    Text("Lunula, İndirmeler klasörünü yalnızca biten indirmeler için izler.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Palette.textSecondary)
                        .padding(.leading, 52)
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                }

                Divider().background(Palette.hairline)

                // 8. Kamera ve mikrofon göstergesi
                activityRow(
                    feature: .privacyIndicator,
                    title: "Kamera ve mikrofon göstergesi",
                    description: "Gizlilik noktaları ve canlı çağrı adası.",
                    symbol: "camera.fill",
                    permissionState: .unavailable,
                    permissionName: nil
                )

                Divider().background(Palette.hairline)

                // 9. Özel etkinlikler
                activityRow(
                    feature: .customActivities,
                    title: "Özel etkinlikler (URL ve Kestirmeler)",
                    description: "lunula:// adresleri, disk çıkarma, Caps Lock, ajan onayları.",
                    symbol: "sparkles",
                    permissionState: .unavailable,
                    permissionName: nil
                )
            }
            .background(Palette.inkRaised)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Palette.hairline, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Activity Row Helper

    private func activityRow<Content: View>(
        feature: IslandFeature,
        title: String,
        description: String,
        symbol: String,
        permissionState: PermissionState,
        permissionName: String?,
        @ViewBuilder subContent: () -> Content = { EmptyView() }
    ) -> some View {
        let isEnabled = isOn(feature)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // 28 × 28 icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Palette.inkPressed)

                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isEnabled ? Palette.textPrimary : Palette.textTertiary)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Palette.textPrimary)

                    Text(description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Palette.textSecondary)

                    PermissionRow(
                        name: permissionName,
                        state: permissionState,
                        onRequest: { request(feature) },
                        onOpenSettings: {
                            NSWorkspace.shared.open(Self.settingsURL(feature))
                        }
                    )
                    .padding(.top, 4)
                }

                Spacer()

                Toggle("", isOn: featureBinding(feature))
                    .toggleStyle(.lunulaSwitch)
                    .offset(y: 4)
            }
            .padding(12)

            if isEnabled {
                subContent()
            }
        }
    }

    private func isOn(_ feature: IslandFeature) -> Bool {
        settings.settings.enabledFeatures.contains(feature)
            && (feature != .downloads || settings.settings.downloadsAlertsOptedIn)
    }

    private func featureBinding(_ feature: IslandFeature) -> Binding<Bool> {
        Binding(
            get: { isOn(feature) },
            set: { on in
                settings.update {
                    if on { $0.enabledFeatures.insert(feature) } else { $0.enabledFeatures.remove(feature) }
                    if feature == .downloads { $0.downloadsAlertsOptedIn = on }
                }
            }
        )
    }

    private func valueBinding<T>(_ keyPath: WritableKeyPath<IslandSettings, T>) -> Binding<T> {
        Binding(
            get: { settings.settings[keyPath: keyPath] },
            set: { value in settings.update { $0[keyPath: keyPath] = value } }
        )
    }

    public static func settingsURL(_ feature: IslandFeature) -> URL {
        switch feature {
        case .calendar: PermissionRow.settingsURL("Privacy_Calendars")
        case .weather: PermissionRow.settingsURL("Privacy_LocationServices")
        default: PermissionRow.settingsURL("Privacy_Automation")
        }
    }
}
