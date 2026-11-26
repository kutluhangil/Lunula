import IslandCore
import IslandDesign
import SwiftUI

public struct ActivitiesSettingsView: View {
    public static let features: [IslandFeature] = Array(IslandFeature.allCases)

    private enum LocationMode: Hashable {
        case automatic, manual
    }

    let settings: SettingsStore
    let permission: @MainActor (IslandFeature) -> PermissionState?
    let request: @MainActor (IslandFeature) -> Void
    let searchWeatherCity: @MainActor (String) async -> [GeoPlace]

    @State private var locationMode: LocationMode = .automatic
    @State private var cityQuery = ""
    @State private var cityResults: [GeoPlace] = []
    @State private var isSearchingCity = false
    @State private var hasSearchedCity = false

    public init(
        settings: SettingsStore,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState?,
        request: @escaping @MainActor (IslandFeature) -> Void,
        searchWeatherCity: @escaping @MainActor (String) async -> [GeoPlace] = { _ in [] }
    ) {
        self.settings = settings
        self.permission = permission
        self.request = request
        self.searchWeatherCity = searchWeatherCity
        if case .city(let name, _, _) = settings.settings.weatherLocation {
            _locationMode = State(initialValue: .manual)
            _cityQuery = State(initialValue: name)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.activities.intro")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Palette.textSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                activityRow(
                    feature: .nowPlaying,
                    titleKey: "settings.feature.nowPlaying",
                    descriptionKey: "settings.feature.nowPlaying.desc",
                    symbol: "music.note",
                    permissionState: permission(.nowPlaying) ?? .unavailable,
                    permissionName: String(localized: "settings.permission.automation")
                )

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .timer,
                    titleKey: "settings.feature.timer",
                    descriptionKey: "settings.feature.timer.desc",
                    symbol: "timer",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Text("settings.timer.pomodoroFocus")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            LunulaSegmentPicker(
                                selection: Binding(
                                    get: { Int(settings.settings.pomodoroPlan.focus / 60) },
                                    set: { m in settings.update { $0.pomodoroPlan.focus = TimeInterval(m * 60) } }
                                ),
                                items: [15, 25, 30, 45, 50].map {
                                    (value: $0, label: String(localized: "settings.timer.minutesShort \($0)"))
                                }
                            )
                        }
                        HStack(spacing: 12) {
                            Text("settings.timer.pomodoroShortBreak")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            LunulaSegmentPicker(
                                selection: Binding(
                                    get: { Int(settings.settings.pomodoroPlan.shortBreak / 60) },
                                    set: { m in settings.update { $0.pomodoroPlan.shortBreak = TimeInterval(m * 60) } }
                                ),
                                items: [5, 10, 15].map {
                                    (value: $0, label: String(localized: "settings.timer.minutesShort \($0)"))
                                }
                            )
                        }
                        HStack(spacing: 12) {
                            Text("settings.timer.pomodoroLongBreak")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            LunulaSegmentPicker(
                                selection: Binding(
                                    get: { Int(settings.settings.pomodoroPlan.longBreak / 60) },
                                    set: { m in settings.update { $0.pomodoroPlan.longBreak = TimeInterval(m * 60) } }
                                ),
                                items: [15, 20, 30].map {
                                    (value: $0, label: String(localized: "settings.timer.minutesShort \($0)"))
                                }
                            )
                        }
                        HStack(spacing: 12) {
                            Text("settings.timer.pomodoroCycles")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            LunulaSegmentPicker(
                                selection: Binding(
                                    get: { settings.settings.pomodoroPlan.focusSessionsBeforeLongBreak },
                                    set: { c in settings.update { $0.pomodoroPlan.focusSessionsBeforeLongBreak = c } }
                                ),
                                items: [2, 3, 4, 6].map { (value: $0, label: "\($0)×") }
                            )
                        }
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .calendar,
                    titleKey: "settings.feature.calendar",
                    descriptionKey: "settings.feature.calendar.desc",
                    symbol: "calendar",
                    permissionState: permission(.calendar) ?? .notRequested,
                    permissionName: String(localized: "settings.permission.calendar")
                )

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .weather,
                    titleKey: "settings.feature.weather",
                    descriptionKey: "settings.feature.weather.desc",
                    symbol: "cloud.sun.fill",
                    permissionState: permission(.weather) ?? .notRequested,
                    permissionName: String(localized: "settings.permission.location")
                ) {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Text("settings.weather.unit")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)

                            Spacer()

                            LunulaSegmentPicker(
                                selection: valueBinding(\.temperatureUnit),
                                items: [
                                    (value: .system, label: String(localized: "settings.weather.unit.system")),
                                    (value: .celsius, label: "°C"),
                                    (value: .fahrenheit, label: "°F"),
                                ]
                            )
                        }

                        HStack(spacing: 12) {
                            Text("settings.weather.location")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)

                            Spacer()

                            LunulaSegmentPicker(
                                selection: Binding(
                                    get: { locationMode },
                                    set: { mode in
                                        locationMode = mode
                                        if mode == .automatic {
                                            settings.update { $0.weatherLocation = .automatic }
                                            cityResults = []
                                            hasSearchedCity = false
                                        }
                                    }
                                ),
                                items: [
                                    (
                                        value: LocationMode.automatic,
                                        label: String(localized: "settings.weather.location.automatic")
                                    ),
                                    (
                                        value: LocationMode.manual,
                                        label: String(localized: "settings.weather.location.manual")
                                    ),
                                ]
                            )
                        }

                        if locationMode == .manual {
                            weatherCityPicker
                        }
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .shelf,
                    titleKey: "settings.feature.shelf",
                    descriptionKey: "settings.feature.shelf.desc",
                    symbol: "tray.fill",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Text("settings.shelf.copies")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            Toggle("", isOn: valueBinding(\.shelfCopiesFiles))
                                .toggleStyle(.lunulaSwitch)
                        }

                        HStack(spacing: 12) {
                            Text("settings.shelf.retention")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            LunulaSegmentPicker(
                                selection: valueBinding(\.shelfRetentionDays),
                                items: [
                                    (value: Optional(1), label: String(localized: "settings.shelf.retention.1")),
                                    (value: Optional(7), label: String(localized: "settings.shelf.retention.7")),
                                    (value: Optional(30), label: String(localized: "settings.shelf.retention.30")),
                                    (value: nil, label: String(localized: "settings.shelf.retention.never")),
                                ]
                            )
                        }
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .battery,
                    titleKey: "settings.feature.battery",
                    descriptionKey: "settings.feature.battery.desc",
                    symbol: "battery.100.bolt",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            Text("settings.appearance.fullChargeThreshold")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)

                            Spacer()

                            LunulaSegmentPicker(
                                selection: valueBinding(\.fullChargeThreshold),
                                items: [
                                    (value: 80, label: "80%"),
                                    (value: 85, label: "85%"),
                                    (value: 90, label: "90%"),
                                    (value: 95, label: "95%"),
                                    (value: 100, label: "100%"),
                                ]
                            )
                        }

                        HStack(spacing: 12) {
                            Text("settings.battery.bluetoothAlerts")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                            Spacer()
                            Toggle("", isOn: valueBinding(\.bluetoothAlertsEnabled))
                                .toggleStyle(.lunulaSwitch)
                        }
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                }

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .downloads,
                    titleKey: "settings.feature.downloads",
                    descriptionKey: "settings.feature.downloads.desc",
                    symbol: "arrow.down.circle.fill",
                    permissionState: .unavailable,
                    permissionName: nil
                ) {
                    Text("settings.activities.downloadsNote")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Palette.textSecondary)
                        .padding(.leading, 52)
                        .padding(.trailing, 12)
                        .padding(.bottom, 10)
                }

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .privacyIndicator,
                    titleKey: "settings.feature.privacyIndicator",
                    descriptionKey: "settings.feature.privacyIndicator.desc",
                    symbol: "camera.fill",
                    permissionState: .unavailable,
                    permissionName: nil
                )

                Divider().background(Palette.hairline)

                activityRow(
                    feature: .customActivities,
                    titleKey: "settings.feature.customActivities",
                    descriptionKey: "settings.feature.customActivities.desc",
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

    // MARK: - Weather City Picker

    private var weatherCityPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TextField(String(localized: "settings.weather.city.placeholder"), text: $cityQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Palette.obsidian)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Palette.hairline, lineWidth: 0.5)
                    )
                    .onSubmit(performCitySearch)

                Button(action: performCitySearch) {
                    if isSearchingCity {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 16, height: 16)
                    } else {
                        Text("settings.weather.city.search")
                    }
                }
                .buttonStyle(.lunulaSecondary)
                .disabled(cityQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearchingCity)
            }

            if !cityResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(cityResults.prefix(4).enumerated()), id: \.offset) { idx, place in
                        if idx > 0 { Divider().background(Palette.hairline) }
                        Button {
                            settings.update {
                                $0.weatherLocation = .city(
                                    name: place.name, latitude: place.latitude, longitude: place.longitude)
                            }
                            cityQuery = place.name
                            cityResults = []
                            hasSearchedCity = false
                        } label: {
                            HStack {
                                Text([place.name, place.country].compactMap { $0 }.joined(separator: ", "))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Palette.textPrimary)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Palette.textSecondary)
                                    .opacity(isSelectedCity(place) ? 1 : 0)
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Palette.obsidian)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            } else if hasSearchedCity && !isSearchingCity {
                Text("settings.weather.city.noResults")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Palette.textSecondary)
            }
        }
    }

    private func isSelectedCity(_ place: GeoPlace) -> Bool {
        if case .city(let name, let lat, let lon) = settings.settings.weatherLocation {
            return name == place.name && abs(lat - place.latitude) < 0.01 && abs(lon - place.longitude) < 0.01
        }
        return false
    }

    private func performCitySearch() {
        let trimmed = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearchingCity = true
        hasSearchedCity = false
        Task { @MainActor in
            let results = await searchWeatherCity(trimmed)
            cityResults = results
            isSearchingCity = false
            hasSearchedCity = true
        }
    }

    // MARK: - Activity Row Helper

    private func activityRow<Content: View>(
        feature: IslandFeature,
        titleKey: LocalizedStringKey,
        descriptionKey: LocalizedStringKey,
        symbol: String,
        permissionState: PermissionState,
        permissionName: String?,
        @ViewBuilder subContent: () -> Content = { EmptyView() }
    ) -> some View {
        let isEnabled = isOn(feature)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Palette.inkPressed)

                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isEnabled ? Palette.textPrimary : Palette.textTertiary)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(titleKey)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Palette.textPrimary)

                    Text(descriptionKey)
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
