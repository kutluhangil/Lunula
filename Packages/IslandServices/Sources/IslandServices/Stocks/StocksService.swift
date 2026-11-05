import Foundation
import IslandCore
import Observation

/// Fetches stock & crypto quotes on demand (when the Stocks popover is opened) with market-session state labels.
@MainActor @Observable public final class StocksService {
    private struct ChartResponse: Decodable {
        struct Chart: Decodable {
            struct Result: Decodable {
                struct Meta: Decodable {
                    var symbol: String?
                    var regularMarketPrice: Double?
                    var chartPreviousClose: Double?
                    var marketState: String?
                }
                var meta: Meta
            }
            var result: [Result]?
        }
        var chart: Chart
    }

    @ObservationIgnored private let store: StocksWatchlistStore
    @ObservationIgnored private let session: URLSession
    public private(set) var isFetching = false

    public init(store: StocksWatchlistStore, session: URLSession = .shared) {
        self.store = store
        self.session = session
    }

    public func refreshAll() {
        guard !isFetching else { return }
        let symbols = store.symbols
        guard !symbols.isEmpty else {
            store.quotes = []
            return
        }
        isFetching = true
        let session = self.session
        Task { [weak self] in
            var fetched: [StockQuote] = []
            for sym in symbols {
                if let quote = await Self.fetchQuote(symbol: sym, session: session) {
                    fetched.append(quote)
                }
            }
            guard let self else { return }
            if !fetched.isEmpty {
                store.quotes = fetched
            }
            isFetching = false
        }
    }

    private static func fetchQuote(symbol: String, session: URLSession) async -> StockQuote? {
        guard let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d")
        else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await session.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200,
            let decoded = try? JSONDecoder().decode(ChartResponse.self, from: data),
            let meta = decoded.chart.result?.first?.meta,
            let price = meta.regularMarketPrice
        else { return nil }
        let prev = meta.chartPreviousClose ?? price
        let change = prev > 0 ? ((price - prev) / prev) * 100 : 0
        let state: MarketSessionState =
            switch meta.marketState?.uppercased() {
            case "REGULAR": .regular
            case "PRE", "PREPRE": .preMarket
            case "POST", "POSTPOST": .afterHours
            default: .closed
            }
        return StockQuote(symbol: symbol, price: price, changePercent: change, session: state)
    }
}
