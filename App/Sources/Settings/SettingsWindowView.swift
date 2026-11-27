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
    let hasAIKey: @MainActor (QuickAIProvider) -> Bool
    let saveAIKey: @MainActor (String, QuickAIProvider) -> Void
    let clearAIKey: @MainActor (QuickAIProvider) -> Void
    let extraPermission: @MainActor (ExtraPermissionKind) -> PermissionState
    let requestExtraPermission: @MainActor (ExtraPermissionKind) -> Void
    let ollamaModels: @MainActor () -> [String]
    let refreshOllamaModels: @MainActor (String) async -> [String]
    let testAIConnection: @MainActor (QuickAIConfig) async -> (ok: Bool, message: String)
    let resetDefaults: (@MainActor () -> Void)?

    @State private var selectedTab: SettingsTabID = .general
    @State private var previewFocusOverride: SettingsPreviewFocus?
    @Namespace private var tabAnimation

    public init(
        settings: SettingsStore,
        launchAtLogin: LaunchAtLoginService,
        permission: @escaping @MainActor (IslandFeature) -> PermissionState? = { _ in nil },
        request: @escaping @MainActor (IslandFeature) -> Void = { _ in },
        searchWeatherCity: @escaping @MainActor (String) async -> [GeoPlace] = { _ in [] },
        hasAIKey: @escaping @MainActor (QuickAIProvider) -> Bool = { _ in false },
        saveAIKey: @escaping @MainActor (String, QuickAIProvider) -> Void = { _, _ in },
        clearAIKey: @escaping @MainActor (QuickAIProvider) -> Void = { _ in },
        extraPermission: @escaping @MainActor (ExtraPermissionKind) -> PermissionState = { _ in .notRequested },
        requestExtraPermission: @escaping @MainActor (ExtraPermissionKind) -> Void = { _ in },
        ollamaModels: @escaping @MainActor () -> [String] = { [] },
        refreshOllamaModels: @escaping @MainActor (String) async -> [String] = { _ in [] },
        testAIConnection: @escaping @MainActor (QuickAIConfig) async -> (ok: Bool, message: String) = { _ in
            (false, "")
        },
        resetDefaults: (@MainActor () -> Void)? = nil,
        initialTab: SettingsTabID = .general
    ) {
        self.settings = settings
        self.launchAtLogin = launchAtLogin
        self.permission = permission
        self.request = request
        self.searchWeatherCity = searchWeatherCity
        self.hasAIKey = hasAIKey
        self.saveAIKey = saveAIKey
        self.clearAIKey = clearAIKey
        self.extraPermission = extraPermission
        self.requestExtraPermission = requestExtraPermission
        self.ollamaModels = ollamaModels
        self.refreshOllamaModels = refreshOllamaModels
        self.testAIConnection = testAIConnection
        self.resetDefaults = resetDefaults
        self._selectedTab = State(initialValue: initialTab)
    }

    private var stageLabel: String {
        if let override = previewFocusOverride {
            switch override {
            case .style:
                return String(localized: "settings.preview.stage.style")
            case .glass:
                return String(localized: "settings.preview.stage.liquidGlass")
            case .pill:
                return String(localized: "settings.appearance.pillOffset")
            case .bar:
                return String(
                    localized: settings.settings.hideNotchBar
                        ? "settings.preview.stage.blackBar" : "settings.preview.stage.notched")
            case .timer:
                return String(
                    localized: settings.settings.timerMascot != .none
                        ? "settings.preview.stage.mascot" : "settings.preview.stage.halo")
            }
        }

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
                focus: previewFocusOverride ?? stageFocus,
                haloIntensity: settings.settings.haloIntensity,
                mascot: settings.settings.timerMascot,
                hideNotchBar: settings.settings.hideNotchBar,
                useGlassCards: settings.settings.useGlassCards,
                pillVerticalOffset: settings.settings.pillVerticalOffset,
                visualStyle: settings.settings.visualStyle,
                surfaceMaterial: settings.settings.surfaceMaterial,
                expandedWidth: settings.settings.expandedWidth,
                waterDropletEffect: settings.settings.waterDropletEffect,
                dropletSensitivity: settings.settings.dropletSensitivity
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            // MARK: - Unified 5-Tab Segmented Pill (36 pt)
            HStack(spacing: 4) {
                ForEach(SettingsTabID.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            previewFocusOverride = nil
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
            ScrollView(.vertical, showsIndicators: true) {
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(
                            settings: settings,
                            launchAtLogin: launchAtLogin,
                            onResetDefaults: resetDefaults.map { action in
                                { MainActor.assumeIsolated { action() } }
                            }
                        )
                    case .appearance:
                        AppearanceSettingsView(
                            settings: settings,
                            onHaloChanged: { _ in previewFocusOverride = .timer },
                            onPillOffsetChanged: { _ in previewFocusOverride = .pill },
                            onGlassChanged: { _ in previewFocusOverride = .glass },
                            onBarChanged: { _ in previewFocusOverride = .bar },
                            onMascotChanged: { _ in previewFocusOverride = .timer },
                            onStyleChanged: { previewFocusOverride = .style }
                        )
                    case .activities:
                        ActivitiesSettingsView(
                            settings: settings,
                            permission: permission,
                            request: request,
                            searchWeatherCity: searchWeatherCity,
                            extraPermission: extraPermission,
                            requestExtraPermission: requestExtraPermission
                        )
                    case .tools:
                        ToolsSettingsView(
                            settings: settings,
                            onSelectTab: { tab in
                                withAnimation(.easeInOut(duration: 0.20)) {
                                    previewFocusOverride = nil
                                    selectedTab = tab
                                }
                            },
                            hasAIKey: hasAIKey,
                            saveAIKey: saveAIKey,
                            clearAIKey: clearAIKey,
                            ollamaModels: ollamaModels,
                            refreshOllamaModels: refreshOllamaModels,
                            testAIConnection: testAIConnection
                        )
                    case .about:
                        AboutSettingsView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Palette.basalt],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 16)
                .allowsHitTesting(false)
            }
        }
        .frame(width: 680, height: 540)
        .background(Palette.basalt)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 0.5)
        )
        .environment(\.colorScheme, .dark)
        .onChange(of: selectedTab) { _, _ in
            previewFocusOverride = nil
        }
    }
}
