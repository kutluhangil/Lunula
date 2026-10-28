import Foundation
import Testing

@testable import IslandCore

@Suite private struct CustomActivityRegistryTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    func req(_ id: String, duration: TimeInterval? = nil) -> CustomActivityRequest {
        .init(id: id, title: id, subtitle: nil, symbol: nil, accent: nil, progress: nil, duration: duration)
    }
    @Test func fourthCustomActivityEvictsOldest() {
        var r = CustomActivityRegistry()
        for (i, id) in ["a", "b", "c", "d"].enumerated() { r.upsert(req(id), now: now.addingTimeInterval(Double(i))) }
        #expect(r.activities.map(\.id.rawValue).sorted() == ["b", "c", "d"])
    }
    @Test func customActivityLivesAtMost8Hours() {
        var r = CustomActivityRegistry()
        let a = r.upsert(req("a"), now: now)
        #expect(a.expiresAt == now.addingTimeInterval(28_800))
        r.removeExpired(now: now.addingTimeInterval(28_801))
        #expect(r.activities.isEmpty)
    }
    @Test func updateKeepsStartedAtAndCapsLifetime() {
        var r = CustomActivityRegistry()
        r.upsert(req("a"), now: now)
        let u = r.upsert(req("a", duration: 28_800), now: now.addingTimeInterval(3600))
        #expect(u.startedAt == now && u.expiresAt == now.addingTimeInterval(28_800))
    }
    @Test func reShowAfterExpiryStartsFresh() {
        var r = CustomActivityRegistry()
        r.upsert(req("a"), now: now)
        let u = r.upsert(req("a"), now: now.addingTimeInterval(32_400))
        #expect(u.startedAt == now.addingTimeInterval(32_400))
        #expect(u.expiresAt! > now.addingTimeInterval(32_400))
    }
    @Test func endRemovesById() {
        var r = CustomActivityRegistry()
        r.upsert(req("a"), now: now)
        #expect(r.end(id: "a") && r.activities.isEmpty)
    }
}
