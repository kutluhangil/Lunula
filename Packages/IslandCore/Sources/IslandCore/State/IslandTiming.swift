import Foundation

public enum IslandTiming {
    public static let dwell: TimeInterval = 0.100
    public static let exitGrace: TimeInterval = 0.250
    public static let maxPeekSpeed: Double = 1200
    public static let fullscreenCriticalAlert: TimeInterval = 2.0
    public static let maxQueuedAlerts = 3
}
