# Faz 4 — Etkinlik hattı, zamanlayıcı ve geçici uyarılar

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §3.5, §5.2, §5.6 (sunum sütunu)
> T4.1 önce biter (Faz 5–8'in hepsi ona bağlanır); T4.2 ve T4.3 paraleldir.

---

### T4.1 `ActivityHub` (Core Engineer)

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Hub/{ActivityProviding,ActivityHub}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Hub/ActivityHubTests.swift`

**Interfaces:**
- Consumes: T1.1 `IslandTime`, `Activity`, `TransientAlert`; T1.3 `ActivityScheduler`, `ActivityPriorityRules`; T1.9 `SettingsStore`, `IslandFeature`.
- Produces:
  - `@MainActor public protocol ActivityProviding: AnyObject { var activities: [Activity] { get }; var onActivitiesChange: (@MainActor () -> Void)? { get set } }`
  - `@MainActor public protocol AlertProviding: AnyObject { var onAlert: (@MainActor (TransientAlert) -> Void)? { get set } }`
  - `@MainActor public final class ActivityHub { init(time: IslandTime, settings: SettingsStore); func register(_: ActivityProviding, feature: IslandFeature); func register(alerts: AlertProviding, feature: IslandFeature); var onLayoutChange: (@MainActor (IslandLayout) -> Void)?; var onAlert: (@MainActor (TransientAlert) -> Void)?; private(set) var layout: IslandLayout; func refresh() }`

Davranış: herhangi bir sağlayıcı değişince ya da `refresh()` çağrılınca — özelliği açık sağlayıcıların etkinlikleri toplanır, `custom` dışındakilerin önceliği `ActivityPriorityRules.priority(for:now:)` ile **yeniden** hesaplanır, `ActivityScheduler.layout` alınır; düzen öncekiyle aynıysa yayınlanmaz. Ardından **tek** bir zamanlayıcı en erken `nextChange` / `expiresAt` anına kurulur (önceki iptal edilir) ve o an `refresh()` çağrılır — yoklama yok. Uyarılar: özelliği kapalıysa ya da `settings.muteUntil > now` iken önceliği `< .critical` ise düşürülür; aksi hâlde `onAlert`. Ayarlar değişince `refresh()`.

- [ ] **Step 1: Testler** (`FakeProvider`: `activities` atanınca `onActivitiesChange` çağırır; `FakeAlerts`: `emit(_:)`)

```swift
@MainActor @Suite struct ActivityHubTests {
    let time = ManualTime()
    func makeHub() -> (ActivityHub, SettingsStore) {
        let s = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!); return (ActivityHub(time: time, settings: s), s)
    }
    func runningTimer(endsIn s: TimeInterval) -> Activity {
        .fixture(id: "timer", content: .timer(.init(timerID: "timer", label: nil, phase: .simple, duration: 1500,
                 endsAt: time.now.addingTimeInterval(s), pausedRemaining: nil, cycle: nil, totalCycles: nil)))
    }
    @Test func hubMergesProvidersIntoLayout() {
        let (hub, _) = makeHub(); let a = FakeProvider(), b = FakeProvider()
        hub.register(a, feature: .nowPlaying); hub.register(b, feature: .timer)
        a.activities = [.fixture(id: "music", content: .nowPlaying(.fixture(isPlaying: true)))]; b.activities = [runningTimer(endsIn: 600)]
        #expect(hub.layout.primary != nil && hub.layout.detached.count == 1)
    }
    @Test func disabledFeatureIsIgnored() {
        let (hub, settings) = makeHub(); let p = FakeProvider(); hub.register(p, feature: .timer)
        settings.update { $0.enabledFeatures.remove(.timer) }; p.activities = [runningTimer(endsIn: 600)]
        #expect(hub.layout == .empty)
    }
    @Test func hubRecomputesAtPriorityBoundary() {
        let (hub, _) = makeHub(); let p = FakeProvider(); hub.register(p, feature: .timer)
        p.activities = [runningTimer(endsIn: 120)]; #expect(hub.layout.primary?.priority == .normal)
        time.advance(by: 60); #expect(hub.layout.primary?.priority == .high)
    }
    @Test func expiredActivityRemovedAtExpiry() {
        let (hub, _) = makeHub(); let p = FakeProvider(); hub.register(p, feature: .customActivities)
        p.activities = [.fixture(id: "c", expiresAt: time.now.addingTimeInterval(30))]
        time.advance(by: 31); #expect(hub.layout == .empty)
    }
    @Test func unchangedLayoutIsNotReemitted() {
        let (hub, _) = makeHub(); let p = FakeProvider(); var count = 0
        hub.onLayoutChange = { _ in count += 1 }; hub.register(p, feature: .timer)
        p.activities = [runningTimer(endsIn: 600)]; hub.refresh(); hub.refresh()
        #expect(count == 1)
    }
    @Test func muteSuppressesNonCriticalAlerts() {
        let (hub, settings) = makeHub(); let src = FakeAlerts(); var got: [TransientAlert] = []
        hub.onAlert = { got.append($0) }; hub.register(alerts: src, feature: .battery)
        settings.update { $0.muteUntil = time.now.addingTimeInterval(3600) }
        src.emit(.fixture(priority: .normal)); src.emit(.fixture(priority: .critical))
        #expect(got.map(\.priority) == [.critical])
    }
}
```

- [ ] **Step 2–4:** `--filter ActivityHubTests` → FAIL → uygula → PASS (6 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(core): activity hub with boundary-driven refresh and alert filtering"`
- **Entegrasyon notları:** `hub.onLayoutChange` → tüm store'lara `.activitiesChanged`; `hub.onAlert` → tüm store'lara `.alertRaised`; `SettingsStore` değişince `hub.refresh()`.

---

### T4.2 Zamanlayıcı özelliği (Productivity Engineer)

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Timer/TimerController.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Timer/{TimerActions,TimerCompactView,TimerExpandedCard,TimerQuickStartTile}.swift`
- Modify: `App/Resources/Localizable.xcstrings` (`timer.*` anahtarları)
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Timer/TimerControllerTests.swift`, `Packages/IslandFeatures/Tests/IslandFeaturesTests/Timer/TimerViewTests.swift`

**Interfaces:**
- Consumes: T1.7 `CountdownTimer`, `PomodoroPlan`, `PomodoroProgress`; T4.1 `ActivityProviding`, `AlertProviding`.
- Produces:
  - `@MainActor @Observable public final class TimerController: ActivityProviding, AlertProviding { init(time: IslandTime, defaults: UserDefaults, plan: PomodoroPlan = .standard); private(set) var current: CountdownTimer?; private(set) var pomodoro: PomodoroProgress?; func start(minutes: Double, label: String?); func startPomodoro(); func pause(); func resume(); func cancel(); func skip(); func restore(); var activities: [Activity] }` — `init` kalıcı durumu yalnızca okur; "kapalıyken bitti" uyarısını `onAlert` bağlandıktan sonra `restore()` üretir. Zamanlanmış eylemler `[weak self]` yakalar (serbest bırakılan denetleyici ateşlenmez).
  - `struct TimerActions { var start: (Double) -> Void; var startPomodoro: () -> Void; var pause: () -> Void; var resume: () -> Void; var cancel: () -> Void; var skip: () -> Void }` + `EnvironmentValues.timerActions` (varsayılan: hepsi no-op).
  - `struct TimerCompactLeading: View`, `struct TimerCompactTrailing: View { init(snapshot: TimerSnapshot) }`, `struct TimerExpandedCard: View { init(snapshot: TimerSnapshot) }`, `struct TimerQuickStartTile: View` (5 / 15 / 25 dk + Pomodoro + özel süre).

Davranış: etkinlik kimliği `"timer"`, vurgu turuncu; bitişte **bir kez** `TransientAlert(kind: .timerFinished, detail: .timer(label:phase:), tint: .orange, duration: 6, priority: .critical)`. Pomodoro'da bitişte `PomodoroProgress.advance` ve sonraki aşama **otomatik başlar**. Durum her değişimde `defaults`'a `"timer.v1"` anahtarıyla JSON yazılır. Açılışta geri yükleme: çalışıyorsa devam; uygulama kapalıyken bittiyse ve bitiş son 10 dk içindeyse uyarı **bir kez**, daha eskiyse sessizce temizlenir. Bitiş zamanlayıcısı `time.schedule(after: endDate − now)` (sürekli saat, uykudan sonra geçmişse uyanınca hemen ateşlenir). Kompakt geri sayım **uygulamayı her saniye uyandırmaz**: `Text(timerInterval: now...endsAt, countsDown: true)` + `TypeToken.numeralCompact` + `.monospacedDigit()`.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct TimerControllerTests {
    let time = ManualTime()
    func make(_ d: UserDefaults = UserDefaults(suiteName: UUID().uuidString)!) -> TimerController { TimerController(time: time, defaults: d) }
    @Test func startEmitsNormalTimerActivity() {
        let c = make(); c.start(minutes: 25, label: nil)
        #expect(c.activities.first?.priority == .normal && c.activities.first?.id == "timer")
    }
    @Test func lastMinuteRaisesPriorityToHigh() {
        let c = make(); c.start(minutes: 2, label: nil); time.advance(by: 61)
        #expect(c.activities.first?.priority == .high)
    }
    @Test func finishEmitsCriticalAlertOnce() {
        let c = make(); var alerts: [TransientAlert] = []; c.onAlert = { alerts.append($0) }
        c.start(minutes: 1, label: "Çay"); time.advance(by: 120)
        #expect(alerts.count == 1 && alerts[0].kind == .timerFinished && alerts[0].priority == .critical)
        #expect(c.activities.isEmpty)
    }
    @Test func pomodoroAdvancesToBreakAndAutoStarts() {
        let c = make(); c.startPomodoro(); time.advance(by: 1500)
        #expect(c.pomodoro?.phase == .shortBreak && c.current?.phase == .shortBreak && c.current?.remaining(at: time.now) == 300)
    }
    @Test func restoresRunningTimerAfterRelaunch() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        make(d).start(minutes: 25, label: nil); time.advance(by: 60)
        #expect(make(d).current?.remaining(at: time.now) == 1440)
    }
    @Test func finishedWhileQuitAlertsOnceWithin10Minutes() {
        let d = UserDefaults(suiteName: UUID().uuidString)!
        make(d).start(minutes: 1, label: nil); time.advance(by: 300)
        var alerts = 0; let c = make(d); c.onAlert = { _ in alerts += 1 }; c.restore()
        #expect(alerts == 1 && c.current == nil)
    }
    @Test func cancelClearsActivityAndPersistence() {
        let d = UserDefaults(suiteName: UUID().uuidString)!; let c = make(d)
        c.start(minutes: 5, label: nil); c.cancel()
        #expect(c.activities.isEmpty && make(d).current == nil)
    }
}
```

```swift
@MainActor @Suite struct TimerViewTests {
    @Test func quickStartOffers5_15_25() { #expect(TimerQuickStartTile.presetMinutes == [5, 15, 25]) }
    @Test func cardsRender() {
        let snap = TimerSnapshot(timerID: "timer", label: nil, phase: .focus, duration: 1500, endsAt: Date().addingTimeInterval(600), pausedRemaining: nil, cycle: 1, totalCycles: 4)
        #expect(ImageRenderer(content: TimerExpandedCard(snapshot: snap).frame(width: 492)).cgImage != nil)
        #expect(ImageRenderer(content: TimerCompactTrailing(snapshot: snap)).cgImage != nil)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (7 + 2 test).
- [ ] **Step 5: Commit** — `git commit -m "feat: timer and pomodoro with wall-clock persistence"`
- **Entegrasyon notları:** `hub.register(timer, feature: .timer)` + `register(alerts:)`; `ActivityContentView`'da `.timer` dalları; `HomeCardView`'da `.timer`, `.timerQuickStart`; `.environment(\.timerActions, …)`; `HomeInputs.hasRunningTimer`; açılışta `timer.restore()`.

---

### T4.3 Geçici uyarı görünümleri (Design Engineer)

**Files:**
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Alerts/{AlertPresentation,BatterySymbol,TransientAlertView}.swift`
- Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Root/IslandRootView.swift` (transient fazı bu görünümü kullanır)
- Modify: `App/Resources/Localizable.xcstrings` (`alert.*` anahtarları)
- Test: `Packages/IslandFeatures/Tests/IslandFeaturesTests/Alerts/AlertPresentationTests.swift`

**Interfaces:**
- Consumes: T1.1 `TransientAlert`, `AlertKind`, `AlertDetail`; T2.1 `Palette.tint`.
- Produces:
  - `enum BatterySymbol { static func name(level: Int, charging: Bool) -> String }` — `charging` → `battery.100percent.bolt`; aksi hâlde ≤ 10 → `battery.0percent`, ≤ 37 → `battery.25percent`, ≤ 62 → `battery.50percent`, ≤ 87 → `battery.75percent`, değilse `battery.100percent`.
  - `struct AlertPresentation: Equatable { symbol: String; titleKey: String; subtitle: String? }`; `enum AlertPresentations { static func make(_: TransientAlert) -> AlertPresentation }` — anahtarlar: `alert.charging` ("Şarj oluyor"/"Charging", alt satır `%NN`), `alert.unplugged`, `alert.batteryLow` ("Pil zayıf"), `alert.batteryFull` ("Şarj doldu"), `alert.downloadFinished` (alt satır dosya adı), `alert.timerFinished` / `alert.breakStarted` / `alert.focusStarted` (aşamaya göre), `alert.trackChanged` (başlık/sanatçı), `alert.permissionNeeded` ("Müzik bilgisi için izin gerekiyor"), `custom` → isteğin metni.
  - `struct TransientAlertView: View { init(alert: TransientAlert) }` — compact boyutunda: sol kanatta simge (ton renginde), sağ kanatta başlık; `downloadFinished` için peek boyutunda iki düğme: "Finder'da göster", "Rafa ekle" (`AlertActions` ortam değeri, varsayılan no-op).

- [ ] **Step 1: Testler**

```swift
@Suite struct AlertPresentationTests {
    @Test(arguments: [(5, "battery.0percent"), (30, "battery.25percent"), (60, "battery.50percent"), (80, "battery.75percent"), (100, "battery.100percent")])
    func batterySymbolMatchesLevel(level: Int, expected: String) { #expect(BatterySymbol.name(level: level, charging: false) == expected) }
    @Test func chargingUsesBoltSymbol() { #expect(BatterySymbol.name(level: 40, charging: true) == "battery.100percent.bolt") }
    @Test func everyAlertKindHasPresentation() {
        for kind in AlertKind.allCases {
            let p = AlertPresentations.make(.fixture(kind: kind))
            #expect(!p.symbol.isEmpty && NSImage(systemSymbolName: p.symbol, accessibilityDescription: nil) != nil, "\(kind)")
        }
    }
    @MainActor @Test func alertViewRendersForEveryKind() {
        for kind in AlertKind.allCases { #expect(ImageRenderer(content: TransientAlertView(alert: .fixture(kind: kind))).cgImage != nil) }
    }
}
```
(`TransientAlert.fixture(kind:)` her tür için uygun `detail` üretir.)

- [ ] **Step 2–4:** `--filter AlertPresentationTests` → FAIL → uygula → PASS (8 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(features): transient alert presentations and view"`

**Faz 4 çıkış ölçütü:** cihazda ⌃⌥Space → Ev → "25 dk" → ada compact geri sayım + turuncu ilerleme ışığı; bitişte 6 sn uyarı ve ses; uygulamayı kapatıp açınca zamanlayıcı sürer; Mac'i 2 dk uyutup uyandırınca kalan süre doğru (Review Focus #5); `measure-idle.sh` zamanlayıcı çalışırken < %1 CPU.
