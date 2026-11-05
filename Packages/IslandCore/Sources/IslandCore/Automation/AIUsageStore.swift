import Foundation
import Observation

public struct AIProviderUsage: Identifiable, Codable, Equatable, Sendable {
    public var id: String { provider }
    public var provider: String
    public var tokensUsed: Int
    public var costUSD: Double
    public var windowLimitPercent: Int
    public var updatedAt: Date

    public init(
        provider: String, tokensUsed: Int, costUSD: Double, windowLimitPercent: Int, updatedAt: Date
    ) {
        self.provider = provider
        self.tokensUsed = max(0, tokensUsed)
        self.costUSD = max(0, costUSD)
        self.windowLimitPercent = min(max(windowLimitPercent, 0), 100)
        self.updatedAt = updatedAt
    }
}

public struct AgentApprovalRequest: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var agentName: String
    public var commandSummary: String
    public var requestedAt: Date

    public init(id: String, agentName: String, commandSummary: String, requestedAt: Date) {
        self.id = id
        self.agentName = agentName
        self.commandSummary = commandSummary
        self.requestedAt = requestedAt
    }
}

/// Tracks AI coding assistant usage (Claude Code, Codex, Cursor, Copilot) and pending agent approvals via URL hooks.
@MainActor @Observable public final class AIUsageStore {
    static let storageKey = "ai.usage.v1"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let time: IslandTime
    public private(set) var providers: [AIProviderUsage] = []
    public private(set) var pendingApprovals: [AgentApprovalRequest] = []
    public private(set) var lastDecisions: [String: Bool] = [:]

    public init(defaults: UserDefaults, time: IslandTime) {
        self.defaults = defaults
        self.time = time
        if let data = defaults.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([AIProviderUsage].self, from: data)
        {
            providers = decoded
        } else {
            providers = [
                AIProviderUsage(
                    provider: "Claude Code", tokensUsed: 0, costUSD: 0, windowLimitPercent: 0, updatedAt: time.now),
                AIProviderUsage(
                    provider: "Codex", tokensUsed: 0, costUSD: 0, windowLimitPercent: 0, updatedAt: time.now),
                AIProviderUsage(
                    provider: "Cursor", tokensUsed: 0, costUSD: 0, windowLimitPercent: 0, updatedAt: time.now),
            ]
        }
    }

    public func update(provider: String, tokensUsed: Int, costUSD: Double, windowLimitPercent: Int) {
        let entry = AIProviderUsage(
            provider: provider, tokensUsed: tokensUsed, costUSD: costUSD,
            windowLimitPercent: windowLimitPercent, updatedAt: time.now)
        if let idx = providers.firstIndex(where: { $0.provider.caseInsensitiveCompare(provider) == .orderedSame }) {
            providers[idx] = entry
        } else {
            providers.append(entry)
        }
        persist()
    }

    public func requestApproval(id: String, agentName: String, commandSummary: String) {
        let req = AgentApprovalRequest(
            id: id, agentName: agentName, commandSummary: commandSummary, requestedAt: time.now)
        if let idx = pendingApprovals.firstIndex(where: { $0.id == id }) {
            pendingApprovals[idx] = req
        } else {
            pendingApprovals.insert(req, at: 0)
        }
    }

    /// Removes a pending approval. When `approved` is non-nil, records the user's decision; nil means resolved externally.
    public func resolveApproval(id: String, approved: Bool?) {
        pendingApprovals.removeAll { $0.id == id }
        if let approved {
            lastDecisions[id] = approved
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(providers) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
