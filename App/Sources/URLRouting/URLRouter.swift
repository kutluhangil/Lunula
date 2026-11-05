import Foundation
import IslandCore
import OSLog

/// `lunula://` commands from Terminal, scripts and agent hooks (no network). Rate limited; invalid URLs change
/// nothing.
@MainActor final class URLRouter {
    private let custom: CustomActivityController
    private let timer: TimerController
    private let aiUsage: AIUsageStore?
    private let onAgentApprovalRequested: (@MainActor (AgentApprovalRequest) -> Void)?
    private let toggle: @MainActor () -> Void
    private let time: IslandTime
    private var limiter: RateLimiter
    private let logger = Logger(subsystem: "com.kutluhangul.lunula", category: "url")

    init(
        custom: CustomActivityController, timer: TimerController,
        aiUsage: AIUsageStore? = nil,
        onAgentApprovalRequested: (@MainActor (AgentApprovalRequest) -> Void)? = nil,
        toggle: @escaping @MainActor () -> Void,
        time: IslandTime, limiter: RateLimiter = RateLimiter()
    ) {
        self.custom = custom
        self.timer = timer
        self.aiUsage = aiUsage
        self.onAgentApprovalRequested = onAgentApprovalRequested
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
        case .success(.updateAIUsage(let provider, let tokensUsed, let costUSD, let windowLimitPercent)):
            aiUsage?.update(
                provider: provider, tokensUsed: tokensUsed, costUSD: costUSD,
                windowLimitPercent: windowLimitPercent)
        case .success(.requestAgentApproval(let id, let agent, let command)):
            aiUsage?.requestApproval(id: id, agentName: agent, commandSummary: command)
            if let req = aiUsage?.pendingApprovals.first(where: { $0.id == id }) {
                onAgentApprovalRequested?(req)
            }
        case .success(.resolveAgentApproval(let id)):
            aiUsage?.resolveApproval(id: id, approved: nil)
        case .failure(let error):
            logger.notice("Invalid URL command (\(String(describing: error), privacy: .public))")
        }
        return result
    }
}
