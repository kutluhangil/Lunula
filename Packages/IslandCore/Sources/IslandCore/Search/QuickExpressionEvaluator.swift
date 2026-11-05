import Foundation

public enum SearchEngine: String, CaseIterable, Codable, Sendable {
    case google, duckDuckGo, bing, perplexity, github, youtube, wikipedia, googleTranslate

    public var displayName: String {
        switch self {
        case .google: "Google"
        case .duckDuckGo: "DuckDuckGo"
        case .bing: "Bing"
        case .perplexity: "Perplexity"
        case .github: "GitHub"
        case .youtube: "YouTube"
        case .wikipedia: "Wikipedia"
        case .googleTranslate: "Translate"
        }
    }

    public func searchURL(for query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        let raw: String =
            switch self {
            case .google: "https://www.google.com/search?q=\(encoded)"
            case .duckDuckGo: "https://duckduckgo.com/?q=\(encoded)"
            case .bing: "https://www.bing.com/search?q=\(encoded)"
            case .perplexity: "https://www.perplexity.ai/search?q=\(encoded)"
            case .github: "https://github.com/search?q=\(encoded)"
            case .youtube: "https://www.youtube.com/results?search_query=\(encoded)"
            case .wikipedia: "https://en.wikipedia.org/w/index.php?search=\(encoded)"
            case .googleTranslate: "https://translate.google.com/?sl=auto&tl=tr&text=\(encoded)&op=translate"
            }
        return URL(string: raw)
    }
}

/// Safe recursive-descent arithmetic evaluator (`+`, `-`, `*`, `/`, parentheses) for quick sums in the notch.
public enum QuickExpressionEvaluator {
    public static func evaluate(_ input: String) -> Double? {
        let cleaned = input.replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/() ")
        guard cleaned.unicodeScalars.allSatisfy({ allowed.contains($0) }),
            cleaned.contains(where: { "+-*/".contains($0) })
        else { return nil }

        var scanner = Scanner(characters: Array(cleaned))
        guard let value = scanner.parseExpression(),
            scanner.isAtEnd,
            value.isFinite
        else { return nil }
        return value
    }

    public static func format(_ value: Double) -> String {
        if value.rounded() == value, abs(value) < 1e12 {
            return String(Int64(value))
        }
        return String(format: "%.4f", value)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }

    private struct Scanner {
        let characters: [Character]
        var index = 0

        var isAtEnd: Bool {
            var i = index
            while i < characters.count, characters[i].isWhitespace { i += 1 }
            return i >= characters.count
        }

        mutating func skipWhitespace() {
            while index < characters.count, characters[index].isWhitespace { index += 1 }
        }

        mutating func parseExpression() -> Double? {
            guard var left = parseTerm() else { return nil }
            while true {
                skipWhitespace()
                guard index < characters.count else { break }
                let op = characters[index]
                guard op == "+" || op == "-" else { break }
                index += 1
                guard let right = parseTerm() else { return nil }
                left = op == "+" ? left + right : left - right
            }
            return left
        }

        mutating func parseTerm() -> Double? {
            guard var left = parseFactor() else { return nil }
            while true {
                skipWhitespace()
                guard index < characters.count else { break }
                let op = characters[index]
                guard op == "*" || op == "/" else { break }
                index += 1
                guard let right = parseFactor() else { return nil }
                if op == "/" {
                    guard right != 0 else { return nil }
                    left /= right
                } else {
                    left *= right
                }
            }
            return left
        }

        mutating func parseFactor() -> Double? {
            skipWhitespace()
            guard index < characters.count else { return nil }
            if characters[index] == "+" {
                index += 1
                return parseFactor()
            }
            if characters[index] == "-" {
                index += 1
                guard let v = parseFactor() else { return nil }
                return -v
            }
            if characters[index] == "(" {
                index += 1
                guard let inner = parseExpression() else { return nil }
                skipWhitespace()
                guard index < characters.count, characters[index] == ")" else { return nil }
                index += 1
                return inner
            }
            let start = index
            var hasDot = false
            while index < characters.count {
                let c = characters[index]
                if c.isNumber {
                    index += 1
                } else if c == "." && !hasDot {
                    hasDot = true
                    index += 1
                } else {
                    break
                }
            }
            guard index > start else { return nil }
            return Double(String(characters[start..<index]))
        }
    }
}
