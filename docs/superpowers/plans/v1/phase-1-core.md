# Faz 1 — Çekirdek mantık (`IslandCore`, Core Engineer)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §3.3–§3.5, §5, §6.5
> Kural: bu paket yalnızca `Foundation` ve `Observation` import eder; tüm testler Linux'ta da (`core-linux` CI işi) geçer. Zaman değeri gerektiren saf fonksiyonlar `now: Date` parametresi alır.
> Komut kalıbı: `swift test --package-path Packages/IslandCore --filter <SuiteAdı>`
> T1.1 önce biter; T1.2–T1.10 birbirinden bağımsızdır ve paralel worktree'lerde yürütülebilir.

---

### T1.1 Temel modeller ve zaman

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Model/{ActivityID,Activity,ActivityContent,Snapshots,TransientAlert,RGBAColor}.swift`
- Create: `Packages/IslandCore/Sources/IslandCore/Time/{IslandTime,SystemTime}.swift`
- Create: `Packages/IslandCore/Sources/IslandCoreTestSupport/{ManualTime,Fixtures}.swift` (T0.1'deki boş `TestSupport.swift`'i siler)
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Model/{ActivityModelTests,RGBAColorTests,NowPlayingSnapshotTests}.swift`, `Time/ManualTimeTests.swift`

**Interfaces:**
- Produces (tümü `public`, `Sendable`; aksi belirtilmedikçe `Equatable`):
  - `struct ActivityID: Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible { let rawValue: String; init(_ rawValue: String) }`
  - `enum ActivityKind: String, Codable, CaseIterable { nowPlaying, timer, calendar, custom }`
  - `enum ActivityPriority: Int, Codable, Comparable, CaseIterable { ambient, normal, high, critical }`
  - `struct Activity: Identifiable { id: ActivityID; priority: ActivityPriority; startedAt: Date; updatedAt: Date; expiresAt: Date?; content: ActivityContent; accent: RGBAColor?; var kind: ActivityKind { content.kind } }`
  - `enum ActivityContent { nowPlaying(NowPlayingSnapshot), timer(TimerSnapshot), calendar(EventSnapshot), custom(CustomActivitySnapshot); var kind: ActivityKind }`
  - `enum MediaSourceID: String, Codable { music, spotify }`
  - `struct NowPlayingSnapshot { source: MediaSourceID; trackID: String; title: String; artist: String; album: String?; artworkKey: String?; duration: TimeInterval?; position: TimeInterval; positionTimestamp: Date; isPlaying: Bool; func position(at now: Date) -> TimeInterval }`
  - `enum TimerPhase: String, Codable { simple, focus, shortBreak, longBreak }`
  - `struct TimerSnapshot { timerID: ActivityID; label: String?; phase: TimerPhase; duration: TimeInterval; endsAt: Date?; pausedRemaining: TimeInterval?; cycle: Int?; totalCycles: Int? }` (`endsAt == nil` ⇔ duraklatılmış)
  - `enum MeetingService: String, Codable { zoom, googleMeet, teams, facetime, webex }`, `struct MeetingLink { service: MeetingService; url: URL }`
  - `struct EventSnapshot { eventID: String; title: String; start: Date; end: Date; isAllDay: Bool; calendarColor: RGBAColor?; location: String?; meetingLink: MeetingLink? }`
  - `struct CustomActivitySnapshot { title: String; subtitle: String?; symbol: String?; progress: Double?; endsAt: Date? }`
  - `struct BatterySnapshot { level: Int; isCharging: Bool; isPluggedIn: Bool; isCharged: Bool; isLowPowerMode: Bool; hasBattery: Bool }`
  - `struct PrivacySnapshot { cameraInUse: Bool; microphoneInUse: Bool; static let none }`
  - `enum WeatherCondition: String, Codable, CaseIterable { clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, thunderstorm }`
  - `struct WeatherSnapshot: Codable { temperatureC: Double; highC: Double; lowC: Double; condition: WeatherCondition; isDaylight: Bool; sunrise: Date?; sunset: Date?; placeName: String?; fetchedAt: Date }`
  - `enum SignalTint: Hashable { accent(RGBAColor), green, orange, red, neutral }`
  - `enum AlertKind: String, CaseIterable { charging, unplugged, batteryLow, batteryFull, downloadFinished, timerFinished, trackChanged, permissionNeeded, custom }`
  - `enum AlertDetail: Hashable { batteryLevel(Int), file(name: String, url: URL), track(title: String, artist: String, artworkKey: String?), timer(label: String?, phase: TimerPhase), permission(MediaSourceID), text(title: String, subtitle: String?, symbol: String?) }` — Core'da yerelleştirilmiş metin **yok**; görünümler `kind` + `detail`'den metin üretir.
  - `struct TransientAlert: Identifiable, Hashable { id: UUID; kind: AlertKind; detail: AlertDetail; tint: SignalTint; duration: TimeInterval; priority: ActivityPriority }`
  - `struct RGBAColor: Hashable, Codable { red, green, blue, alpha: Double /* 0...1 */; init(red:green:blue:alpha: = 1); init?(hex: String); var hexString: String }`
  - `@MainActor protocol IslandTime: AnyObject { var now: Date { get }; @discardableResult func schedule(after delay: TimeInterval, _ action: @escaping @MainActor () -> Void) -> ScheduledToken }`
  - `@MainActor final class ScheduledToken { init(onCancel: @escaping @MainActor () -> Void); func cancel(); private(set) var isCancelled: Bool }`
  - `@MainActor final class SystemTime: IslandTime` — `Task.sleep(for: .seconds(delay), tolerance: .seconds(max(0.01, delay * 0.1)))` (enerji için tolerans).
  - `IslandCoreTestSupport`: `@MainActor final class ManualTime: IslandTime { init(start: Date = Date(timeIntervalSinceReferenceDate: 800_000_000)); func advance(by seconds: TimeInterval) }` ve `Activity.fixture(...)`, `NowPlayingSnapshot.fixture(...)`, `EventSnapshot.fixture(...)`, `TransientAlert.fixture(...)`, `WeatherSnapshot.fixture(...)` (tüm parametreler varsayılanlı).

- [ ] **Step 1: Başarısız testleri yaz**

```swift
@Suite struct ActivityModelTests {
    @Test func kindDerivesFromContent() {
        #expect(Activity.fixture(content: .nowPlaying(.fixture())).kind == .nowPlaying)
        #expect(Activity.fixture(content: .custom(.init(title: "x", subtitle: nil, symbol: nil, progress: nil, endsAt: nil))).kind == .custom)
    }
    @Test func priorityOrderIsAmbientNormalHighCritical() {
        #expect(ActivityPriority.allCases.sorted() == [.ambient, .normal, .high, .critical])
    }
}

@Suite struct RGBAColorTests {
    @Test func parsesHexWithAndWithoutHash() {
        let orange = RGBAColor(red: 1, green: 128.0 / 255, blue: 0)
        #expect(RGBAColor(hex: "#FF8000") == orange)
        #expect(RGBAColor(hex: "ff8000") == orange)
        #expect(RGBAColor(hex: "XYZ") == nil)
        #expect(orange.hexString == "#FF8000")
    }
}

@Suite struct NowPlayingSnapshotTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    @Test func positionInterpolatesWhilePlaying() {
        let s = NowPlayingSnapshot.fixture(duration: 200, position: 10, positionTimestamp: t0, isPlaying: true)
        #expect(s.position(at: t0.addingTimeInterval(5)) == 15)
    }
    @Test func positionFrozenWhenPaused() {
        let s = NowPlayingSnapshot.fixture(duration: 200, position: 10, positionTimestamp: t0, isPlaying: false)
        #expect(s.position(at: t0.addingTimeInterval(5)) == 10)
    }
    @Test func positionClampsToDuration() {
        let s = NowPlayingSnapshot.fixture(duration: 12, position: 10, positionTimestamp: t0, isPlaying: true)
        #expect(s.position(at: t0.addingTimeInterval(5)) == 12)
    }
}

@MainActor @Suite struct ManualTimeTests {
    @Test func advanceFiresDueActionsInDeadlineOrder() {
        let time = ManualTime(); var log: [String] = []
        time.schedule(after: 2) { log.append("b") }
        time.schedule(after: 1) { log.append("a") }
        time.schedule(after: 5) { log.append("c") }
        time.advance(by: 3)
        #expect(log == ["a", "b"])
    }
    @Test func cancelledTokenDoesNotFire() {
        let time = ManualTime(); var fired = false
        let token = time.schedule(after: 1) { fired = true }
        token.cancel(); time.advance(by: 2)
        #expect(!fired && token.isCancelled)
    }
    @Test func actionScheduledDuringAdvanceFiresIfDue() {
        let time = ManualTime(); var log: [String] = []
        time.schedule(after: 1) { log.append("a"); time.schedule(after: 1) { log.append("b") } }
        time.advance(by: 3)
        #expect(log == ["a", "b"])
    }
}
```

- [ ] **Step 2: Çalıştır, başarısızlığı gör**
Run: `swift test --package-path Packages/IslandCore --filter "ActivityModelTests|RGBAColorTests|NowPlayingSnapshotTests|ManualTimeTests"`
Expected: FAIL — `cannot find 'Activity' in scope`.

- [ ] **Step 3: Türleri Interfaces bloğundaki imzalarla uygula**
`ManualTime.advance`: bitiş anı ≤ yeni `now` olan eylemleri bitiş anı sırasına göre (eşitlikte planlanma sırasına göre) çalıştırır, her eylemden önce `now`'u o eylemin bitiş anına ayarlar; çalışma sırasında planlanıp pencereye düşenler de çalışır. `position(at:)`: oynuyorsa `position + (now − positionTimestamp)`, `0...duration` aralığına sıkıştırılır (süre yoksa üst sınır yok).

- [ ] **Step 4: Çalıştır, geçtiğini gör** — aynı komut, Expected: PASS (9 test).

- [ ] **Step 5: Commit**
```bash
git add Packages/IslandCore
git commit -m "feat(core): add activity models, snapshots, alerts, colors and injectable time"
```

---

### T1.2 Notch geometrisi, ada ölçüleri ve ekran seçimi

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Geometry/{ScreenDescriptor,NotchGeometry,IslandMetrics,DisplaySelection}.swift`
- Create: `Packages/IslandCore/Sources/IslandCoreTestSupport/ScreenFixtures.swift` — aşağıdaki iki sabit `public extension ScreenDescriptor { static let mbp14, external }` olarak burada yaşar (Faz 3 testleri de kullanır)
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Geometry/{NotchGeometryTests,IslandMetricsTests,DisplaySelectionTests}.swift`

**Interfaces:**
- Consumes: yok (T1.1'den bağımsız).
- Produces (koordinatlar **AppKit global**: orijin sol alt, y yukarı doğru artar):
  - `struct ScreenDescriptor: Equatable, Sendable` (tüm alanlar `var`) `{ id: UInt32; frame: CGRect; visibleFrame: CGRect; safeAreaTop: CGFloat; auxiliaryTopLeft: CGRect?; auxiliaryTopRight: CGRect?; menuBarHeight: CGFloat; isBuiltIn: Bool; isMain: Bool; localizedName: String }`
  - `struct NotchMetrics: Equatable, Sendable { rect: CGRect; hasHardwareNotch: Bool; var size: CGSize }`
  - `enum NotchGeometry { static let pillBaseWidth: CGFloat = 180; static func metrics(for screen: ScreenDescriptor) -> NotchMetrics }` — donanım notch'u varsa ondan, yoksa hap.
  - `enum IslandSizeRequest: Equatable, Sendable { idle, invite, compact(wing: CGFloat), peek, expanded(width: CGFloat, bodyHeight: CGFloat) }` — `invite`: etkinlik yokken hover'daki "nefes" daveti, her yana +8 pt (spec §4.4).
  - `enum IslandMetrics { static let wingMax: CGFloat = 64; static let peekWing: CGFloat = 72; static let peekMinWidth: CGFloat = 340; static let peekExtraHeight: CGFloat = 30; static let expandedWidthRange: ClosedRange<CGFloat> = 520...600; static let expandedBodyRange: ClosedRange<CGFloat> = 128...176; static let bubbleGap: CGFloat = 8; static let panelSize = CGSize(width: 760, height: 300); static func size(for: IslandSizeRequest, notch: NotchMetrics) -> CGSize; static func islandRect(size: CGSize, notch: NotchMetrics) -> CGRect; static func bubbleRect(index: Int, primary: CGRect, notch: NotchMetrics) -> CGRect; static func hotZone(around rect: CGRect) -> CGRect; static func panelFrame(notch: NotchMetrics, screen: ScreenDescriptor) -> CGRect }`
  - `enum DisplayMode: String, Codable, Sendable, CaseIterable { notchedOnly, allDisplays, mainDisplay }` ve `enum DisplaySelection { static func screens(from: [ScreenDescriptor], mode: DisplayMode) -> [ScreenDescriptor] }`

- [ ] **Step 1: Başarısız testleri yaz** (fikstür değerleri örnekleyicidir; gerçek cihaz değerleri T9.6'da kaydedilip fikstürlere eklenir)

```swift
// IslandCoreTestSupport/ScreenFixtures.swift → static let mbp14 / external; test dosyası: let mbp14 = ScreenDescriptor.mbp14, external = ScreenDescriptor.external
let mbp14 = ScreenDescriptor(id: 1, frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
    visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 950), safeAreaTop: 32,
    auxiliaryTopLeft: CGRect(x: 0, y: 950, width: 662, height: 32),
    auxiliaryTopRight: CGRect(x: 850, y: 950, width: 662, height: 32),
    menuBarHeight: 32, isBuiltIn: true, isMain: true, localizedName: "Built-in Retina Display")
let external = ScreenDescriptor(id: 2, frame: CGRect(x: 1512, y: 0, width: 2560, height: 1440),
    visibleFrame: CGRect(x: 1512, y: 0, width: 2560, height: 1416), safeAreaTop: 0,
    auxiliaryTopLeft: nil, auxiliaryTopRight: nil, menuBarHeight: 24, isBuiltIn: false, isMain: false, localizedName: "LG")

@Suite struct NotchGeometryTests {
    @Test func notchWidthIsFrameMinusAuxiliaryAreas() {
        let m = NotchGeometry.metrics(for: mbp14)
        #expect(m.hasHardwareNotch)
        #expect(m.rect == CGRect(x: 662, y: 950, width: 188, height: 32))
    }
    @Test func missingAuxiliaryAreasMeansPillMode() {
        #expect(!NotchGeometry.metrics(for: external).hasHardwareNotch)
    }
    @Test(arguments: [(24.0, 22.0), (33.0, 27.0), (37.0, 30.0)])
    func pillHeightIsMenuBarMinus6ClampedTo22through30(menuBar: Double, expected: Double) {
        var s = external; s.menuBarHeight = menuBar
        #expect(NotchGeometry.metrics(for: s).rect.height == expected)
    }
    @Test func pillIsCenteredInMenuBarBand() {
        let r = NotchGeometry.metrics(for: external).rect   // menüBar 24, yükseklik 22
        #expect(r.midX == external.frame.midX)
        #expect(r.width == NotchGeometry.pillBaseWidth)
        #expect(r.maxY == external.frame.maxY - 1)           // (24 − 22) / 2
    }
}

@Suite struct IslandMetricsTests {
    let notch = NotchGeometry.metrics(for: mbp14)            // 188 × 32
    @Test func idleSizeEqualsNotch() { #expect(IslandMetrics.size(for: .idle, notch: notch) == CGSize(width: 188, height: 32)) }
    @Test func inviteAdds8ptPerSide() { #expect(IslandMetrics.size(for: .invite, notch: notch) == CGSize(width: 204, height: 32)) }
    @Test func compactWingClampedTo64() { #expect(IslandMetrics.size(for: .compact(wing: 80), notch: notch).width == 188 + 128) }
    @Test func peekHasMinimumWidth340() {
        #expect(IslandMetrics.size(for: .peek, notch: notch) == CGSize(width: 340, height: 62))
    }
    @Test func expandedWidthAndBodyAreClamped() {
        #expect(IslandMetrics.size(for: .expanded(width: 500, bodyHeight: 100), notch: notch) == CGSize(width: 520, height: 32 + 128))
        #expect(IslandMetrics.size(for: .expanded(width: 700, bodyHeight: 300), notch: notch) == CGSize(width: 600, height: 32 + 176))
    }
    @Test func islandRectIsTopAlignedAndCenteredOnNotch() {
        let r = IslandMetrics.islandRect(size: CGSize(width: 340, height: 62), notch: notch)
        #expect(r.midX == notch.rect.midX && r.maxY == notch.rect.maxY)
    }
    @Test func bubblesSitRightOfPrimaryWith8ptGap() {
        let primary = CGRect(x: 600, y: 950, width: 300, height: 32)
        #expect(IslandMetrics.bubbleRect(index: 0, primary: primary, notch: notch) == CGRect(x: 908, y: 950, width: 32, height: 32))
        #expect(IslandMetrics.bubbleRect(index: 1, primary: primary, notch: notch) == CGRect(x: 948, y: 950, width: 32, height: 32))
    }
    @Test func hotZoneExpands10HorizontallyAnd6Down() {
        #expect(IslandMetrics.hotZone(around: CGRect(x: 100, y: 950, width: 188, height: 32)) == CGRect(x: 90, y: 944, width: 208, height: 38))
    }
    @Test func panelFrameIs760x300TopCenteredAndInsideScreen() {
        let f = IslandMetrics.panelFrame(notch: notch, screen: mbp14)
        #expect(f.size == CGSize(width: 760, height: 300) && f.midX == notch.rect.midX && f.maxY == mbp14.frame.maxY)
        #expect(mbp14.frame.contains(f))
    }
}

@Suite struct DisplaySelectionTests {
    @Test func notchedOnlySelectsNotchedScreen() { #expect(DisplaySelection.screens(from: [mbp14, external], mode: .notchedOnly).map(\.id) == [1]) }
    @Test func notchedOnlyFallsBackToMainWhenNoNotchedScreen() {
        var ext = external; ext.isMain = true
        #expect(DisplaySelection.screens(from: [ext], mode: .notchedOnly).map(\.id) == [2])
    }
    @Test func allDisplaysSelectsEvery() { #expect(DisplaySelection.screens(from: [mbp14, external], mode: .allDisplays).count == 2) }
    @Test func mainDisplaySelectsMain() { #expect(DisplaySelection.screens(from: [mbp14, external], mode: .mainDisplay).map(\.id) == [1]) }
}
```

- [ ] **Step 2: Çalıştır** — `swift test --package-path Packages/IslandCore --filter "NotchGeometryTests|IslandMetricsTests|DisplaySelectionTests"` → FAIL (`cannot find 'ScreenDescriptor'`).
- [ ] **Step 3: Uygula.** Notch: `rect.x = auxiliaryTopLeft.maxX`, genişlik = `frame.width − left.width − right.width`, yükseklik = `safeAreaTop`, `rect.maxY = frame.maxY`. Hap: yükseklik `min(max(menuBarHeight − 6, 22), 30)`, `rect.maxY = frame.maxY − (menuBarHeight − height) / 2`. `panelFrame`: yatayda ekran içine sıkıştırılır. `islandRect`: `midX = notch.rect.midX`, `maxY = notch.rect.maxY`.
- [ ] **Step 4: Çalıştır** — Expected: PASS (19 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): notch geometry, island size classes and display selection"`

---

### T1.3 Etkinlik zamanlayıcısı ve öncelik kuralları

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Scheduling/{IslandLayout,ActivityScheduler,ActivityPriorityRules}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Scheduling/{ActivitySchedulerTests,ActivityPriorityRulesTests}.swift`

**Interfaces:**
- Consumes: T1.1 `Activity`, `ActivityContent`, `ActivityPriority`.
- Produces:
  - `struct IslandLayout: Equatable, Sendable { primary: Activity?; detached: [Activity]; overflowCount: Int; static let empty; func contains(_ id: ActivityID) -> Bool }`
  - `enum ActivityScheduler { static func layout(for: [Activity], now: Date, capacity: Int = 3) -> IslandLayout }`
  - `enum ActivityPriorityRules { static func priority(for: ActivityContent, now: Date) -> ActivityPriority; static func nextChange(for: ActivityContent, now: Date) -> Date? }`

Kurallar (spec §3.5): müzik çalıyor `normal`, duraklatılmış `ambient` · zamanlayıcı: duraklatılmış `ambient`, kalan > 60 sn `normal`, ≤ 60 sn `high`, ≤ 0 `critical` · takvim: `[start−60, start+60)` aralığında `critical`, aksi hâlde `high` (takvim etkinliği yalnızca `[start−600, start+300)` penceresinde var olur; pencereyi servis uygular) · özel: `normal`. `nextChange`: içerik için `now`'dan büyük ilk sınır — zamanlayıcıda `endsAt−60`, `endsAt`; takvimde `start−60`, `start+60`, `start+300`; diğerlerinde `nil`.

- [ ] **Step 1: Testler**

```swift
@Suite struct ActivitySchedulerTests {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    @Test func expiredActivitiesAreDropped() {
        let a = Activity.fixture(id: "a", expiresAt: now.addingTimeInterval(-1))
        #expect(ActivityScheduler.layout(for: [a], now: now) == .empty)
    }
    @Test func higherPriorityIsPrimary() {
        let low = Activity.fixture(id: "low", priority: .normal), high = Activity.fixture(id: "high", priority: .critical)
        #expect(ActivityScheduler.layout(for: [low, high], now: now).primary?.id == "high")
    }
    @Test func tieBrokenByMostRecentUpdate() {
        let old = Activity.fixture(id: "old", priority: .normal, updatedAt: now.addingTimeInterval(-10))
        let new = Activity.fixture(id: "new", priority: .normal, updatedAt: now)
        #expect(ActivityScheduler.layout(for: [old, new], now: now).primary?.id == "new")
    }
    @Test func atMostTwoDetachedAndOverflowCounted() {
        let items = (0..<5).map { Activity.fixture(id: ActivityID("\($0)"), updatedAt: now.addingTimeInterval(Double($0))) }
        let l = ActivityScheduler.layout(for: items, now: now)
        #expect(l.primary?.id == "4" && l.detached.map(\.id) == ["3", "2"] && l.overflowCount == 2)
    }
}

@Suite struct ActivityPriorityRulesTests {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    func meeting(startsIn s: TimeInterval) -> ActivityContent { .calendar(.fixture(start: now.addingTimeInterval(s))) }
    func timer(endsIn s: TimeInterval?) -> ActivityContent {
        .timer(.init(timerID: "t", label: nil, phase: .simple, duration: 1500, endsAt: s.map { now.addingTimeInterval($0) },
                     pausedRemaining: s == nil ? 100 : nil, cycle: nil, totalCycles: nil))
    }
    @Test func meetingWithin10MinIsHighAndWithin1MinIsCritical() {
        #expect(ActivityPriorityRules.priority(for: meeting(startsIn: 300), now: now) == .high)
        #expect(ActivityPriorityRules.priority(for: meeting(startsIn: 30), now: now) == .critical)
    }
    @Test func timerPriorities() {
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: 600), now: now) == .normal)
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: 45), now: now) == .high)
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: 0), now: now) == .critical)
        #expect(ActivityPriorityRules.priority(for: timer(endsIn: nil), now: now) == .ambient)
    }
    @Test func pausedMusicIsAmbient() {
        #expect(ActivityPriorityRules.priority(for: .nowPlaying(.fixture(isPlaying: false)), now: now) == .ambient)
    }
    @Test func nextChangeForMeetingIsOneMinuteBeforeStart() {
        #expect(ActivityPriorityRules.nextChange(for: meeting(startsIn: 300), now: now) == now.addingTimeInterval(240))
    }
    @Test func nextChangeForTimerIsLastMinuteThenEnd() {
        #expect(ActivityPriorityRules.nextChange(for: timer(endsIn: 600), now: now) == now.addingTimeInterval(540))
        #expect(ActivityPriorityRules.nextChange(for: timer(endsIn: 30), now: now) == now.addingTimeInterval(30))
    }
}
```

- [ ] **Step 2: Çalıştır** — `--filter "ActivitySchedulerTests|ActivityPriorityRulesTests"` → FAIL.
- [ ] **Step 3: Uygula** (sıralama: öncelik azalan, sonra `updatedAt` azalan, sonra `id` artan — kararlılık için).
- [ ] **Step 4: Çalıştır** → PASS (9 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): activity scheduler and priority rules"`

---

### T1.4 Ada durum makinesi (indirgeyici)

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/State/{IslandState,IslandEvent,IslandEffect,IslandReducer,IslandTiming}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/State/IslandReducerTests.swift`

**Interfaces:**
- Consumes: T1.1 `TransientAlert`, `ActivityID`, `ActivityPriority`; T1.3 `IslandLayout`.
- Produces:
  - `enum IslandPage: Hashable, Sendable { home, shelf, activity(ActivityID) }`
  - `enum IslandPhase: Hashable, Sendable { hidden, idle, compact, peek, expanded(IslandPage), transient(TransientAlert); var isOpen: Bool /* peek|expanded */ }`
  - `enum IslandHitTarget: Hashable, Sendable { island, bubble(ActivityID) }`
  - `struct IslandOptions: Equatable, Sendable { var hideInFullscreen = true; var criticalAlertsInFullscreen = true }`
  - `struct IslandState: Equatable, Sendable { var phase: IslandPhase = .idle; var layout: IslandLayout = .empty; var isFullscreen = false; var pointerInside = false; var pendingAlerts: [TransientAlert] = []; var options = IslandOptions(); var restingPhase: IslandPhase }`
  - `enum IslandEvent: Equatable, Sendable { pointerEnteredHotZone, pointerDwellElapsed(speed: Double), pointerExitedIsland, exitGraceElapsed, clicked(IslandHitTarget), swipedDown, swipedUp, escapePressed, clickedOutside, toggleRequested, pageSelected(IslandPage), fileDragApproached, fileDragLeft, activitiesChanged(IslandLayout), alertRaised(TransientAlert), alertExpired, fullscreenChanged(Bool), displayConfigurationChanged, systemWillSleep, systemDidWake, optionsChanged(IslandOptions) }`
  - `enum IslandTimer: Hashable, Sendable { dwell, exitGrace, alertExpiry }`; `enum HapticKind: Hashable, Sendable { alignment, levelChange, generic }`; `enum SoundKind: Hashable, Sendable { timerFinished }`
  - `enum IslandEffect: Hashable, Sendable { schedule(IslandTimer, after: TimeInterval), cancel(IslandTimer), playHaptic(HapticKind), playSound(SoundKind), makePanelKey(Bool), setMouseEventsIgnored(Bool) }` — **aynı türde bir zamanlayıcıyı yeniden planlamak eskisini değiştirir** (yürütücü sözleşmesi, T3.4).
  - `struct IslandTransition: Equatable, Sendable { var state: IslandState; var effects: [IslandEffect] }`
  - `enum IslandReducer { static func reduce(_ state: IslandState, _ event: IslandEvent) -> IslandTransition }`
  - `enum IslandTiming { static let dwell: TimeInterval = 0.100; static let exitGrace: TimeInterval = 0.250; static let maxPeekSpeed: Double = 1200; static let fullscreenCriticalAlert: TimeInterval = 2.0; static let maxQueuedAlerts = 3 }`

**Bağlayıcı geçiş tablosu.** Tanımlar: `resting(s)` = `s.isFullscreen && s.options.hideInFullscreen ? .hidden : (s.layout.primary == nil ? .idle : .compact)`. `collapse(s)` = bekleyen uyarı varsa ilkini çıkar → `transient(a)` + `schedule(.alertExpiry, a.duration)` + (`a.kind == .timerFinished` ise `playSound(.timerFinished)`) + `setMouseEventsIgnored(false)`; yoksa `resting(s)` + `setMouseEventsIgnored(true)` + `makePanelKey(false)`. `show(a)` = `transient(a)` + `cancel(.dwell)` + `schedule(.alertExpiry, a.duration)` + `setMouseEventsIgnored(false)` (+ zamanlayıcı bitişinde ses). `enqueue(a)` = sona ekle; sayı > 3 ise en düşük öncelikli en eski uyarıyı at. Testler efektleri **küme** olarak karşılaştırır (sıra önemsiz).

| Olay | Kaynak faz | Yeni durum | Efektler |
|---|---|---|---|
| `pointerEnteredHotZone` | idle, compact | `pointerInside = true` | `schedule(.dwell, 0.1)` |
| | peek, expanded, transient | `pointerInside = true` | `cancel(.exitGrace)` |
| `pointerDwellElapsed(v)` | idle, compact ve `pointerInside` | `v < 1200` → `peek`; değilse aynı | `setMouseEventsIgnored(false)`; değilse `schedule(.dwell, 0.1)` |
| `pointerExitedIsland` | idle, compact | `pointerInside = false` | `cancel(.dwell)` |
| | peek, expanded | `pointerInside = false` | `schedule(.exitGrace, 0.25)` |
| `exitGraceElapsed` | peek, expanded ve `!pointerInside` | `collapse` | `collapse` efektleri |
| `clicked(.island)` / `clicked(.bubble(id))` | idle, compact, peek, transient | `expanded(.home)` / `expanded(.activity(id))` | `cancel(.dwell)`, `cancel(.alertExpiry)`, `playHaptic(.alignment)`, `setMouseEventsIgnored(false)` |
| `swipedDown` | idle, compact, peek | `expanded(.home)` | `cancel(.dwell)`, `setMouseEventsIgnored(false)` |
| `swipedUp`, `escapePressed`, `clickedOutside` | peek, expanded | `collapse` | `cancel(.exitGrace)` + `collapse` efektleri |
| `escapePressed` | transient | `collapse` | `cancel(.alertExpiry)` + `collapse` efektleri |
| `toggleRequested` | expanded | `collapse` | `collapse` efektleri |
| | idle, compact, peek, transient | `expanded(.home)` | `cancel(.dwell)`, `cancel(.alertExpiry)`, `setMouseEventsIgnored(false)`, `makePanelKey(true)` |
| `pageSelected(p)` | expanded | `expanded(p)` | — |
| `fileDragApproached` | hidden dışı | `expanded(.shelf)`; transient ise uyarı kuyruğun **başına** | `cancel(.dwell)`, `cancel(.exitGrace)`, `cancel(.alertExpiry)`, `setMouseEventsIgnored(false)` |
| `fileDragLeft` | `expanded(.shelf)` ve `!pointerInside` | `collapse` | `collapse` efektleri |
| `activitiesChanged(l)` | her biri | `layout = l`; idle/compact → `resting`; `expanded(.activity(id))` ve `!l.contains(id)` → `expanded(.home)` | — |
| `alertRaised(a)` | idle, compact, peek | `show(a)` | `show` efektleri |
| | expanded | `enqueue(a)` | zamanlayıcı bitişiyse `playSound(.timerFinished)` |
| | transient(c) | `a.priority > c.priority` → `show(a)`, `c` kuyruğun başına; değilse `enqueue(a)` | `show` efektleri / — |
| | hidden | `a.priority == .critical && criticalAlertsInFullscreen` → `transient(a)`, süre 2.0 | `schedule(.alertExpiry, 2.0)` (+ ses); değilse yok sayılır |
| `alertExpired` | transient | `collapse` | `collapse` efektleri |
| `fullscreenChanged(true)` | hidden dışı ve `hideInFullscreen` | `isFullscreen = true`, `hidden` | üç zamanlayıcının `cancel`'ı, `setMouseEventsIgnored(true)`, `makePanelKey(false)` |
| `fullscreenChanged(false)` | hidden | `isFullscreen = false`, `resting` | — |
| `displayConfigurationChanged`, `systemWillSleep` | her biri | `pointerInside = false`, `resting` (kuyruk korunur) | üç `cancel`, `setMouseEventsIgnored(true)`, `makePanelKey(false)` |
| `systemDidWake` | her biri | `pointerInside = false`, `collapse` | `collapse` efektleri |
| `optionsChanged(o)` | her biri | `options = o`; fullscreen ve `!o.hideInFullscreen` ise `hidden` → `resting` | — |

Tabloda olmayan (olay, faz) çiftleri: durum ve efekt değişmez (`IslandTransition(state: s, effects: [])`).

- [ ] **Step 1: Testler** (yardımcı: `func run(_ s: IslandState, _ events: IslandEvent...) -> IslandTransition` olayları sırayla uygular, son geçişi döndürür; `let alert = TransientAlert.fixture(...)`)

```swift
@Suite struct IslandReducerTests {
    var compactState: IslandState { var s = IslandState(); s.layout = .init(primary: .fixture(), detached: [], overflowCount: 0); s.phase = .compact; return s }

    @Test func hoverDwellOpensPeek() {
        let entered = IslandReducer.reduce(IslandState(), .pointerEnteredHotZone)
        #expect(Set(entered.effects) == [.schedule(.dwell, after: 0.1)])
        let t = IslandReducer.reduce(entered.state, .pointerDwellElapsed(speed: 300))
        #expect(t.state.phase == .peek && Set(t.effects) == [.setMouseEventsIgnored(false)])
    }
    @Test func fastPointerDoesNotPeek() {
        let t = run(IslandState(), .pointerEnteredHotZone, .pointerDwellElapsed(speed: 1500))
        #expect(t.state.phase == .idle && Set(t.effects) == [.schedule(.dwell, after: 0.1)])
    }
    @Test func dwellAfterPointerLeftIsIgnored() {
        #expect(run(IslandState(), .pointerEnteredHotZone, .pointerExitedIsland, .pointerDwellElapsed(speed: 100)).state.phase == .idle)
    }
    @Test func exitGraceCollapsesAfter250ms() {
        let exited = run(IslandState(), .pointerEnteredHotZone, .pointerDwellElapsed(speed: 0), .pointerExitedIsland)
        #expect(Set(exited.effects) == [.schedule(.exitGrace, after: 0.25)])
        let t = IslandReducer.reduce(exited.state, .exitGraceElapsed)
        #expect(t.state.phase == .idle && Set(t.effects) == [.setMouseEventsIgnored(true), .makePanelKey(false)])
    }
    @Test func reenterDuringExitGraceKeepsOpen() {
        let t = run(IslandState(), .pointerEnteredHotZone, .pointerDwellElapsed(speed: 0), .pointerExitedIsland, .pointerEnteredHotZone)
        #expect(Set(t.effects) == [.cancel(.exitGrace)])
        #expect(IslandReducer.reduce(t.state, .exitGraceElapsed).state.phase == .peek)
    }
    @Test func clickFromCompactExpandsHomeWithHaptic() {
        let t = IslandReducer.reduce(compactState, .clicked(.island))
        #expect(t.state.phase == .expanded(.home))
        #expect(Set(t.effects).isSuperset(of: [.playHaptic(.alignment), .setMouseEventsIgnored(false)]))
    }
    @Test func clickOnBubbleOpensThatActivity() {
        #expect(IslandReducer.reduce(compactState, .clicked(.bubble("b"))).state.phase == .expanded(.activity("b")))
    }
    @Test func escapeCollapsesToCompactWhenActivityExists() {
        #expect(run(compactState, .clicked(.island), .escapePressed).state.phase == .compact)
    }
    @Test func escapeCollapsesToIdleWhenNoActivity() {
        #expect(run(IslandState(), .toggleRequested, .escapePressed).state.phase == .idle)
    }
    @Test func fileDragOpensShelfAndLeavingCollapses() {
        let opened = IslandReducer.reduce(IslandState(), .fileDragApproached)
        #expect(opened.state.phase == .expanded(.shelf))
        #expect(IslandReducer.reduce(opened.state, .fileDragLeft).state.phase == .idle)
    }
    @Test func alertWhileExpandedIsQueuedAndShownOnCollapse() {
        let a = TransientAlert.fixture(kind: .charging, duration: 2.6)
        let queued = run(IslandState(), .toggleRequested, .alertRaised(a))
        #expect(queued.state.phase == .expanded(.home) && queued.state.pendingAlerts == [a])
        let t = IslandReducer.reduce(queued.state, .escapePressed)
        #expect(t.state.phase == .transient(a) && Set(t.effects).contains(.schedule(.alertExpiry, after: 2.6)))
    }
    @Test func higherPriorityAlertPreemptsCurrent() {
        let low = TransientAlert.fixture(priority: .normal), high = TransientAlert.fixture(priority: .critical)
        let t = run(IslandState(), .alertRaised(low), .alertRaised(high))
        #expect(t.state.phase == .transient(high) && t.state.pendingAlerts == [low])
    }
    @Test func alertQueueKeepsAtMostThree() {
        let alerts = (0..<5).map { _ in TransientAlert.fixture(priority: .normal) }
        var s = IslandReducer.reduce(IslandState(), .toggleRequested).state
        for a in alerts { s = IslandReducer.reduce(s, .alertRaised(a)).state }
        #expect(s.pendingAlerts == Array(alerts.suffix(3)))
    }
    @Test func timerFinishedAlertPlaysSound() {
        let t = IslandReducer.reduce(IslandState(), .alertRaised(.fixture(kind: .timerFinished, priority: .critical)))
        #expect(Set(t.effects).contains(.playSound(.timerFinished)))
    }
    @Test func fullscreenHidesIsland() {
        let t = IslandReducer.reduce(compactState, .fullscreenChanged(true))
        #expect(t.state.phase == .hidden && Set(t.effects).contains(.setMouseEventsIgnored(true)))
        #expect(IslandReducer.reduce(t.state, .fullscreenChanged(false)).state.phase == .compact)
    }
    @Test func criticalAlertShowsInFullscreenFor2Seconds() {
        let hidden = IslandReducer.reduce(IslandState(), .fullscreenChanged(true)).state
        let t = IslandReducer.reduce(hidden, .alertRaised(.fixture(priority: .critical, duration: 6)))
        #expect(Set(t.effects).contains(.schedule(.alertExpiry, after: 2.0)))
        #expect(IslandReducer.reduce(t.state, .alertExpired).state.phase == .hidden)
    }
    @Test func nonCriticalAlertDroppedInFullscreen() {
        let hidden = IslandReducer.reduce(IslandState(), .fullscreenChanged(true)).state
        #expect(IslandReducer.reduce(hidden, .alertRaised(.fixture(priority: .normal))).state.phase == .hidden)
    }
    @Test func activitiesChangedMovesIdleToCompactAndBack() {
        let layout = IslandLayout(primary: .fixture(), detached: [], overflowCount: 0)
        let s = IslandReducer.reduce(IslandState(), .activitiesChanged(layout)).state
        #expect(s.phase == .compact)
        #expect(IslandReducer.reduce(s, .activitiesChanged(.empty)).state.phase == .idle)
    }
    @Test func removedActivityPageFallsBackToHome() {
        let s = IslandReducer.reduce(compactState, .clicked(.bubble("gone"))).state
        #expect(IslandReducer.reduce(s, .activitiesChanged(.empty)).state.phase == .expanded(.home))
    }
    @Test func sleepCollapsesAndCancelsAllTimers() {
        let t = run(compactState, .clicked(.island), .systemWillSleep)
        #expect(t.state.phase == .compact)
        #expect(Set(t.effects).isSuperset(of: [.cancel(.dwell), .cancel(.exitGrace), .cancel(.alertExpiry)]))
    }
    @Test func wakeShowsAlertQueuedDuringSleep() {
        let a = TransientAlert.fixture(kind: .timerFinished, priority: .critical)
        let t = run(IslandState(), .toggleRequested, .alertRaised(a), .systemWillSleep, .systemDidWake)
        #expect(t.state.phase == .transient(a))
    }
    @Test func toggleOpensWithKeyFocusAndClosesWhenOpen() {
        let opened = IslandReducer.reduce(IslandState(), .toggleRequested)
        #expect(opened.state.phase == .expanded(.home) && Set(opened.effects).contains(.makePanelKey(true)))
        #expect(IslandReducer.reduce(opened.state, .toggleRequested).state.phase == .idle)
    }
}
```

- [ ] **Step 2: Çalıştır** — `--filter IslandReducerTests` → FAIL.
- [ ] **Step 3: Uygula** — tablo dışında karar yok; `reduce` saf, yan etkisiz, `now` almaz.
- [ ] **Step 4: Çalıştır** → PASS (22 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): island state machine with binding transition table"`

---

### T1.5 Biçimlendirme ve birim tercihleri

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Format/{IslandFormat,UnitPreferences}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Format/{IslandFormatTests,UnitPreferencesTests}.swift`

**Interfaces:**
- Produces:
  - `enum IslandFormat { static func countdown(_ remaining: TimeInterval) -> String /* yukarı yuvarlar */; static func trackTime(_ seconds: TimeInterval) -> String /* aşağı yuvarlar */; static func temperature(celsius: Double, unit: TemperatureUnit) -> String }`
  - `enum TemperatureUnit: String, Codable, Sendable { celsius, fahrenheit }`, `enum SpeedUnit: String, Codable, Sendable { kilometersPerHour, milesPerHour }`
  - `enum TemperatureUnitPreference: String, Codable, Sendable, CaseIterable { system, celsius, fahrenheit }`
  - `struct UnitChoice: Equatable, Sendable { temperature: TemperatureUnit; speed: SpeedUnit }`
  - `enum UnitPreferences { static func resolve(locale: Locale, systemTemperatureSetting: String?, override: TemperatureUnitPreference) -> UnitChoice }` — `systemTemperatureSetting`: uygulamanın `UserDefaults.standard.string(forKey: "AppleTemperatureUnit")` değeri ("Celsius"/"Fahrenheit"); öncelik: `override` > sistem ayarı > `locale.measurementSystem` (`.us` → °F/mph, `.uk` → °C/mph, diğerleri → °C/km/sa).

- [ ] **Step 1: Testler**

```swift
@Suite struct IslandFormatTests {
    @Test(arguments: [(65.0, "1:05"), (59.2, "1:00"), (3725.0, "1:02:05"), (-3.0, "0:00"), (0.4, "0:01")])
    func countdown(_ input: Double, _ expected: String) { #expect(IslandFormat.countdown(input) == expected) }
    @Test func trackTimeFloors() { #expect(IslandFormat.trackTime(187.9) == "3:07") }
    @Test func temperatureRoundsAndDropsNegativeZero() {
        #expect(IslandFormat.temperature(celsius: 21.5, unit: .celsius) == "22°")
        #expect(IslandFormat.temperature(celsius: -0.4, unit: .celsius) == "0°")
        #expect(IslandFormat.temperature(celsius: -3.2, unit: .celsius) == "-3°")
    }
    @Test func temperatureConvertsToFahrenheit() { #expect(IslandFormat.temperature(celsius: 20, unit: .fahrenheit) == "68°") }
}

@Suite struct UnitPreferencesTests {
    @Test func turkishLocaleUsesCelsiusAndKmh() {   // Review Focus #3
        let u = UnitPreferences.resolve(locale: Locale(identifier: "tr_TR"), systemTemperatureSetting: nil, override: .system)
        #expect(u == UnitChoice(temperature: .celsius, speed: .kilometersPerHour))
    }
    @Test func usLocaleUsesFahrenheitAndMph() {
        #expect(UnitPreferences.resolve(locale: Locale(identifier: "en_US"), systemTemperatureSetting: nil, override: .system)
                == UnitChoice(temperature: .fahrenheit, speed: .milesPerHour))
    }
    @Test func ukLocaleUsesCelsiusAndMph() {
        #expect(UnitPreferences.resolve(locale: Locale(identifier: "en_GB"), systemTemperatureSetting: nil, override: .system)
                == UnitChoice(temperature: .celsius, speed: .milesPerHour))
    }
    @Test func systemTemperatureSettingWinsOverLocale() {
        #expect(UnitPreferences.resolve(locale: Locale(identifier: "tr_TR"), systemTemperatureSetting: "Fahrenheit", override: .system).temperature == .fahrenheit)
    }
    @Test func explicitOverrideWinsOverEverything() {
        #expect(UnitPreferences.resolve(locale: Locale(identifier: "en_US"), systemTemperatureSetting: "Fahrenheit", override: .celsius).temperature == .celsius)
    }
}
```

- [ ] **Step 2–4:** `--filter "IslandFormatTests|UnitPreferencesTests"` → FAIL → uygula → PASS (13 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): countdown/temperature formatting and unit preferences"`

---

### T1.6 Toplantı bağlantısı algılama

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Calendar/MeetingLinkDetector.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Calendar/MeetingLinkDetectorTests.swift`

**Interfaces:**
- Consumes: T1.1 `MeetingLink`, `MeetingService`.
- Produces: `enum MeetingLinkDetector { static func detect(in fields: [String?]) -> MeetingLink? }` — alanlar sırayla taranır, ilk eşleşen döner. (Linux uyumu için `NSDataDetector` kullanılmaz: önce `https?://[^\s<>"']+` ve `zoommtg://[^\s<>"']+` ile aday bağlantılar çıkarılır, sondaki `).,;:!?>]` atılır, SafeLinks `url` parametresi yüzde-çözülerek açılır, sonra servis desenleri uygulanır.)

Desenler (büyük/küçük harf duyarsız): Zoom `^https?://([\w-]+\.)?zoom\.(us|com)/(j|w|my|s)/` veya `^zoommtg://` · Meet `^https?://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}` · Teams `^https?://teams\.(microsoft|live)\.com/(l/meetup-join|meet)/` · FaceTime `^https?://facetime\.apple\.com/join` · Webex `^https?://[\w-]+\.webex\.com/`.

- [ ] **Step 1: Testler**

```swift
@Suite struct MeetingLinkDetectorTests {
    @Test func detectsZoomInURLField() {
        let l = MeetingLinkDetector.detect(in: ["https://us02web.zoom.us/j/123456789?pwd=abc", nil])
        #expect(l?.service == .zoom && l?.url.absoluteString == "https://us02web.zoom.us/j/123456789?pwd=abc")
    }
    @Test func detectsMeetInNotes() {
        #expect(MeetingLinkDetector.detect(in: [nil, "Join: https://meet.google.com/abc-defg-hij\nThanks"])?.url.absoluteString
                == "https://meet.google.com/abc-defg-hij")
    }
    @Test func detectsTeamsInsideHTMLAnchor() {
        let notes = #"<a href="https://teams.microsoft.com/l/meetup-join/19%3ameeting_X%40thread.v2/0?context=%7b%7d">Join</a>"#
        #expect(MeetingLinkDetector.detect(in: [notes])?.url.absoluteString
                == "https://teams.microsoft.com/l/meetup-join/19%3ameeting_X%40thread.v2/0?context=%7b%7d")
    }
    @Test func firstFieldWins() {
        #expect(MeetingLinkDetector.detect(in: ["https://zoom.us/j/1", "https://meet.google.com/abc-defg-hij"])?.service == .zoom)
    }
    @Test func ignoresNonMeetingLinks() { #expect(MeetingLinkDetector.detect(in: ["https://example.com/j/123"]) == nil) }
    @Test func stripsTrailingPunctuation() {
        #expect(MeetingLinkDetector.detect(in: ["(https://meet.google.com/abc-defg-hij)."])?.url.absoluteString == "https://meet.google.com/abc-defg-hij")
    }
    @Test func unwrapsOutlookSafeLinks() {
        let s = "https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fzoom.us%2Fj%2F987&data=x"
        #expect(MeetingLinkDetector.detect(in: [s])?.url.absoluteString == "https://zoom.us/j/987")
    }
    @Test func detectsZoomAppSchemeFaceTimeAndWebex() {
        #expect(MeetingLinkDetector.detect(in: ["zoommtg://zoom.us/join?confno=123"])?.service == .zoom)
        #expect(MeetingLinkDetector.detect(in: ["https://facetime.apple.com/join#v=1&p=abc"])?.service == .facetime)
        #expect(MeetingLinkDetector.detect(in: ["https://acme.webex.com/meet/jane"])?.service == .webex)
    }
}
```

- [ ] **Step 2–4:** `--filter MeetingLinkDetectorTests` → FAIL → uygula → PASS (8 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): meeting link detection incl. SafeLinks"`

---

### T1.7 Geri sayım ve Pomodoro modeli

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Timer/{CountdownTimer,Pomodoro}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Timer/{CountdownTimerTests,PomodoroTests}.swift`

**Interfaces:**
- Consumes: T1.1 `ActivityID`, `TimerPhase`, `TimerSnapshot`.
- Produces:
  - `struct CountdownTimer: Equatable, Sendable, Codable { let id: ActivityID; var label: String?; let phase: TimerPhase; let duration: TimeInterval; private(set) var startedAt: Date; private(set) var pausedAt: Date?; private(set) var pausedTotal: TimeInterval; init(id:label:phase:duration:startedAt:); func remaining(at: Date) -> TimeInterval; func isFinished(at: Date) -> Bool; func endDate() -> Date? /* duraklatılmışsa nil */; mutating func pause(at: Date); mutating func resume(at: Date); func snapshot(at: Date, cycle: Int?, totalCycles: Int?) -> TimerSnapshot }`
  - `struct PomodoroPlan: Equatable, Sendable, Codable { var focus: TimeInterval = 1500; var shortBreak: TimeInterval = 300; var longBreak: TimeInterval = 900; var focusSessionsBeforeLongBreak = 4; static let standard }`
  - `struct PomodoroProgress: Equatable, Sendable, Codable { var phase: TimerPhase = .focus; var completedFocusSessions = 0; mutating func advance(plan: PomodoroPlan); func duration(plan: PomodoroPlan) -> TimeInterval }`

Kalan süre **duvar saatiyle** hesaplanır: `max(0, duration − (now − startedAt − pausedTotal − (pausedAt.map { now − $0 } ?? 0)))`. Uyku sırasında saat ilerlediği için sapma olmaz (spec §5.2).

- [ ] **Step 1: Testler**

```swift
@Suite struct CountdownTimerTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    func timer() -> CountdownTimer { CountdownTimer(id: "t", label: nil, phase: .simple, duration: 1500, startedAt: t0) }
    @Test func remainingUsesWallClockAcrossSleep() {   // Review Focus #5
        let t = timer()
        #expect(t.remaining(at: t0.addingTimeInterval(1800)) == 0)
        #expect(t.isFinished(at: t0.addingTimeInterval(1800)))
        #expect(t.endDate() == t0.addingTimeInterval(1500))
    }
    @Test func pauseFreezesRemaining() {
        var t = timer(); t.pause(at: t0.addingTimeInterval(100))
        #expect(t.remaining(at: t0.addingTimeInterval(900)) == 1400 && t.endDate() == nil)
    }
    @Test func resumeContinuesFromPausedValue() {
        var t = timer(); t.pause(at: t0.addingTimeInterval(100)); t.resume(at: t0.addingTimeInterval(400))
        #expect(t.remaining(at: t0.addingTimeInterval(500)) == 1300)
        #expect(t.endDate() == t0.addingTimeInterval(1800))
    }
}

@Suite struct PomodoroTests {
    @Test func standardPlanIs25_5_15x4() { #expect(PomodoroPlan.standard == PomodoroPlan(focus: 1500, shortBreak: 300, longBreak: 900, focusSessionsBeforeLongBreak: 4)) }
    @Test func focusLeadsToShortBreakAndBreakLeadsToFocus() {
        var p = PomodoroProgress(); p.advance(plan: .standard)
        #expect(p.phase == .shortBreak); p.advance(plan: .standard); #expect(p.phase == .focus)
    }
    @Test func fourthFocusLeadsToLongBreak() {
        var p = PomodoroProgress()
        for _ in 0..<7 { p.advance(plan: .standard) }      // F→S→F→S→F→S→F→L
        #expect(p.phase == .longBreak && p.completedFocusSessions == 4 && p.duration(plan: .standard) == 900)
    }
}
```

- [ ] **Step 2–4:** `--filter "CountdownTimerTests|PomodoroTests"` → FAIL → uygula → PASS (6 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): wall-clock countdown and pomodoro sequence"`

---

### T1.8 URL komutları, özel etkinlik kaydı ve hız sınırlayıcı

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Automation/{IslandURLCommand,IslandURLParser,CustomActivityRegistry,RateLimiter}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Automation/{IslandURLParserTests,CustomActivityRegistryTests,RateLimiterTests}.swift`

**Interfaces:**
- Consumes: T1.1 `Activity`, `ActivityID`, `CustomActivitySnapshot`, `RGBAColor`.
- Produces:
  - `struct CustomActivityRequest: Equatable, Sendable { id: String; title: String; subtitle: String?; symbol: String?; accent: RGBAColor?; progress: Double?; duration: TimeInterval? }` — App Intents (T8.2) da bunu üretir.
  - `enum IslandURLCommand: Equatable, Sendable { showActivity(CustomActivityRequest) /* ekle ya da güncelle */, endActivity(id: String), startTimer(minutes: Double), toggleIsland }`
  - `enum IslandURLError: Error, Equatable { wrongScheme, unknownCommand(String), missingParameter(String), invalidParameter(String), rateLimited }` (`rateLimited` yalnızca `URLRouter` tarafından üretilir, T8.1)
  - `enum CustomActivityLimits { static let maxIDLength = 64; static let maxTitleLength = 80; static let maxSubtitleLength = 120; static let maxLifetime: TimeInterval = 28_800; static let maxConcurrent = 3; static let timerMinutes: ClosedRange<Double> = 1...600 }`
  - `extension CustomActivityRequest { static func make(id: String?, title: String?, subtitle: String?, symbol: String?, accentHex: String?, progress: Double?, duration: Double?) -> Result<CustomActivityRequest, IslandURLError> }` — tüm doğrulama burada; ayrıştırıcı ve App Intents (T8.2) aynı fonksiyonu kullanır.
  - `enum IslandURLParser { static func parse(_ url: URL, expectedScheme: String = "nimbo") -> Result<IslandURLCommand, IslandURLError> }` — yollar: `activity/show`, `activity/end`, `timer/start`, `island/toggle`. `id` yalnızca `[A-Za-z0-9._-]`, en çok 64 (aşarsa `invalidParameter("id")`); başlık/alt başlık sınırı aşarsa **kısaltılır** (sonuna `…`); `progress` 0...1'e sıkıştırılır, NaN → `invalidParameter`; `duration` 1...28800 dışı → `invalidParameter`; `accent` `RGBAColor(hex:)`; `minutes` aralık dışı → `invalidParameter`.
  - `struct CustomActivityRegistry: Equatable, Sendable { private(set) var activities: [Activity]; @discardableResult mutating func upsert(_: CustomActivityRequest, now: Date) -> Activity; @discardableResult mutating func end(id: String) -> Bool; mutating func removeExpired(now: Date) }` — güncellemede `startedAt` korunur; `expiresAt = min(now + (duration ?? maxLifetime), startedAt + maxLifetime)`; 4. yeni etkinlik en eski `updatedAt`'lıyı çıkarır; öncelik `.normal`.
  - `struct RateLimiter: Sendable { init(limit: Int = 10, window: TimeInterval = 10); mutating func allow(at: Date) -> Bool }`

- [ ] **Step 1: Testler**

```swift
@Suite struct IslandURLParserTests {
    func parse(_ s: String) -> Result<IslandURLCommand, IslandURLError> { IslandURLParser.parse(URL(string: s)!) }
    @Test func parsesShowActivityWithAllFields() {
        let r = parse("nimbo://activity/show?id=build&title=Derleme&subtitle=Nimbo&symbol=hammer&accent=FF8000&progress=0.4&duration=600")
        #expect(r == .success(.showActivity(.init(id: "build", title: "Derleme", subtitle: "Nimbo", symbol: "hammer",
                                                  accent: RGBAColor(hex: "FF8000"), progress: 0.4, duration: 600))))
    }
    @Test func percentDecodesTurkishCharacters() {
        guard case .success(.showActivity(let req)) = parse("nimbo://activity/show?id=m&title=Toplant%C4%B1%20ba%C5%9Fl%C4%B1yor") else { Issue.record(); return }
        #expect(req.title == "Toplantı başlıyor")
    }
    @Test func rejectsMissingTitle() { #expect(parse("nimbo://activity/show?id=a") == .failure(.missingParameter("title"))) }
    @Test func clampsProgressAndTruncatesTitle() {
        guard case .success(.showActivity(let req)) = parse("nimbo://activity/show?id=a&title=\(String(repeating: "x", count: 100))&progress=1.7") else { Issue.record(); return }
        #expect(req.progress == 1 && req.title.count == 80 && req.title.hasSuffix("…"))
    }
    @Test func rejectsDurationOver8Hours() { #expect(parse("nimbo://activity/show?id=a&title=t&duration=40000") == .failure(.invalidParameter("duration"))) }
    @Test func rejectsInvalidID() { #expect(parse("nimbo://activity/show?id=a%20b&title=t") == .failure(.invalidParameter("id"))) }
    @Test func parsesEndTimerAndToggle() {
        #expect(parse("nimbo://activity/end?id=a") == .success(.endActivity(id: "a")))
        #expect(parse("nimbo://timer/start?minutes=25") == .success(.startTimer(minutes: 25)))
        #expect(parse("nimbo://island/toggle") == .success(.toggleIsland))
    }
    @Test func rejectsWrongSchemeAndUnknownCommand() {
        #expect(parse("other://activity/show?id=a&title=t") == .failure(.wrongScheme))
        #expect(parse("nimbo://foo/bar") == .failure(.unknownCommand("foo/bar")))
    }
}

@Suite struct CustomActivityRegistryTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    func req(_ id: String, duration: TimeInterval? = nil) -> CustomActivityRequest { .init(id: id, title: id, subtitle: nil, symbol: nil, accent: nil, progress: nil, duration: duration) }
    @Test func fourthCustomActivityEvictsOldest() {
        var r = CustomActivityRegistry()
        for (i, id) in ["a", "b", "c", "d"].enumerated() { r.upsert(req(id), now: now.addingTimeInterval(Double(i))) }
        #expect(r.activities.map(\.id.rawValue).sorted() == ["b", "c", "d"])
    }
    @Test func customActivityLivesAtMost8Hours() {
        var r = CustomActivityRegistry(); let a = r.upsert(req("a"), now: now)
        #expect(a.expiresAt == now.addingTimeInterval(28_800))
        r.removeExpired(now: now.addingTimeInterval(28_801)); #expect(r.activities.isEmpty)
    }
    @Test func updateKeepsStartedAtAndCapsLifetime() {
        var r = CustomActivityRegistry(); r.upsert(req("a"), now: now)
        let u = r.upsert(req("a", duration: 28_800), now: now.addingTimeInterval(3600))
        #expect(u.startedAt == now && u.expiresAt == now.addingTimeInterval(28_800))
    }
    @Test func endRemovesById() { var r = CustomActivityRegistry(); r.upsert(req("a"), now: now); #expect(r.end(id: "a") && r.activities.isEmpty) }
}

@Suite struct RateLimiterTests {
    @Test func moreThan10In10SecondsAreDropped() {
        var l = RateLimiter(); let t0 = Date(timeIntervalSinceReferenceDate: 0)
        let allowed = (0..<12).filter { l.allow(at: t0.addingTimeInterval(Double($0) * 0.1)) }.count
        #expect(allowed == 10 && l.allow(at: t0.addingTimeInterval(10.5)))
    }
}
```

- [ ] **Step 2–4:** `--filter "IslandURLParserTests|CustomActivityRegistryTests|RateLimiterTests"` → FAIL → uygula → PASS (13 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): URL command parser, custom activity registry, rate limiter"`

---

### T1.9 Ayarlar modeli ve kalıcılığı

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Settings/{IslandSettings,SettingsStore}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Settings/{IslandSettingsTests,SettingsStoreTests}.swift`

**Interfaces:**
- Consumes: T1.2 `DisplayMode`, T1.5 `TemperatureUnitPreference`.
- Produces:
  - `enum IslandFeature: String, Codable, Sendable, CaseIterable { nowPlaying, timer, calendar, weather, shelf, battery, downloads, privacyIndicator, customActivities }`
  - `enum WeatherLocationSetting: Codable, Equatable, Sendable { automatic, city(name: String, latitude: Double, longitude: Double) }`
  - `struct IslandSettings: Codable, Equatable, Sendable` — alanlar ve varsayılanlar: `displayMode = .notchedOnly`, `hideInFullscreen = true`, `criticalAlertsInFullscreen = true`, `launchAtLogin = false`, `hapticsEnabled = true`, `soundsEnabled = true`, `haloIntensity: Double = 1.0` (0...1), `enabledFeatures = Set(IslandFeature.allCases)`, `weatherLocation = .automatic`, `temperatureUnit = .system`, `shelfCopiesFiles = false`, `shelfRetentionDays: Int? = 7` (`nil` = asla), `showMenuBarIcon = false`, `muteUntil: Date? = nil`, `hasCompletedOnboarding = false`; `static let default`; `var islandOptions: IslandOptions`. Çözümleme her anahtarı `decodeIfPresent ?? varsayılan` ile okur (eksik/fazla anahtar kırmaz).
  - `@MainActor @Observable final class SettingsStore { init(defaults: UserDefaults, key: String = "settings.v1"); private(set) var settings: IslandSettings; func update(_ mutate: (inout IslandSettings) -> Void) }` — JSON olarak yazar; bozuk veri → varsayılanlar.

- [ ] **Step 1: Testler**

```swift
@Suite struct IslandSettingsTests {
    @Test func decodingEmptyObjectGivesDefaults() throws {
        #expect(try JSONDecoder().decode(IslandSettings.self, from: Data("{}".utf8)) == .default)
    }
    @Test func decodingIgnoresUnknownKeysAndKeepsKnown() throws {
        let s = try JSONDecoder().decode(IslandSettings.self, from: Data(#"{"hapticsEnabled":false,"futureKey":1}"#.utf8))
        #expect(s.hapticsEnabled == false && s.displayMode == .notchedOnly)
    }
    @Test func roundTripPreservesValues() throws {
        var s = IslandSettings.default; s.weatherLocation = .city(name: "İzmir", latitude: 38.42, longitude: 27.14); s.shelfRetentionDays = nil
        #expect(try JSONDecoder().decode(IslandSettings.self, from: JSONEncoder().encode(s)) == s)
    }
}

@MainActor @Suite struct SettingsStoreTests {
    func freshDefaults() -> UserDefaults { UserDefaults(suiteName: "test.\(UUID().uuidString)")! }
    @Test func storePersistsAcrossInstances() {
        let d = freshDefaults()
        SettingsStore(defaults: d).update { $0.soundsEnabled = false }
        #expect(SettingsStore(defaults: d).settings.soundsEnabled == false)
    }
    @Test func corruptDataFallsBackToDefaults() {
        let d = freshDefaults(); d.set(Data("not json".utf8), forKey: "settings.v1")
        #expect(SettingsStore(defaults: d).settings == .default)
    }
}
```

- [ ] **Step 2–4:** `--filter "IslandSettingsTests|SettingsStoreTests"` → FAIL → uygula → PASS (5 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): settings model with tolerant decoding and store"`

---

### T1.10 Renk matematiği ve kapak vurgusu seçimi

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Color/{ColorMath,ArtworkPalette}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Color/{ColorMathTests,ArtworkPaletteTests}.swift`

**Interfaces:**
- Consumes: T1.1 `RGBAColor`.
- Produces:
  - `extension RGBAColor { var relativeLuminance: Double /* WCAG */; func contrastRatio(with: RGBAColor) -> Double; var hsl: (hue: Double, saturation: Double, lightness: Double); init(hue: Double, saturation: Double, lightness: Double, alpha: Double = 1); func adjustedForBlackBackground(minimumContrast: Double = 3.0) -> RGBAColor; static let black, white }`
  - `struct WeightedColor: Equatable, Sendable { color: RGBAColor; weight: Double }`
  - `enum ArtworkPalette { static func accent(from candidates: [WeightedColor]) -> RGBAColor? }`

Algoritma (`accent`): parlaklığı < 0.02 veya HSL doygunluğu < 0.18 olan adayları at; kalan yoksa `nil` (çağıran nötr hâle kullanır). Puan = `weight × (0.35 + saturation)`; en yüksek puanlı rengi `adjustedForBlackBackground(3.0)` ile döndür. `adjustedForBlackBackground`: kontrast ≥ hedef olana kadar HSL açıklığını 0.02 adımlarla artır (ton ve doygunluk korunur; açıklık en çok 0.9).

- [ ] **Step 1: Testler**

```swift
@Suite struct ColorMathTests {
    @Test func contrastOfWhiteOnBlackIs21() { #expect(abs(RGBAColor.white.contrastRatio(with: .black) - 21) < 0.01) }
    @Test func adjustedAccentMeetsThreeToOneOnBlackAndKeepsHue() {
        let navy = RGBAColor(red: 0.06, green: 0.06, blue: 0.25)
        let adjusted = navy.adjustedForBlackBackground()
        #expect(adjusted.contrastRatio(with: .black) >= 3.0)
        #expect(abs(adjusted.hsl.hue - navy.hsl.hue) < 1.0 / 360)
    }
    @Test func alreadyBrightColorIsUnchanged() {
        let yellow = RGBAColor(red: 1, green: 0.85, blue: 0.2)
        #expect(yellow.adjustedForBlackBackground() == yellow)
    }
}

@Suite struct ArtworkPaletteTests {
    @Test func accentIgnoresBlackAndGray() throws {
        let c = try #require(ArtworkPalette.accent(from: [
            .init(color: .black, weight: 0.7), .init(color: RGBAColor(red: 0.5, green: 0.5, blue: 0.5), weight: 0.2),
            .init(color: RGBAColor(red: 0.9, green: 0.1, blue: 0.1), weight: 0.1)]))
        #expect(c.hsl.hue < 0.02 || c.hsl.hue > 0.98)
    }
    @Test func grayscaleArtworkHasNoAccent() {
        #expect(ArtworkPalette.accent(from: [.init(color: .black, weight: 0.5), .init(color: .white, weight: 0.5)]) == nil)
    }
}
```

- [ ] **Step 2–4:** `--filter "ColorMathTests|ArtworkPaletteTests"` → FAIL → uygula → PASS (5 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): WCAG color math and artwork accent selection"`

---

**Faz 1 çıkış ölçütü:** `swift test --package-path Packages/IslandCore` → tüm testler geçer (≈ 110); `core-linux` CI işi yeşil; `Scripts/check-architecture.sh` temiz; macOS'ta `swift test --package-path Packages/IslandCore --enable-code-coverage` sonrası `xcrun llvm-cov report` ile `IslandCore` satır kapsamı ≥ %90 (spec §10).
