import AppKit
import IslandCore
import IslandDesign
import IslandServices
import SwiftUI

/// Main unified container view for Lunula Settings.
/// Strict 680 × 540 pt dimensions, 16 pt continuous corner radius, 32 pt custom title bar,
/// 656 × 88 pt live interactive stage preview, 36 pt tab pill, and scrollable content.
public struct SettingsWindowView: View {
    let settings: SettingsStore
    let launchAtLogin: LaunchAtLoginService
    let permission: @MainActor (IslandFeature) -> PermissionState?
    let request: @MainActor (IslandFeature) -> Void
    let searchWeatherCity: @MainActor (String) async -> [GeoPlace]

    @State private var selectedTab: SettingsTabID = .general
    @Namespace private var tabAnimation

    public init(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState? = { _ in nil },
        request: @escaping @MainActor (IslandFeature) -> Void = { _ in },
        searchWeatherCity: @escaping @MainActor (String) async -> [GeoPlace] = { _ in [] },
        initialTab: SettingsTabID = .general
    ) {
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.permission = permission
        self.request = request
        self.searchWeatherCity = searchWeatherCity
        self._selectedTab = State(initialValue: initialTab)
    }

    private var stageLabel: String {
        switch selectedTab {
        case .general:
            return String(
                localized: settings.settings.hideNotchBar
                    ? "settings.preview.stage.blackBar" : "settings.preview.stage.notched")
        case .appearance:
            if settings.settings.useGlassCards {
                return String(localized: "settings.preview.stage.liquidGlass")
            } else if settings.settings.timerMascot != .none {
                return String(localized: "settings.preview.stage.mascot")
            } else {
                return String(localized: "settings.preview.stage.halo")
            }
        case .activities:
            return String(localized: "settings.preview.stage.downloads")
        case .tools:
            return String(localized: "settings.preview.stage.tools")
        case .about:
            return String(localized: "settings.preview.stage.live")
        }
    }

    private var stageFocus: SettingsPreviewFocus {
        switch selectedTab {
        case .general:
            return settings.settings.hideNotchBar ? .bar : .timer
        case .appearance:
            if settings.settings.useGlassCards {
                return .glass
            } else if settings.settings.pillVerticalOffset > 0 {
                return .pill
            } else {
                return .timer
            }
        case .activities:
            return .glass
        case .tools:
            return .timer
        case .about:
            return .timer
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Titlebar (32 pt)
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: 72, height: 32)

                Spacer(minLength: 0)

                Text("settings.window.title")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)

                Spacer(minLength: 0)

                Text(String(localized: "settings.preview.prefix \(stageLabel)"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: 180, alignment: .trailing)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)

            // MARK: - Live Interactive Preview Stage (656 × 88 pt)
            SettingsStagePreview(
                focus: stageFocus,
                haloIntensity: settings.settings.haloIntensity,
                mascot: settings.settings.timerMascot,
                hideNotchBar: settings.settings.hideNotchBar,
                useGlassCards: settings.settings.useGlassCards,
                pillVerticalOffset: settings.settings.pillVerticalOffset
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            // MARK: - Unified 5-Tab Segmented Pill (36 pt)
            HStack(spacing: 4) {
                ForEach(SettingsTabID.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 12, weight: .medium))
                            Text(tab.titleKey)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.inkPressed)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.24), lineWidth: 0.5)
                                    )
                                    .matchedGeometryEffect(id: "selectedTabBackground", in: tabAnimation)
                            }
                        }
                        .foregroundStyle(isSelected ? Palette.textPrimary : Palette.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .frame(height: 36)
            .background(Color.black)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Palette.hairline, lineWidth: 0.5)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            // MARK: - Tab Content Scroll Container (372 pt)
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(settings: settings, launchAtLogin: launchAtLogin)
                    case .appearance:
                        AppearanceSettingsView(settings: settings)
                    case .activities:
                        ActivitiesSettingsView(
                            settings: settings, permission: permission, request: request,
                            searchWeatherCity: searchWeatherCity)
                    case .tools:
                        ToolsSettingsView(
                            settings: settings,
                            onSelectTab: { tab in
                                withAnimation(.easeInOut(duration: 0.20)) {
                                    selectedTab = tab
                                }
                            })
                    case .about:
                        AboutSettingsView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 680, height: 540)
        .background(Palette.basalt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 0.5)
        )
        .environment(\.colorScheme, .dark)
    }
}
