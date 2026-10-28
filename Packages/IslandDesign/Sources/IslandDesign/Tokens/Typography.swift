import SwiftUI

public enum TypeToken: CaseIterable, Sendable {
    case numeralLarge, numeralCompact, title, body, caption

    public var size: CGFloat {
        switch self {
        case .numeralLarge: 28
        case .numeralCompact, .body: 13
        case .title: 15
        case .caption: 11
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .numeralLarge, .title: .semibold
        case .numeralCompact, .caption: .medium
        case .body: .regular
        }
    }

    public var isRounded: Bool { self == .numeralLarge || self == .numeralCompact }

    public var monospacedDigits: Bool { self == .numeralLarge || self == .numeralCompact }

    public var font: Font {
        let base = Font.system(size: size, weight: weight, design: isRounded ? .rounded : .default)
        return monospacedDigits ? base.monospacedDigit() : base
    }
}
