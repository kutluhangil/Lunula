import IslandCore
import IslandDesign
import SwiftUI

public enum SettingsPreviewFocus: Equatable, Sendable {
    case timer
    case glass
    case pill
    case bar
    case style
}

/// The live 656 × 88 pt stage at the top of the Settings window that interactively reacts to user settings.
public struct SettingsStagePreview: View {
    private static let stageSize = CGSize(width: 656, height: 88)
    private static let previewNotchSize = CGSize(width: 120, height: 26)
    private static let boringTint = RGBAColor(red: 0.92, green: 0.32, blue: 0.62)
    private static let equalizerHeights: [CGFloat] = [8, 16, 11, 18, 10]

    let focus: SettingsPreviewFocus
    let haloIntensity: Double
    let mascot: TimerMascot
    let hideNotchBar: Bool
    let useGlassCards: Bool
    let pillVerticalOffset: Double
    let visualStyle: IslandVisualStyle
    let surfaceMaterial: IslandSurfaceMaterial
    let expandedWidth: Double
    let waterDropletEffect: Bool
    let dropletSensitivity: DropletSensitivity

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoverPoint: CGPoint?

    private var increaseContrast: Bool { colorSchemeContrast == .increased }

    public init(
        focus: SettingsPreviewFocus = .timer,
        haloIntensity: Double = 1.0,
        mascot: TimerMascot = .none,
        hideNotchBar: Bool = false,
        useGlassCards: Bool = false,
        pillVerticalOffset: Double = 0,
        visualStyle: IslandVisualStyle = .lunula,
        surfaceMaterial: IslandSurfaceMaterial = .obsidian,
        expandedWidth: Double = 520,
        waterDropletEffect: Bool = true,
        dropletSensitivity: DropletSensitivity = .balanced
    ) {
        self.focus = focus
        self.haloIntensity = haloIntensity
        self.mascot = mascot
        self.hideNotchBar = hideNotchBar
        self.useGlassCards = useGlassCards
        self.pillVerticalOffset = pillVerticalOffset
        self.visualStyle = visualStyle
        self.surfaceMaterial = surfaceMaterial
        self.expandedWidth = expandedWidth
        self.waterDropletEffect = waterDropletEffect
        self.dropletSensitivity = dropletSensitivity
    }

    private var glowOpacity: Double {
        visualStyle == .alcove ? 0 : 0.32 * max(0, min(1, haloIntensity))
    }

    private var rimOpacity: Double {
        guard visualStyle != .alcove, haloIntensity > 0 else { return 0 }
        return increaseContrast ? 0.60 : 0.35
    }

    private var rimWidth: CGFloat {
        increaseContrast ? 1.5 : 1.0
    }

    private var activeHaloColor: Color {
        switch visualStyle {
        case .lunula, .alcove:
            Palette.amberGold
        case .boring:
            Palette.color(Self.boringTint)
        }
    }

    private var mascotSymbol: String {
        switch mascot {
        case .none: "timer"
        case .hare: "hare.fill"
        case .tortoise: "tortoise.fill"
        case .cat: "cat.fill"
        case .bird: "bird.fill"
        case .flame: "flame.fill"
        }
    }

    private var styleIslandSize: CGSize {
        let clamped = min(max(expandedWidth, 520), 600)
        let delta = clamped - 520
        switch visualStyle {
        case .lunula:
            return CGSize(width: 380 + delta * 0.75, height: 68)
        case .alcove:
            return CGSize(width: 336 + delta * 0.55, height: 62)
        case .boring:
            return CGSize(width: 396 + delta * 0.75, height: 68)
        }
    }

    private var previewIslandRect: CGRect {
        let stageW = Self.stageSize.width
        switch focus {
        case .glass:
            return CGRect(x: (stageW - 404) * 0.5, y: 0, width: 404, height: 70)
        case .pill:
            return CGRect(x: (stageW - 180) * 0.5, y: CGFloat(pillVerticalOffset), width: 180, height: 22)
        case .style:
            let size = styleIslandSize
            return CGRect(x: (stageW - size.width) * 0.5, y: 0, width: size.width, height: size.height)
        case .timer, .bar:
            return CGRect(x: (stageW - 304) * 0.5, y: 0, width: 304, height: 32)
        }
    }

    private var currentTension: DropletTension {
        DropletPhysics.compute(
            pointer: waterDropletEffect && !reduceMotion ? hoverPoint : nil,
            islandRect: previewIslandRect,
            sensitivity: dropletSensitivity
        )
    }

    public var body: some View {
        ZStack(alignment: .top) {
            RadialGradient(
                colors: [Color(red: 0x2B / 255, green: 0x32 / 255, blue: 0x66 / 255), Color.clear],
                center: UnitPoint(x: 0.15, y: 0.0),
                startRadius: 0,
                endRadius: 300
            )
            .background(
                RadialGradient(
                    colors: [Color(red: 0x4A / 255, green: 0x25 / 255, blue: 0x50 / 255), Color.clear],
                    center: UnitPoint(x: 0.88, y: 0.0),
                    startRadius: 0,
                    endRadius: 280
                )
            )
            .background(Color(red: 0x0C / 255, green: 0x0E / 255, blue: 0x15 / 255))

            switch focus {
            case .glass:
                glassPreview
            case .pill:
                pillPreview
            case .style:
                stylePreview
            case .timer, .bar:
                notchTimerPreview
            }
        }
        .frame(width: Self.stageSize.width, height: Self.stageSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(increaseContrast ? Palette.hairlineContrast : Palette.hairline, lineWidth: 0.5)
        )
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                if reduceMotion {
                    hoverPoint = nil
                } else {
                    withAnimation(.spring(duration: 0.35, bounce: 0.12)) {
                        hoverPoint = location
                    }
                }
            case .ended:
                withAnimation(.spring(duration: 0.35, bounce: 0.12)) {
                    hoverPoint = nil
                }
            }
        }
    }

    // MARK: - Menu Bar Strip

    @ViewBuilder
    private var menuBarStrip: some View {
        if hideNotchBar {
            Rectangle()
                .fill(Palette.obsidian)
                .frame(height: 32)
        } else {
            HStack {
                HStack(spacing: 14) {
                    Text("Finder").fontWeight(.bold)
                    Text("settings.preview.menu.file")
                    Text("settings.preview.menu.edit")
                }
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Palette.textPrimary)
                .padding(.leading, 14)

                Spacer()

                Text("settings.preview.menu.clock")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Palette.textPrimary)
                    .padding(.trailing, 14)
            }
            .frame(height: 32)
        }
    }

    // MARK: - Notch Timer Preview

    private var notchTimerPreview: some View {
        let tension = currentTension
        let fluidShape = FluidIslandShape(base: .closed, tension: tension)

        return ZStack(alignment: .top) {
            menuBarStrip

            ZStack {
                if glowOpacity > 0 {
                    fluidShape
                        .stroke(activeHaloColor, lineWidth: 20)
                        .frame(width: 304, height: 32)
                        .blur(radius: 14)
                        .opacity(glowOpacity)
                }

                IslandShellBackground(
                    material: surfaceMaterial,
                    shape: fluidShape,
                    notchSize: Self.previewNotchSize,
                    hasHardwareNotch: true,
                    artworkTint: Self.boringTint,
                    visualStyle: visualStyle
                )
                .frame(width: 304, height: 32)
                .overlay {
                    if rimOpacity > 0 {
                        fluidShape
                            .stroke(activeHaloColor.opacity(rimOpacity), lineWidth: rimWidth)
                    }
                }
                .overlay {
                    DropletSpecularOverlay(tension: tension, shape: fluidShape)
                }

                HStack {
                    Image(systemName: mascotSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(visualStyle == .alcove ? Palette.textPrimary : activeHaloColor)

                    Spacer()

                    Text("12:47")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Palette.textPrimary)
                }
                .padding(.horizontal, 14)
                .frame(width: 292, height: 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Style & Physics Miniature Preview

    private var stylePreview: some View {
        let size = styleIslandSize
        let tension = currentTension
        let fluidShape = FluidIslandShape(base: .expanded, tension: tension)

        return ZStack(alignment: .top) {
            menuBarStrip

            ZStack(alignment: .top) {
                if glowOpacity > 0 {
                    fluidShape
                        .stroke(activeHaloColor, lineWidth: 20)
                        .frame(width: size.width, height: size.height)
                        .blur(radius: 14)
                        .opacity(glowOpacity)
                }

                IslandShellBackground(
                    material: surfaceMaterial,
                    shape: fluidShape,
                    notchSize: Self.previewNotchSize,
                    hasHardwareNotch: true,
                    artworkTint: Self.boringTint,
                    visualStyle: visualStyle
                )
                .frame(width: size.width, height: size.height)
                .overlay {
                    if rimOpacity > 0 {
                        fluidShape
                            .stroke(activeHaloColor.opacity(rimOpacity), lineWidth: rimWidth)
                    }
                }
                .overlay {
                    DropletSpecularOverlay(tension: tension, shape: fluidShape)
                }

                styleInnerContent(size: size)
                    .frame(width: size.width - 28, height: size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func styleInnerContent(size: CGSize) -> some View {
        switch visualStyle {
        case .lunula:
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: mascotSymbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.amberGold)

                    Text("settings.preview.pill.focus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Palette.textPrimary)

                    Text("25:00")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Palette.amberGold)
                }

                Spacer(minLength: 8)

                Text("\(Int(expandedWidth.rounded())) pt")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Palette.warmCream)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(Palette.inkPressed)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Palette.amberGold.opacity(0.35), lineWidth: 0.5)
                    )
            }
            .padding(.top, 24)
            .padding(.horizontal, 6)

        case .alcove:
            HStack(spacing: 8) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Palette.textPrimary)

                Text("settings.preview.style.alcoveFocus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Palette.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("12:47")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Palette.textSecondary)
            }
            .padding(.top, 22)
            .padding(.horizontal, 8)

        case .boring:
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.32, blue: 0.62),
                                    Color(red: 0.52, green: 0.24, blue: 0.88),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "music.note")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Palette.textPrimary)
                }
                .frame(width: 26, height: 26)

                Text("settings.preview.style.trackTitle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                    .lineLimit(1)

                HStack(alignment: .center, spacing: 2.5) {
                    ForEach(0..<Self.equalizerHeights.count, id: \.self) { index in
                        Capsule()
                            .fill(Color(red: 0.95, green: 0.42, blue: 0.72))
                            .frame(width: 2.5, height: Self.equalizerHeights[index])
                    }
                }
                .frame(height: 20)

                Spacer(minLength: 6)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .medium))
                    Text("settings.preview.style.agendaChip")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(Palette.textPrimary)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(Palette.inkPressed)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Palette.hairline, lineWidth: 0.5)
                )
            }
            .padding(.top, 24)
            .padding(.horizontal, 6)
        }
    }

    // MARK: - Liquid Glass Preview (Download Peek 380 × 70 pt)

    private var glassPreview: some View {
        let tension = currentTension
        let fluidShape = FluidIslandShape(base: .expanded, tension: tension)

        return ZStack(alignment: .top) {
            ZStack {
                if glowOpacity > 0 {
                    fluidShape
                        .stroke(Color.white, lineWidth: 20)
                        .frame(width: 404, height: 70)
                        .blur(radius: 14)
                        .opacity(glowOpacity)
                }

                IslandShellBackground(
                    material: surfaceMaterial,
                    shape: fluidShape,
                    notchSize: Self.previewNotchSize,
                    hasHardwareNotch: true,
                    artworkTint: Self.boringTint,
                    visualStyle: visualStyle
                )
                .frame(width: 404, height: 70)
                .overlay {
                    if rimOpacity > 0 {
                        fluidShape
                            .stroke(Color.white.opacity(rimOpacity), lineWidth: rimWidth)
                    }
                }
                .overlay {
                    DropletSpecularOverlay(tension: tension, shape: fluidShape)
                }

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Palette.inkRaised)

                        if useGlassCards || surfaceMaterial == .liquidGlass {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.white.opacity(0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(alignment: .top) {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.24), Color.white.opacity(0.10)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 0.75)
                                }
                        }

                        Image(systemName: "doc.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Palette.textSecondary)
                    }
                    .frame(width: 42, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Palette.hairline, lineWidth: 0.5)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("settings.preview.download.file")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Palette.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("settings.preview.download.status")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textSecondary)
                        }

                        HStack(spacing: 8) {
                            Text("settings.preview.download.reveal")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                                .padding(.horizontal, 8)
                                .frame(height: 22)
                                .background(Palette.inkPressed)
                                .clipShape(Capsule())

                            Text("settings.preview.download.shelf")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Palette.textPrimary)
                                .padding(.horizontal, 8)
                                .frame(height: 22)
                                .background(Palette.inkPressed)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(width: 380, height: 70)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Pill Mode Preview (180 × 22 pt Capsule)

    private var pillPreview: some View {
        let tension = currentTension
        let fluidShape = FluidIslandShape(base: .pill, tension: tension)

        return ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: mascotSymbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(visualStyle == .alcove ? Palette.textPrimary : activeHaloColor)

                    Text("settings.preview.pill.focus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Palette.textSecondary)

                    Spacer()

                    Text("12:47")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Palette.textPrimary)
                }
                .padding(.horizontal, 8)
                .frame(width: 180, height: 22)
                .background {
                    IslandShellBackground(
                        material: surfaceMaterial,
                        shape: fluidShape,
                        notchSize: .zero,
                        hasHardwareNotch: false,
                        artworkTint: Self.boringTint,
                        visualStyle: visualStyle
                    )
                }
                .overlay {
                    if rimOpacity > 0 {
                        fluidShape
                            .stroke(activeHaloColor.opacity(rimOpacity), lineWidth: rimWidth)
                    }
                }
                .overlay {
                    DropletSpecularOverlay(tension: tension, shape: fluidShape)
                }
                .shadow(color: activeHaloColor.opacity(glowOpacity), radius: 10)
                .offset(y: CGFloat(pillVerticalOffset))

                Spacer()

                HStack {
                    Text("settings.preview.pill.external")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Palette.textSecondary)
                        .padding(.leading, 14)
                        .padding(.bottom, 10)

                    Spacer()

                    Text("\(Int(pillVerticalOffset)) pt")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Palette.textSecondary)
                        .padding(.trailing, 14)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}
