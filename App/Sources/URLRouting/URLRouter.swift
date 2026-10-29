import Foundation
import IslandCore
import OSLog

/// `lunula://` commands from Terminal, scripts and agent hooks (no network). Rate limited; invalid URLs change
/// nothing.
@MainActor final class URLRouter {
    private let custom: CustomActivityController
    private let timer: TimerController
    private let toggle: @MainActor () -> Void
    private let time: IslandTime
    private var limiter: RateLimiter
    private let logger = Logger(subsystem: "com.kutluhangul.lunula", category: "url")

    init(
        custom: CustomActivityController, timer: TimerController, toggle: @escaping @MainActor () -> Void,
        time: IslandTime, limiter: RateLimiter = RateLimiter()
    ) {
        self.custom = custom
        self.timer = timer
        self.toggle = toggle
        self.time = time
        self.limiter = limiter
    }

    @discardableResult
    func handle(_ url: URL) -> Result<IslandURLCommand, IslandURLError> {
        guard limiter.allow(at: time.now) else {
            logger.notice("URL command dropped by rate limit: \(url.absoluteString, privacy: .private)")
            return .failure(.rateLimited)
        }
        let result = IslandURLParser.parse(url)
        switch result {
        case .success(.showActivity(let request)): custom.show(request)
        case .success(.endActivity(let id)): custom.end(id: id)
        case .success(.startTimer(let minutes)): timer.start(minutes: minutes, label: nil)
        case .success(.toggleIsland): toggle()
        case .failure(let error):
            logger.notice("Invalid URL command (\(String(describing: error), privacy: .public))")
        }
        return result
    }
}
