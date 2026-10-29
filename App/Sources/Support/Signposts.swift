import OSLog

/// Points of interest for Instruments (T9.5): phase changes, window syncs and URL commands.
enum Signposts {
    static let island = OSSignposter(subsystem: "com.kutluhangul.lunula", category: .pointsOfInterest)
}
