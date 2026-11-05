import Foundation

public enum IslandURLParser {
    /// URLs can come from any app: every value is validated, nothing here traps on malformed input.
    public static func parse(_ url: URL, expectedScheme: String = "lunula") -> Result<IslandURLCommand, IslandURLError>
    {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
            comps.scheme?.lowercased() == expectedScheme.lowercased()
        else { return .failure(.wrongScheme) }

        let path = ((comps.host ?? "") + comps.path).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var query: [String: String] = [:]
        for item in comps.queryItems ?? [] where query[item.name] == nil {
            if let value = item.value { query[item.name] = value }
        }

        switch path {
        case "activity/show":
            // Non-numeric numbers become NaN so make() reports them in its own validation order.
            return CustomActivityRequest.make(
                id: query["id"], title: query["title"], subtitle: query["subtitle"], symbol: query["symbol"],
                accentHex: query["accent"], progress: query["progress"].map { Double($0) ?? .nan },
                duration: query["duration"].map { Double($0) ?? .nan }
            ).map(IslandURLCommand.showActivity)
        case "activity/end":
            if let failure = CustomActivityRequest.validateID(query["id"]) { return .failure(failure) }
            return .success(.endActivity(id: query["id"] ?? ""))
        case "timer/start":
            guard let raw = query["minutes"] else { return .failure(.missingParameter("minutes")) }
            guard let minutes = Double(raw), CustomActivityLimits.timerMinutes.contains(minutes) else {
                return .failure(.invalidParameter("minutes"))
            }
            return .success(.startTimer(minutes: minutes))
        case "island/toggle":
            return .success(.toggleIsland)
        case "ai/usage":
            let provider = (query["provider"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !provider.isEmpty else { return .failure(.missingParameter("provider")) }
            guard let rawTokens = query["tokens"] else { return .failure(.missingParameter("tokens")) }
            guard let tokens = Int(rawTokens), tokens >= 0 else { return .failure(.invalidParameter("tokens")) }
            let cost = query["cost"].flatMap(Double.init) ?? 0
            guard !cost.isNaN, cost >= 0 else { return .failure(.invalidParameter("cost")) }
            let limit = query["limit"].flatMap(Int.init) ?? 0
            return .success(
                .updateAIUsage(
                    provider: provider, tokensUsed: tokens, costUSD: cost,
                    windowLimitPercent: min(max(limit, 0), 100)))
        case "agent/approval":
            if let failure = CustomActivityRequest.validateID(query["id"]) { return .failure(failure) }
            let agent = (query["agent"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !agent.isEmpty else { return .failure(.missingParameter("agent")) }
            let command = (query["command"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !command.isEmpty else { return .failure(.missingParameter("command")) }
            return .success(.requestAgentApproval(id: query["id"] ?? "", agent: agent, command: command))
        case "agent/resolve":
            if let failure = CustomActivityRequest.validateID(query["id"]) { return .failure(failure) }
            return .success(.resolveAgentApproval(id: query["id"] ?? ""))
        default:
            return .failure(.unknownCommand(path))
        }
    }
}
