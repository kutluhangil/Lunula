import IslandDesign
import SwiftUI

/// Tab 5: About view with glowing Lunula crescent emblem, version, system metrics badges, and licenses.
struct AboutSettingsView: View {
    static var attributions: [(name: String, license: String)] {
        [
            ("KeyboardShortcuts", "MIT · Sindre Sorhus"),
            (String(localized: "settings.about.openMeteo"), "CC BY 4.0"),
        ]
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return String(localized: "settings.about.versionFormat \(version) \(build)")
    }

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Center Emblem and App Info
            VStack(spacing: 8) {
                lunulaEmblem
                    .frame(width: 72, height: 72)

                Text("app.name")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)

                Text(versionString)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.textSecondary)

                HStack(spacing: 6) {
                    metricBadge(titleKey: "settings.about.badge.native", dotColor: Palette.textPrimary)
                    metricBadge(titleKey: "settings.about.badge.sandbox", dotColor: Palette.textPrimary)
                    metricBadge(titleKey: "settings.about.badge.idle", dotColor: Palette.signalGreen)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)

            // MARK: - Licenses and Attributions Section
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.about.licensesTitle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    HStack {
                        Text("KeyboardShortcuts")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text("MIT · Sindre Sorhus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)

                    Divider().overlay(Color.white.opacity(0.08))

                    HStack {
                        Text("settings.about.weatherData")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        if let url = URL(string: "https://open-meteo.com") {
                            Link("Open-Meteo.com · CC BY 4.0", destination: url)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Palette.textSecondary)
                        } else {
                            Text("Open-Meteo.com · CC BY 4.0")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                }
                .background(Palette.inkRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Palette.hairlineContrast, lineWidth: 0.5)
                )
            }
        }
    }

    private var lunulaEmblem: some View {
        let crescentGradient = LinearGradient(
            colors: [Palette.warmCream, Palette.amberGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                )

            // Blur glow behind crescent (even-odd fill cuts out the inner circle)
            crescentShape
                .fill(crescentGradient, style: FillStyle(eoFill: true))
                .frame(width: 44, height: 44)
                .opacity(0.55)
                .blur(radius: 4)

            // Crisp sharp crescent
            crescentShape
                .fill(crescentGradient, style: FillStyle(eoFill: true))
                .frame(width: 44, height: 44)
        }
    }

    private var crescentShape: some Shape {
        CrescentMoonShape()
    }

    private func metricBadge(titleKey: LocalizedStringKey, dotColor: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(titleKey)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Palette.textPrimary)
        }
        .padding(.horizontal, 10)
        .frame(height: 22)
        .background(Palette.inkPressed)
        .clipShape(Capsule())
    }
}

/// A crescent moon created by subtracting a secondary offset circle from a base circle via even-odd fill.
private struct CrescentMoonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var outer = Path()
        outer.addEllipse(in: rect)

        let cutRadius = rect.width * 0.477  // 21 / 44
        let cutX = rect.midX + rect.width * (5.0 / 44.0)
        let cutY = rect.midY - rect.height * (4.0 / 44.0)
        let cutRect = CGRect(
            x: cutX - cutRadius,
            y: cutY - cutRadius,
            width: cutRadius * 2,
            height: cutRadius * 2
        )

        var inner = Path()
        inner.addEllipse(in: cutRect)

        var crescent = Path()
        crescent.addPath(outer)
        crescent.addPath(inner)
        return Path(crescent.cgPath)
    }
}
