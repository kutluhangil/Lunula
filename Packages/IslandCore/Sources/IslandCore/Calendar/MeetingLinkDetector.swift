import Foundation

public enum MeetingLinkDetector {
    // Regexes are compiled once; the patterns are literals, so `try!` cannot fail at runtime.
    private static let candidate = try! NSRegularExpression(pattern: #"(?:https?|zoommtg)://[^\s<>"']+"#)

    private static let services: [(MeetingService, NSRegularExpression)] = [
        (MeetingService.zoom, #"^https?://([\w-]+\.)?zoom\.(us|com)/(j|w|my|s)/|^zoommtg://"#),
        (.googleMeet, #"^https?://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}"#),
        (.teams, #"^https?://teams\.(microsoft|live)\.com/(l/meetup-join|meet)/"#),
        (.facetime, #"^https?://facetime\.apple\.com/join"#),
        (.webex, #"^https?://[\w-]+\.webex\.com/"#),
    ].map { ($0.0, try! NSRegularExpression(pattern: $0.1, options: .caseInsensitive)) }

    private static let trailing = CharacterSet(charactersIn: ").,;:!?>]")

    public static func detect(in fields: [String?]) -> MeetingLink? {
        for case let field? in fields {
            let ns = field as NSString
            for match in candidate.matches(in: field, range: NSRange(location: 0, length: ns.length)) {
                var text = ns.substring(with: match.range)
                while let last = text.unicodeScalars.last, trailing.contains(last) { text.removeLast() }
                text = unwrapSafeLinks(text)
                let range = NSRange(location: 0, length: (text as NSString).length)
                guard let service = services.first(where: { $0.1.firstMatch(in: text, range: range) != nil })?.0,
                    let url = URL(string: text)
                else { continue }
                return MeetingLink(service: service, url: url)
            }
        }
        return nil
    }

    // Only the wrapper's `url` parameter is percent-decoded; everything else stays untouched.
    private static func unwrapSafeLinks(_ text: String) -> String {
        guard let c = URLComponents(string: text), let host = c.host?.lowercased(),
            host.hasSuffix("safelinks.protection.outlook.com"),
            let inner = c.queryItems?.first(where: { $0.name == "url" })?.value
        else { return text }
        return inner
    }
}
