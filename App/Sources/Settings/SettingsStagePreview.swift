import IslandCore
import IslandDesign
import SwiftUI

public enum SettingsPreviewFocus: Equatable, Sendable {
    case timer
    case glass
    case pill
    case bar
}

/// The live 656 × 88 pt stage at the top of the Settings window that interactively reacts to user settings.
public struct SettingsStagePreview: View {
    let focus: SettingsPreviewFocus
    let haloIntensity: Double
    let mascot: TimerMascot
    let hideNotchBar: Bool
    let useGlassCards: Bool
    let pillVerticalOffset: Double
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    private var increaseContrast: Bool { colorSchemeContrast == .increased }

    public init(
        focus: SettingsPreviewFocus = .timer,
        haloIntensity: Double = 1.0,
        mascot: TimerMascot = .none,
        hideNotchBar: Bool = false,
        useGlassCards: Bool = false,
        pillVerticalOffset: Double = 0
    ) {
        self.focus = focus
        self.haloIntensity = haloIntensity
        self.mascot = mascot
        self.hideNotchBar = hideNotchBar
        self.useGlassCards = useGlassCards
        self.pillVerticalOffset = pillVerticalOffset
    }

    private var glowOpacity: Double {
        0.32 * max(0, min(1, haloIntensity))
    }

    private var rimOpacity: Double {
        haloIntensity > 0 ? (increaseContrast ? 0.60 : 0.35) : 0
    }

    private var rimWidth: CGFloat {
        increaseContrast ? 1.5 : 1.0
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

    public var body: some View {
        ZStack {
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

            if focus == .glass {
                glassPreview
            } else if focus == .pill {
                pillPreview
            } else {
                notchTimerPreview
            }
        }
        .frame(width: 656, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(increaseContrast ? Palette.hairlineContrast : Palette.hairline, lineWidth: 0.5)
        )
    }

    // MARK: - Notch Timer Preview

    private var notchTimerPreview: some View {
        ZStack(alignment: .top) {
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

            ZStack {
                IslandShape.closed
                    .stroke(Palette.amberGold, lineWidth: 20)
                    .frame(width: 304, height: 32)
                    .blur(radius: 14)
                    .opacity(glowOpacity)

                IslandShape.closed
                    .fill(Palette.obsidian)
                    .frame(width: 304, height: 32)
                    .overlay(
                        IslandShape.closed
                            .stroke(Palette.amberGold.opacity(rimOpacity), lineWidth: rimWidth)
                    )

                HStack {
                    Image(systemName: mascotSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Palette.amberGold)

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
    }

    // MARK: - Liquid Glass Preview (Download Peek 380 × 70 pt)

    private var glassPreview: some View {
        ZStack(alignment: .top) {
            ZStack {
                IslandShape.expanded
                    .stroke(Color.white, lineWidth: 20)
                    .frame(width: 404, height: 70)
                    .blur(radius: 14)
                    .opacity(glowOpacity)

                IslandShape.expanded
                    .fill(Palette.obsidian)
                    .frame(width: 404, height: 70)
                    .overlay(
                        IslandShape.expanded
                            .stroke(Color.white.opacity(rimOpacity), lineWidth: rimWidth)
                    )

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Palette.inkRaised)

                        if useGlassCards {
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
    }

    // MARK: - Pill Mode Preview (180 × 22 pt Capsule)

    private var pillPreview: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: mascotSymbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Palette.amberGold)

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
                .background(Palette.obsidian)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Palette.amberGold.opacity(rimOpacity), lineWidth: rimWidth)
                )
                .shadow(color: Palette.amberGold.opacity(glowOpacity), radius: 10)
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
