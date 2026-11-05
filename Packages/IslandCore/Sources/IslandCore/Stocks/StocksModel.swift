import Foundation
import Observation

public enum MarketSessionState: String, Codable, Equatable, Sendable {
    case regular, preMarket, afterHours, closed
}

public struct StockQuote: Identifiable, Codable, Equatable, Sendable {
    public var id: String { symbol }
    public var symbol: String
    public var price: Double
    public var changePercent: Double
    public var session: MarketSessionState

    public init(symbol: String, price: Double, changePercent: Double, session: MarketSessionState) {
        self.symbol = symbol.uppercased()
        self.price = price
        self.changePercent = changePercent
        self.session = session
    }
}

/// Persists the user's stock watchlist symbols and latest fetched quotes.
@MainActor @Observable public final class StocksWatchlistStore {
    static let symbolsKey = "stocks.symbols.v1"
    public static let defaultSymbols = ["AAPL", "NVDA", "MSFT", "BTC-USD"]

    @ObservationIgnored private let defaults: UserDefaults
    public private(set) var symbols: [String]
    public var quotes: [StockQuote] = []

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        if let saved = defaults.stringArray(forKey: Self.symbolsKey), !saved.isEmpty {
            self.symbols = saved
        } else {
            self.symbols = Self.defaultSymbols
        }
    }

    public func addSymbol(_ raw: String) {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleaned.isEmpty, !symbols.contains(cleaned) else { return }
        symbols.append(cleaned)
        defaults.set(symbols, forKey: Self.symbolsKey)
    }

    public func removeSymbol(_ symbol: String) {
        symbols.removeAll { $0 == symbol.uppercased() }
        quotes.removeAll { $0.symbol == symbol.uppercased() }
        defaults.set(symbols, forKey: Self.symbolsKey)
    }
}
