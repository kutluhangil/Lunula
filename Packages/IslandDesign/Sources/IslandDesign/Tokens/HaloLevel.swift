public enum HaloLevel: CaseIterable, Sendable {
    case off, ambient, active, alert

    public var intensity: Double {
        switch self {
        case .off: 0
        case .ambient: 0.16
        case .active: 0.32
        case .alert: 0.55
        }
    }
}
