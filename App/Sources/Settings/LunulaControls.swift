import IslandDesign
import SwiftUI

// MARK: - Lunula Custom Toggle Style (32 × 18 pt)

public struct LunulaSwitchStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer()
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(configuration.isOn ? Palette.textPrimary : Palette.inkPressed)
                        .frame(width: 32, height: 18)
                        .overlay(
                            Capsule()
                                .stroke(Palette.hairline, lineWidth: 0.5)
                        )
                    Circle()
                        .fill(configuration.isOn ? Palette.obsidian : Palette.textSecondary)
                        .frame(width: 14, height: 14)
                        .offset(x: configuration.isOn ? 16 : 2)
                }
                .animation(.smooth(duration: 0.20), value: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == LunulaSwitchStyle {
    public static var lunulaSwitch: LunulaSwitchStyle { LunulaSwitchStyle() }
}

// MARK: - Lunula Button Styles

public struct LunulaPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Palette.obsidian)
            .frame(height: 36)
            .padding(.horizontal, 24)
            .background(Palette.textPrimary)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

public struct LunulaSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Palette.textPrimary)
            .frame(height: 24)
            .padding(.horizontal, 10)
            .background(Palette.inkPressed)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

public struct LunulaBadgeButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Palette.textPrimary)
            .frame(height: 22)
            .padding(.horizontal, 10)
            .background(Palette.inkPressed)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

extension ButtonStyle where Self == LunulaPrimaryButtonStyle {
    public static var lunulaPrimary: LunulaPrimaryButtonStyle { LunulaPrimaryButtonStyle() }
}

extension ButtonStyle where Self == LunulaSecondaryButtonStyle {
    public static var lunulaSecondary: LunulaSecondaryButtonStyle { LunulaSecondaryButtonStyle() }
}

extension ButtonStyle where Self == LunulaBadgeButtonStyle {
    public static var lunulaBadge: LunulaBadgeButtonStyle { LunulaBadgeButtonStyle() }
}

// MARK: - Lunula Custom Segmented Picker

public struct LunulaSegmentPicker<T: Hashable>: View {
    @Binding var selection: T
    let items: [(value: T, label: String)]

    public init(selection: Binding<T>, items: [(value: T, label: String)]) {
        self._selection = selection
        self.items = items
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.value) { item in
                let isSelected = (selection == item.value)
                Button {
                    withAnimation(.spring(duration: 0.30, bounce: 0.08)) {
                        selection = item.value
                    }
                } label: {
                    Text(item.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? Palette.textPrimary : Palette.textSecondary)
                        .padding(.horizontal, 10)
                        .frame(height: 24)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Palette.inkPressed)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Palette.obsidian)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 0.5)
        )
    }
}

// MARK: - Lunula Halo Slider (Amber Glow)

public struct LunulaHaloSlider: View {
    @Binding var value: Double  // 0...1

    public init(value: Binding<Double>) {
        self._value = value
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let percent = max(0, min(1, value))
            let fillWidth = max(0, width * CGFloat(percent))
            let thumbX = max(9, min(width - 9, fillWidth))

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Palette.inkPressed)
                    .frame(height: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Palette.hairline, lineWidth: 0.5)
                    )

                // Fill gradient with glow
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.warmCream, Palette.amberGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: 4)
                    .shadow(
                        color: Palette.amberGold.opacity(0.6 * percent),
                        radius: 10
                    )

                // Thumb
                Circle()
                    .fill(Palette.textPrimary)
                    .frame(width: 18, height: 18)
                    .position(x: thumbX, y: 12)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let clampedX = max(0, min(width, gesture.location.x))
                        value = Double(clampedX / width)
                    }
            )
        }
        .frame(height: 24)
    }
}

// MARK: - Lunula Ticked Slider (Pill Offset 0...8 pt)

public struct LunulaTickedSlider: View {
    @Binding var value: Double  // 0...8
    let maxRange: Double = 8

    public init(value: Binding<Double>) {
        self._value = value
    }

    public var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                let percent = max(0, min(1, value / maxRange))
                let fillWidth = max(0, width * CGFloat(percent))
                let thumbX = max(9, min(width - 9, fillWidth))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Palette.inkPressed)
                        .frame(height: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Palette.hairline, lineWidth: 0.5)
                        )

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Palette.textPrimary)
                        .frame(width: fillWidth, height: 4)

                    Circle()
                        .fill(Palette.textPrimary)
                        .frame(width: 18, height: 18)
                        .position(x: thumbX, y: 10)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let clampedX = max(0, min(width, gesture.location.x))
                            let raw = (clampedX / width) * maxRange
                            value = round(raw)
                        }
                )
            }
            .frame(height: 20)

            // 9 tick marks (0...8)
            HStack {
                ForEach(0...8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Palette.textTertiary)
                        .frame(width: 2, height: 4)
                    if true {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 9)
        }
        .frame(height: 30)
    }
}
