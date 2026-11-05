import Foundation

public struct SyncedLyricLine: Equatable, Sendable, Codable {
    public var time: TimeInterval
    public var text: String

    public init(time: TimeInterval, text: String) {
        self.time = time
        self.text = text
    }
}

/// Pure LRC parser (`[mm:ss.xx] line`) and active-line lookup for Now Playing synced lyrics.
public enum SyncedLyricsParser {
    public static func parse(_ lrc: String) -> [SyncedLyricLine] {
        var result: [SyncedLyricLine] = []
        for rawLine in lrc.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("["), let closeIdx = line.firstIndex(of: "]") else { continue }
            let tag = line[line.index(after: line.startIndex)..<closeIdx]
            let parts = tag.split(separator: ":")
            guard parts.count == 2,
                let minutes = Double(parts[0]),
                let seconds = Double(parts[1])
            else { continue }
            let lyricText = line[line.index(after: closeIdx)...].trimmingCharacters(in: .whitespaces)
            guard !lyricText.isEmpty else { continue }
            result.append(SyncedLyricLine(time: minutes * 60 + seconds, text: lyricText))
        }
        return result.sorted { $0.time < $1.time }
    }

    public static func activeLine(in lines: [SyncedLyricLine], at position: TimeInterval) -> String? {
        guard !lines.isEmpty else { return nil }
        var current: String?
        for line in lines {
            if line.time <= position + 0.15 {
                current = line.text
            } else {
                break
            }
        }
        return current
    }
}
