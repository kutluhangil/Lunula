import Foundation

@MainActor public protocol FeedbackPlaying: AnyObject {
    func play(_ haptic: HapticKind)
    func play(_ sound: SoundKind)
}
