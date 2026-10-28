# Faz 8 — Kestirmeler, URL şeması ve özel etkinlikler (Automation Engineer)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §5.7
> Önkoşul: T1.8, T4.1, T4.2. Sıra: T8.1 → (T8.2 ∥ T8.3).
> Amaç: terminalden, Kestirmeler'den ve AI ajan kancalarından (ör. Claude Code hook'ları) **ağ izni olmadan** adada etkinlik göstermek.

---

### T8.1 `CustomActivityController` ve `URLRouter`

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Automation/CustomActivityController.swift`
- Create: `App/Sources/URLRouting/URLRouter.swift`
- Modify: `App/Sources/AppDelegate.swift` (`application(_:open:)`) — Integrator
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Automation/CustomActivityControllerTests.swift`, `App/Tests/URLRouterTests.swift`

**Interfaces:**
- Consumes: T1.8 `CustomActivityRegistry`, `IslandURLParser`, `RateLimiter`; T4.1 `ActivityProviding`; T4.2 `TimerController`.
- Produces:
  - `@MainActor @Observable public final class CustomActivityController: ActivityProviding { init(time: IslandTime); func show(_: CustomActivityRequest); func end(id: String); var activities: [Activity] }` — kayıt + en erken `expiresAt` için tek zamanlayıcı (`removeExpired` sonrası `onActivitiesChange`).
  - `@MainActor final class URLRouter { init(custom: CustomActivityController, timer: TimerController, toggle: @escaping @MainActor () -> Void, time: IslandTime, limiter: RateLimiter = RateLimiter()); @discardableResult func handle(_ url: URL) -> Result<IslandURLCommand, IslandURLError> }` — hız sınırını aşan istek düşürülür ve `Logger` ile (başlıklar `privacy: .private`) kaydedilir; geçersiz URL durumu değiştirmez.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct CustomActivityControllerTests {
    let time = ManualTime()
    func req(_ id: String, duration: TimeInterval? = nil) -> CustomActivityRequest { .init(id: id, title: id, subtitle: nil, symbol: nil, accent: nil, progress: nil, duration: duration) }
    @Test func showAddsCustomActivity() { let c = CustomActivityController(time: time); c.show(req("a")); #expect(c.activities.map(\.id) == ["a"]) }
    @Test func expiryRemovesActivityAndNotifies() {
        let c = CustomActivityController(time: time); var changes = 0; c.onActivitiesChange = { changes += 1 }
        c.show(req("a", duration: 60)); time.advance(by: 61)
        #expect(c.activities.isEmpty && changes == 2)
    }
    @Test func endRemoves() { let c = CustomActivityController(time: time); c.show(req("a")); c.end(id: "a"); #expect(c.activities.isEmpty) }
}

@MainActor @Suite struct URLRouterTests {
    let time = ManualTime()
    func make(toggled: @escaping () -> Void = {}) -> (URLRouter, CustomActivityController, TimerController) {
        let custom = CustomActivityController(time: time), timer = TimerController(time: time, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        return (URLRouter(custom: custom, timer: timer, toggle: toggled, time: time), custom, timer)
    }
    @Test func routerDispatchesShowAndTimer() {
        let (r, custom, timer) = make()
        r.handle(URL(string: "nimbo://activity/show?id=build&title=Derleme")!); r.handle(URL(string: "nimbo://timer/start?minutes=5")!)
        #expect(custom.activities.count == 1 && timer.current?.duration == 300)
    }
    @Test func routerDropsCommandsBeyondRateLimit() {
        let (r, custom, _) = make()
        for i in 0..<15 { r.handle(URL(string: "nimbo://activity/show?id=a\(i % 3)&title=t")!) }
        #expect(custom.activities.count <= 3)
        #expect(r.handle(URL(string: "nimbo://island/toggle")!) == .failure(.rateLimited))
    }
    @Test func invalidURLIsIgnored() {
        let (r, custom, _) = make()
        #expect(r.handle(URL(string: "nimbo://activity/show?id=a")!) == .failure(.missingParameter("title")) && custom.activities.isEmpty)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (3 + 3 test).
- [ ] **Step 5: Elle doğrula** — `open -g "nimbo://activity/show?id=demo&title=Merhaba&symbol=sparkles&accent=7C5CFF&progress=0.3"` → adada etkinlik; `open -g "nimbo://activity/end?id=demo"` → kaybolur; `-g` ile uygulama öne gelmez.
- [ ] **Step 6: Commit** — `git commit -m "feat: URL router and custom activity controller"`
- **Entegrasyon notları:** `hub.register(custom, feature: .customActivities)`; `AppDelegate.application(_:open:)` → `router.handle`; `toggle` → etkin store `.toggleRequested`.

---

### T8.2 App Intents ve Kestirmeler

**Files:**
- Create: `App/Sources/Intents/{ShowActivityIntent,UpdateActivityIntent,EndActivityIntent,StartTimerIntent,ToggleIslandIntent,NimboShortcuts,IntentError}.swift`
- Create: `App/Resources/AppShortcuts.xcstrings` (TR + EN ifadeler)
- Test: `App/Tests/IntentsTests.swift`

**Interfaces:**
- Consumes: T1.8 `CustomActivityRequest.make(...)`; T8.1 `CustomActivityController`; T4.2 `TimerController`.
- Produces:
  - Her niyet: `static let supportedModes: IntentModes = .background` (macOS 26; `openAppWhenRun` kullanımdan kalktı), `@Dependency` ile `CustomActivityController` / `TimerController` / `IslandToggler` alır.
  - `ShowActivityIntent` (`id`, `title`, `subtitle?`, `symbol?`, `accentHex?`, `progress?`, `durationSeconds?`) ve `UpdateActivityIntent` (aynı alanlar; kimlik yoksa hata) → `CustomActivityRequest.make` → `show`. `EndActivityIntent(id)`, `StartTimerIntent(minutes)`, `ToggleIslandIntent`.
  - `enum IntentError: Error, CustomLocalizedStringResourceConvertible { invalid(IslandURLError), notFound(String) }`
  - `struct NimboShortcuts: AppShortcutsProvider` — İngilizce: "Show activity in \(.applicationName)", "Start a timer in \(.applicationName)", "Toggle \(.applicationName)"; Türkçe karşılıklar `AppShortcuts.xcstrings`'te.
  - `@MainActor final class IslandToggler { init(_ toggle: @escaping @MainActor () -> Void); func toggle() }`
- Bağımlılık kaydı (Integrator, `CompositionRoot`): `AppDependencyManager.shared.add(dependency: custom)`, `…(dependency: timer)`, `…(dependency: IslandToggler { … })`.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct IntentsTests {
    @Test func showActivityIntentAddsCustomActivity() async throws {
        let custom = CustomActivityController(time: ManualTime())
        var intent = ShowActivityIntent(); intent.id = "deploy"; intent.title = "Yayın"; intent.accentHex = "34C759"
        _ = try await intent.perform(using: custom)
        #expect(custom.activities.first?.accent == RGBAColor(hex: "34C759"))
    }
    @Test func invalidAccentHexThrows() async {
        var intent = ShowActivityIntent(); intent.id = "x"; intent.title = "t"; intent.accentHex = "nothex"
        await #expect(throws: IntentError.self) { _ = try await intent.perform(using: CustomActivityController(time: ManualTime())) }
    }
    @Test func updateUnknownIDThrowsNotFound() async {
        var intent = UpdateActivityIntent(); intent.id = "missing"; intent.title = "t"
        await #expect(throws: IntentError.self) { _ = try await intent.perform(using: CustomActivityController(time: ManualTime())) }
    }
    @Test func startTimerIntentStartsTimer() async throws {
        let timer = TimerController(time: ManualTime(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var intent = StartTimerIntent(); intent.minutes = 10; _ = try await intent.perform(using: timer)
        #expect(timer.current?.duration == 600)
    }
}
```
(`perform(using:)` her niyette `perform()`'un test edilebilir çekirdeğidir; `perform()` bağımlılığı `@Dependency`'den alıp ona devreder.)

- [ ] **Step 2–4:** FAIL → uygula → PASS (4 test).
- [ ] **Step 5: Elle doğrula** — Kestirmeler uygulamasında "Nimbo" eylemleri görünür; "Etkinlik göster" çalıştırılınca uygulama öne gelmeden adada belirir.
- [ ] **Step 6: Commit** — `git commit -m "feat(app): App Intents and shortcuts running in background mode"`

---

### T8.3 Özel etkinlik görünümleri ve otomasyon belgesi

**Files:**
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Custom/{CustomSymbol,CustomCompact,CustomExpandedCard}.swift`
- Create: `docs/automation.md`
- Test: `Packages/IslandFeatures/Tests/IslandFeaturesTests/Custom/CustomActivityViewTests.swift`

**Interfaces:**
- Consumes: T1.1 `CustomActivitySnapshot`.
- Produces: `enum CustomSymbol { static let fallback = "sparkle"; static func resolve(_ name: String?) -> String /* NSImage(systemSymbolName:) nil ise fallback */ }`; `CustomCompactLeading` (simge, vurgu renginde), `CustomCompactTrailing` (`progress` → 14 pt halka; `endsAt` → `Text(timerInterval:)`; ikisi de yoksa boş), `CustomExpandedCard` (başlık, alt başlık, ilerleme çubuğu).
- `docs/automation.md`: URL başvurusu (tüm parametreler, sınırlar: 3 eşzamanlı, 8 saat, 10 istek/10 sn), App Intents listesi, `bash` örnekleri (`open -g "nimbo://…"`), Claude Code kancası örneği (`.claude/settings.json` içinde `PreToolUse`/`Stop` kancalarından `open -g "nimbo://activity/show?id=claude&title=…&symbol=sparkles"` ve bitişte `activity/end`).

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct CustomActivityViewTests {
    @Test func invalidSymbolFallsBackToSparkle() {
        #expect(CustomSymbol.resolve("not.a.real.symbol") == "sparkle")
        #expect(CustomSymbol.resolve("hammer") == "hammer")
        #expect(CustomSymbol.resolve(nil) == "sparkle")
    }
    @Test func customCardRenders() {
        let s = CustomActivitySnapshot(title: "Derleme", subtitle: "Nimbo · Release", symbol: "hammer", progress: 0.4, endsAt: nil)
        #expect(ImageRenderer(content: CustomExpandedCard(snapshot: s, accent: nil).frame(width: 492)).cgImage != nil)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (2 test).
- [ ] **Step 5: Commit** — `git commit -m "feat: custom activity views and automation guide"`
- **Entegrasyon notları:** `ActivityContentView` `.custom` dalları (T3.5'teki genel yedek görünümün yerine).

**Faz 8 çıkış ölçütü:** `docs/automation.md`'deki her örnek cihazda çalışır; 4. özel etkinlik en eskiyi çıkarır; 15 hızlı istekte uygulama takılmaz.
