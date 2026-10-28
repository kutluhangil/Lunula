# Faz 3 — Ada motoru (Engine Engineer + Design Engineer + Integrator)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §4, §7, §8
> Önkoşul: T1.2, T1.4, T2.1, T2.2, T2.3. Bu fazın sonunda gerçek bir ada vardır: notch'la birebir kapalı durur, hover/tık/kaydırma/klavye ile açılır, çoklu ekranda, tam ekranda ve uyku/uyanmada doğru davranır; boşta ~%0 CPU ölçülür.
> Komutlar: paketler `swift test --package-path Packages/<P> --filter <Suite>`; uygulama `xcodebuild test -project Lunula.xcodeproj -scheme Lunula -destination 'platform=macOS' -only-testing:LunulaTests/<Suite>`
> **Entegrasyon notları** satırları Integrator'ın `CompositionRoot.swift` / `project.yml` üzerinde yapacağı değişikliklerdir; görev sahibi bu dosyalara dokunmaz.

---

### T3.1 Ekran servisi

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/Screen/{ScreenService,ScreenDescriptor+NSScreen}.swift`
- Create: `Packages/IslandServices/Tests/IslandServicesTests/Support/AsyncTestSupport.swift` — `func settle(_ iterations: Int = 10) async` (`Task.yield` döngüsü); sonraki tüm Services testleri bunu kullanır, yeniden tanımlamaz.
- Test: `Packages/IslandServices/Tests/IslandServicesTests/Screen/ScreenServiceTests.swift`

**Interfaces:**
- Consumes: T1.2 `ScreenDescriptor`; test desteğinden `ScreenDescriptor.mbp14`, `.external`.
- Produces:
  - `extension ScreenDescriptor { @MainActor init(_ screen: NSScreen, isMain: Bool) }` — `id = screen.cgDirectDisplayID ?? 0` (macOS 26), `isBuiltIn = CGDisplayIsBuiltin(id) != 0`, `safeAreaTop = screen.safeAreaInsets.top`, `auxiliaryTopLeft/Right = screen.auxiliaryTopLeftArea/RightArea`, `menuBarHeight = max(frame.maxY − visibleFrame.maxY, safeAreaTop)`; sonuç 0 ise (otomatik gizlenen menü çubuğu) `NSStatusBar.system.thickness`.
  - `@MainActor final class ScreenService { init(center: NotificationCenter = .default, workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter, debounce: Duration = .milliseconds(150), provider: @escaping @MainActor () -> [ScreenDescriptor] = ScreenService.liveScreens); private(set) var current: [ScreenDescriptor]; func updates() -> AsyncStream<[ScreenDescriptor]>; static func liveScreens() -> [ScreenDescriptor] }`
- Dinlenen bildirimler: `NSApplication.didChangeScreenParametersNotification` (`center`), `NSWorkspace.didWakeNotification`, `.screensDidWakeNotification`, `.sessionDidBecomeActiveNotification` (`workspaceCenter`). Her sinyal bekleyen işi iptal edip `debounce` sonra **bir kez** yeniden hesaplar ve değer aynı olsa da yayınlar (uyanmada konumlar bayat olabilir).

- [ ] **Step 1: Testler** (özel `NotificationCenter()` örnekleri ve 50 ms debounce ile)

```swift
@MainActor @Suite struct ScreenServiceTests {
    func collect(_ s: ScreenService, for ms: Int) async -> [[ScreenDescriptor]] {
        var out: [[ScreenDescriptor]] = []
        let task = Task { for await v in s.updates() { out.append(v) } }
        try? await Task.sleep(for: .milliseconds(ms)); task.cancel(); return out
    }
    @Test func descriptorChangeIsDebounced() async {   // Review Focus #1
        let c = NotificationCenter(), w = NotificationCenter()
        let s = ScreenService(center: c, workspaceCenter: w, debounce: .milliseconds(50), provider: { [.mbp14] })
        Task { for _ in 0..<3 { c.post(name: NSApplication.didChangeScreenParametersNotification, object: nil); try? await Task.sleep(for: .milliseconds(10)) } }
        #expect(await collect(s, for: 300).count == 1)
    }
    @Test func geometryRecomputedOnScreenChange() async {   // Review Focus #1
        let c = NotificationCenter(); var screens: [ScreenDescriptor] = [.mbp14]
        let s = ScreenService(center: c, workspaceCenter: NotificationCenter(), debounce: .milliseconds(20), provider: { screens })
        screens = [.mbp14, .external]
        Task { c.post(name: NSApplication.didChangeScreenParametersNotification, object: nil) }
        #expect(await collect(s, for: 200).last?.count == 2)
    }
    @Test func wakeTriggersRecompute() async {
        let w = NotificationCenter()
        let s = ScreenService(center: NotificationCenter(), workspaceCenter: w, debounce: .milliseconds(20), provider: { [.mbp14] })
        Task { w.post(name: NSWorkspace.didWakeNotification, object: nil) }
        #expect(await collect(s, for: 200).count == 1)
    }
    @Test(.enabled(if: !NSScreen.screens.isEmpty)) func liveScreensMapsEveryScreen() {
        #expect(ScreenService.liveScreens().count == NSScreen.screens.count)
    }
}
```

- [ ] **Step 2–4:** `swift test --package-path Packages/IslandServices --filter ScreenServiceTests` → FAIL → uygula → PASS (4 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): debounced screen service with wake recompute"`

---

### T3.2 `IslandPanel`, sıcak bölge paneli ve pencere yöneticisi

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Ports/PanelControlling.swift`
- Create: `App/Sources/Window/{IslandPanel,HotZonePanel,HotZoneView,IslandWindowController,IslandWindowManager}.swift`
- Test: `App/Tests/IslandPanelTests.swift`

**Interfaces:**
- Consumes: T1.2 `IslandMetrics`, `NotchGeometry`, `DisplaySelection`; T3.1 `ScreenDescriptor`.
- Produces:
  - `@MainActor public protocol PanelControlling: AnyObject { func setMouseEventsIgnored(_ ignored: Bool); func makeKey(_ key: Bool) }` (IslandCore)
  - `final class IslandPanel: NSPanel { init(contentRect: NSRect); var allowsKey: Bool; override var canBecomeKey: Bool { allowsKey }; override var canBecomeMain: Bool { false } }` — yapılandırma spec §4.1: `[.borderless, .nonactivatingPanel]`, `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false`, `level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`, `isMovable = false`, `hidesOnDeactivate = false`, `isFloatingPanel = true`, `animationBehavior = .none`, `isReleasedWhenClosed = false`, başlangıçta `ignoresMouseEvents = true`.
  - `final class HotZonePanel: NSPanel` — aynı yapılandırma, fakat `ignoresMouseEvents = false`, içerik `HotZoneView`; `IslandPanel`'in **altında** sıralanır.
  - `enum HotZoneButton { left, right }`; `@MainActor protocol HotZoneDelegate: AnyObject { func hotZoneEntered(); func hotZoneExited(); func hotZoneMoved(to: NSPoint, at: TimeInterval); func hotZoneClicked(at: NSPoint, button: HotZoneButton); func hotZoneScrolled(deltaY: CGFloat, phase: NSEvent.Phase, momentumPhase: NSEvent.Phase, inverted: Bool) }`
  - `final class HotZoneView: NSView` — `NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self)`; `acceptsFirstMouse` true; olayları `delegate`'e iletir (noktalar **ekran** koordinatında).
  - `@MainActor final class IslandWindowController { let screenID: UInt32; let panel: IslandPanel; let hotZone: HotZonePanel; init(screen: ScreenDescriptor, content: AnyView); func layout(screen: ScreenDescriptor, hotZoneRect: CGRect); func close() }` — içerik `NSHostingView` ile, `sizingOptions = []`; panel çerçevesi `IslandMetrics.panelFrame`.
  - `@MainActor final class IslandWindowManager { func sync(screens: [ScreenDescriptor], mode: DisplayMode, make: (ScreenDescriptor) -> AnyView) -> [UInt32: IslandWindowController]; func controller(for id: UInt32) -> IslandWindowController? }` — ekran kimliğine göre ekler/kaldırır/yeniden konumlar; kaldırılan ekranın panellerini kapatır.
  - `extension IslandWindowController: PanelControlling` — `setMouseEventsIgnored` → `panel.ignoresMouseEvents`; `makeKey(true)` → `panel.allowsKey = true; NSApp.activate(); panel.makeKey()`; `makeKey(false)` → `allowsKey = false; panel.resignKey()`.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct IslandPanelTests {
    @Test func panelIsBorderlessNonActivatingAndClear() {
        let p = IslandPanel(contentRect: .init(x: 0, y: 0, width: 760, height: 300))
        #expect(p.styleMask.contains(.borderless) && p.styleMask.contains(.nonactivatingPanel))
        #expect(!p.isOpaque && p.backgroundColor == .clear && !p.hasShadow)
    }
    @Test func panelJoinsAllSpacesAndFullscreen() {
        let b = IslandPanel(contentRect: .zero).collectionBehavior
        #expect(b.isSuperset(of: [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]))
    }
    @Test func panelLevelIsStatusBarPlus8() {
        #expect(IslandPanel(contentRect: .zero).level.rawValue == NSWindow.Level.statusBar.rawValue + 8)
    }
    @Test func panelBecomesKeyOnlyWhenAllowed() {
        let p = IslandPanel(contentRect: .zero); #expect(!p.canBecomeKey)
        p.allowsKey = true; #expect(p.canBecomeKey); #expect(!p.canBecomeMain)
    }
    @Test func hotZoneReceivesMouseWhileIslandPanelIgnoresIt() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        #expect(c.panel.ignoresMouseEvents && !c.hotZone.ignoresMouseEvents)
    }
    @Test func controllerPositionsPanelAndHotZoneFromGeometry() {
        let c = IslandWindowController(screen: .mbp14, content: AnyView(Color.clear))
        let notch = NotchGeometry.metrics(for: .mbp14), zone = IslandMetrics.hotZone(around: notch.rect)
        c.layout(screen: .mbp14, hotZoneRect: zone)
        #expect(c.panel.frame == IslandMetrics.panelFrame(notch: notch, screen: .mbp14) && c.hotZone.frame == zone)
    }
    @Test func managerRemovesControllersForDisconnectedScreens() {
        let m = IslandWindowManager()
        #expect(m.sync(screens: [.mbp14, .external], mode: .allDisplays) { _ in AnyView(EmptyView()) }.count == 2)
        #expect(m.sync(screens: [.mbp14], mode: .allDisplays) { _ in AnyView(EmptyView()) }.keys.sorted() == [1])
    }
}
```

- [ ] **Step 2–4:** `-only-testing:LunulaTests/IslandPanelTests` → FAIL → uygula → PASS (7 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(app): island and hot-zone panels with per-screen window manager"`
- **Entegrasyon notları:** `CompositionRoot.start()` → `ScreenService.updates()` + `SettingsStore.settings.displayMode` değişince `IslandWindowManager.sync`; her ekran için `content` T3.5'in `IslandRootView`'ı.

---

### T3.3 İmleç, kaydırma ve isabet yönlendirme

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Pointer/{PointerSpeedEstimator,SwipeDetector,IslandHitTesting}.swift`
- Create: `App/Sources/Window/PointerRouter.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Pointer/{PointerSpeedEstimatorTests,SwipeDetectorTests,IslandHitTestingTests}.swift`, `App/Tests/PointerRouterTests.swift`

**Interfaces:**
- Consumes: T1.4 `IslandEvent`, `IslandPhase`, `IslandHitTarget`; T3.2 `HotZoneDelegate`.
- Produces:
  - `struct PointerSpeedEstimator: Sendable { init(window: TimeInterval = 0.05); mutating func add(_ p: CGPoint, at t: TimeInterval); func speed(at t: TimeInterval) -> Double /* pt/sn; < 2 örnek → 0 */ }`
  - `enum ScrollPhase: Sendable { began, changed, ended, none }`; `enum SwipeDirection: Sendable { up, down }`
  - `struct SwipeDetector: Sendable { init(threshold: CGFloat = 24); mutating func feed(deltaY: CGFloat, phase: ScrollPhase, isMomentum: Bool, inverted: Bool) -> SwipeDirection? }` — momentum yok sayılır; bir jest başına en fazla bir kez tetikler; `ended`/`began` biriktiriciyi sıfırlar; "parmaklar aşağı" = `.down` (doğal kaydırma `inverted` ile düzeltilir).
  - `enum IslandHitTesting { static func target(at: CGPoint, island: CGRect, bubbles: [(ActivityID, CGRect)]) -> IslandHitTarget? }` — baloncuk adadan önce kontrol edilir.
  - `@MainActor final class PointerRouter: HotZoneDelegate { init(send: @escaping @MainActor (IslandEvent) -> Void, phase: @escaping @MainActor () -> IslandPhase, geometry: @escaping @MainActor () -> (island: CGRect, bubbles: [(ActivityID, CGRect)]), showContextMenu: @escaping @MainActor (NSPoint) -> Void); var currentSpeed: Double; func islandHoverChanged(_ inside: Bool) }`
- Yönlendirme kuralı: sıcak bölge olayları yalnızca faz `idle`, `compact` veya `transient` iken iletilir; faz `peek`/`expanded` iken giriş/çıkış ada görünümünün kendi `onHover`'ından gelir (`islandHoverChanged`, T3.5 çağırır) — açık ada sıcak bölgeden büyük olduğu için. Sağ tık → `showContextMenu`. Kaydırma → `SwipeDetector` → `.swipedDown` / `.swipedUp`.

- [ ] **Step 1: Testler**

```swift
@Suite struct PointerSpeedEstimatorTests {
    @Test func speedIsDistanceOverTimeWithinWindow() {
        var e = PointerSpeedEstimator(); e.add(.zero, at: 0); e.add(CGPoint(x: 30, y: 40), at: 0.05)
        #expect(abs(e.speed(at: 0.05) - 1000) < 0.001)
    }
    @Test func oldSamplesAreIgnored() {
        var e = PointerSpeedEstimator(); e.add(.zero, at: 0); e.add(CGPoint(x: 500, y: 0), at: 0.01)
        e.add(CGPoint(x: 500, y: 0), at: 1.0); e.add(CGPoint(x: 501, y: 0), at: 1.02)
        #expect(e.speed(at: 1.02) < 100)
    }
    @Test func singleSampleIsZero() { var e = PointerSpeedEstimator(); e.add(.zero, at: 0); #expect(e.speed(at: 0) == 0) }
}

@Suite struct SwipeDetectorTests {
    @Test func downwardSwipePast24ptIsDown() {
        var d = SwipeDetector()
        #expect(d.feed(deltaY: -10, phase: .began, isMomentum: false, inverted: false) == nil)
        #expect(d.feed(deltaY: -20, phase: .changed, isMomentum: false, inverted: false) == .down)
    }
    @Test func naturalScrollingInversionHandled() {
        var d = SwipeDetector(); _ = d.feed(deltaY: 10, phase: .began, isMomentum: false, inverted: true)
        #expect(d.feed(deltaY: 20, phase: .changed, isMomentum: false, inverted: true) == .down)
    }
    @Test func momentumIsIgnored() { var d = SwipeDetector(); #expect(d.feed(deltaY: -100, phase: .none, isMomentum: true, inverted: false) == nil) }
    @Test func smallMovementIsNotASwipe() { var d = SwipeDetector(); #expect(d.feed(deltaY: -10, phase: .changed, isMomentum: false, inverted: false) == nil) }
    @Test func firesOncePerGesture() {
        var d = SwipeDetector(); _ = d.feed(deltaY: -30, phase: .began, isMomentum: false, inverted: false)
        #expect(d.feed(deltaY: -30, phase: .changed, isMomentum: false, inverted: false) == nil)
    }
}

@Suite struct IslandHitTestingTests {
    let island = CGRect(x: 0, y: 0, width: 300, height: 32), bubble = CGRect(x: 308, y: 0, width: 32, height: 32)
    @Test func bubbleWinsOverIsland() { #expect(IslandHitTesting.target(at: CGPoint(x: 320, y: 10), island: island, bubbles: [("b", bubble)]) == .bubble("b")) }
    @Test func islandHit() { #expect(IslandHitTesting.target(at: CGPoint(x: 10, y: 10), island: island, bubbles: []) == .island) }
    @Test func outsideReturnsNil() { #expect(IslandHitTesting.target(at: CGPoint(x: 500, y: 10), island: island, bubbles: []) == nil) }
}

@MainActor @Suite struct PointerRouterTests {
    @Test func hotZoneEventsForwardedOnlyWhileResting() {
        var sent: [IslandEvent] = []; var phase = IslandPhase.idle
        let r = PointerRouter(send: { sent.append($0) }, phase: { phase }, geometry: { (.zero, []) }, showContextMenu: { _ in })
        r.hotZoneEntered(); phase = .expanded(.home); r.hotZoneExited()
        #expect(sent == [.pointerEnteredHotZone])
    }
    @Test func islandHoverForwardedOnlyWhileOpen() {
        var sent: [IslandEvent] = []; var phase = IslandPhase.peek
        let r = PointerRouter(send: { sent.append($0) }, phase: { phase }, geometry: { (.zero, []) }, showContextMenu: { _ in })
        r.islandHoverChanged(false); phase = .idle; r.islandHoverChanged(true)
        #expect(sent == [.pointerExitedIsland])
    }
    @Test func rightClickOpensContextMenu() {
        var opened = false
        let r = PointerRouter(send: { _ in }, phase: { .idle }, geometry: { (.zero, []) }, showContextMenu: { _ in opened = true })
        r.hotZoneClicked(at: .zero, button: .right); #expect(opened)
    }
}
```

- [ ] **Step 2–4:** IslandCore `--filter "PointerSpeedEstimatorTests|SwipeDetectorTests|IslandHitTestingTests"` ve `-only-testing:LunulaTests/PointerRouterTests` → FAIL → uygula → PASS (11 + 3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat: pointer speed, swipe detection, hit testing and pointer router"`

---

### T3.4 `IslandStore` ve efekt yürütücü

**Files:**
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Store/{IslandStore,EffectRunner}.swift`
- Test: `Packages/IslandFeatures/Tests/IslandFeaturesTests/Store/IslandStoreTests.swift`

**Interfaces:**
- Consumes: T1.1 `IslandTime`; T1.4 `IslandReducer`, `IslandEffect`; T2.5 `FeedbackPlaying`; T3.2 `PanelControlling`.
- Produces:
  - `@MainActor @Observable final class IslandStore { init(time: IslandTime, panel: PanelControlling, feedback: FeedbackPlaying, speed: @escaping @MainActor () -> Double); private(set) var state: IslandState; func send(_ event: IslandEvent) }`
  - `@MainActor final class EffectRunner { init(time: IslandTime, panel: PanelControlling, feedback: FeedbackPlaying, speed: @escaping @MainActor () -> Double); func run(_ effects: [IslandEffect], dispatch: @escaping @MainActor (IslandEvent) -> Void) }` — `schedule(k, d)`: aynı türdeki bekleyen token iptal edilir, yenisi kurulur; ateşlenince `dwell` → `.pointerDwellElapsed(speed: speed())`, `exitGrace` → `.exitGraceElapsed`, `alertExpiry` → `.alertExpired`. `cancel(k)`: token iptal.
- Çoklu ekran: **ekran başına bir `IslandStore`** (imleç ekrana özeldir); etkinlik düzeni ve uyarılar hub tarafından tüm store'lara yayınlanır (T4.1 entegrasyonu).

- [ ] **Step 1: Testler** (`ManualTime`, kayıt tutan `FakePanel` ve `FakeFeedback` test hedefinde)

```swift
@MainActor @Suite struct IslandStoreTests {
    let time = ManualTime(); let panel = FakePanel(); let feedback = FakeFeedback()
    func store(speed: Double = 100) -> IslandStore { IslandStore(time: time, panel: panel, feedback: feedback, speed: { speed }) }
    @Test func sendAppliesReducerState() { let s = store(); s.send(.toggleRequested); #expect(s.state.phase == .expanded(.home)) }
    @Test func dwellTimerFiresWithMeasuredSpeed() {
        let s = store(); s.send(.pointerEnteredHotZone); time.advance(by: 0.1)
        #expect(s.state.phase == .peek)
    }
    @Test func fastPointerReschedulesDwell() {
        let s = store(speed: 2000); s.send(.pointerEnteredHotZone); time.advance(by: 0.35)
        #expect(s.state.phase == .idle)
    }
    @Test func reschedulingSameTimerReplacesPrevious() {
        let s = store(); s.send(.pointerEnteredHotZone); time.advance(by: 0.05)
        s.send(.pointerExitedIsland); s.send(.pointerEnteredHotZone); time.advance(by: 0.06)
        #expect(s.state.phase == .idle)                // ilk dwell iptal edildi
        time.advance(by: 0.05); #expect(s.state.phase == .peek)
    }
    @Test func exitGraceCollapsesAfterTimer() {
        let s = store(); s.send(.toggleRequested); s.send(.pointerEnteredHotZone); s.send(.pointerExitedIsland)
        time.advance(by: 0.25); #expect(s.state.phase == .idle)
    }
    @Test func panelReceivesMouseAndKeyChanges() {
        let s = store(); s.send(.toggleRequested)
        #expect(panel.ignoredHistory.last == false && panel.keyHistory.last == true)
    }
    @Test func hapticsForwardedToFeedbackPlayer() { let s = store(); s.send(.clicked(.island)); #expect(feedback.haptics == [.alignment]) }
}
```

- [ ] **Step 2–4:** `swift test --package-path Packages/IslandFeatures --filter IslandStoreTests` → FAIL → uygula → PASS (7 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(features): island store and effect runner"`

---

### T3.5 `IslandRootView` (şekil, fazlar, kanatlar, baloncuklar, ana sayfa iskeleti)

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Home/HomeComposer.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Root/{IslandRootView,IslandSurface,CompactLayoutView,PeekView,ExpandedView,HomePageView,HomeCardView,BubbleView,ActivityContentView,HaloDerivation,PrivacySlot}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Home/HomeComposerTests.swift`, `Packages/IslandFeatures/Tests/IslandFeaturesTests/Root/{IslandRootViewTests,HaloDerivationTests}.swift`

**Interfaces:**
- Consumes: T1.2 `NotchMetrics`, `IslandMetrics`; T1.3 `IslandLayout`; T2.1–T2.4; T3.3 `PointerRouter.islandHoverChanged`; T3.4 `IslandStore`.
- Produces:
  - `enum HomeCard: Hashable, Sendable { permission(MediaSourceID), nowPlaying, meeting, timer, weather, nextEvent, timerQuickStart, calendarAccess }` ve `struct HomeInputs: Equatable, Sendable { pendingPermission: MediaSourceID?; hasNowPlaying: Bool; hasImminentMeeting: Bool; hasRunningTimer: Bool; hasWeather: Bool; hasUpcomingEvent: Bool; calendarAccessUndetermined: Bool }`; `enum HomeComposer { static func compose(_: HomeInputs) -> (hero: HomeCard?, tiles: [HomeCard]) }` — kahraman sırası (spec §6.7): izin > müzik > yaklaşan toplantı > zamanlayıcı > hava; karolar (en fazla 2, kahramanda olmayanlardan): hava, sıradaki etkinlik (yoksa takvim erişimi belirsizse `calendarAccess`), zamanlayıcı çalışmıyorsa `timerQuickStart`.
  - `struct IslandRootView: View { init(store: IslandStore, notch: NotchMetrics, home: @escaping @MainActor () -> HomeInputs, onHover: @escaping @MainActor (Bool) -> Void) }`
  - `struct ActivityContentView: View { enum Slot { compactLeading, compactTrailing, expanded }; init(activity: Activity, slot: Slot) }` — içerik türüne göre özellik görünümünü seçen **tek** `switch`; bu görevde her dal genel bir yedek görünüm çizer (simge + başlık); özellik görevleri kendi dallarını Entegrasyon notuyla bağlar.
  - `struct HomeCardView: View { init(card: HomeCard) }` — aynı desen.
  - `enum HaloDerivation { static func state(phase: IslandPhase, layout: IslandLayout, now: Date) -> HaloState }` — müzik çalıyor → `ambient(breathing: true)` kapak renginde; zamanlayıcı → `progress(fraction, endsAt)` turuncu; toplantı → `warming(fraction: 1 − kalan/600)`; transient → `pulse` (renk: uyarı tonu); idle/hidden → `.off`.
  - `struct PrivacySlot: View` — T7.5'in kamera/mikrofon noktaları için notch'un sağında 6 pt'lik yer; bu görevde boş.
- Davranış: kapalı ada notch boyutunda saf siyah; `peek` fazında düzen boşsa boyut `IslandSizeRequest.invite` (her yana +8 pt "davet"); genişlemiş adanın üst bandında (kamera çevresinde) sol kanatta kahraman etkinliğin simgesi, sağ kanatta sekmeler (Ev · Raf) ve dişli (`gearshape`, Ayarlar'ı açar — `IslandRootView`'a `openSettings: () -> Void` parametresi); fazlar arası boyut değişimi `IslandMetrics.size(for:)` + `MotionToken.morph/open/close`; şekil yarıçapları `IslandShape.closed ↔ .expanded` arasında canlandırılır; baloncuk ilk göründüğünde `MetaballBridge` 0.55 sn; açık adada `.onHover` → `onHover`; "Hareketi Azalt" → `MotionToken.reducedTransition`; ada içeriği hiçbir zaman şeklin dışına taşmaz (`clipShape(IslandShape)`).

- [ ] **Step 1: Testler**

```swift
@Suite struct HomeComposerTests {
    var base: HomeInputs { HomeInputs(pendingPermission: nil, hasNowPlaying: false, hasImminentMeeting: false, hasRunningTimer: false, hasWeather: false, hasUpcomingEvent: false, calendarAccessUndetermined: false) }
    @Test func heroOrderIsMusicMeetingTimerWeather() {
        var i = base; i.hasWeather = true; i.hasRunningTimer = true; i.hasImminentMeeting = true; i.hasNowPlaying = true
        #expect(HomeComposer.compose(i).hero == .nowPlaying)
        i.hasNowPlaying = false; #expect(HomeComposer.compose(i).hero == .meeting)
    }
    @Test func permissionRequestIsAlwaysHero() { var i = base; i.hasNowPlaying = true; i.pendingPermission = .music; #expect(HomeComposer.compose(i).hero == .permission(.music)) }
    @Test func tilesAreAtMostTwoAndExcludeHero() {
        var i = base; i.hasWeather = true; i.hasUpcomingEvent = true; i.hasNowPlaying = true
        let c = HomeComposer.compose(i)
        #expect(c.tiles.count <= 2 && !c.tiles.contains(c.hero!))
        #expect(c.tiles == [.weather, .nextEvent])
    }
    @Test func emptyHomeOffersQuickStart() { #expect(HomeComposer.compose(base).tiles.contains(.timerQuickStart)) }
}

@MainActor @Suite struct IslandRootViewTests {
    @Test(arguments: [IslandPhase.idle, .compact, .peek, .expanded(.home), .expanded(.shelf), .transient(.fixture())])
    func rootRendersEveryPhase(_ phase: IslandPhase) {
        #expect(ImageRenderer(content: IslandRootView.preview(phase: phase).frame(width: 760, height: 300)).cgImage != nil)
    }
    @Test func idleRendersOnlyBlackOrClearPixels() throws {
        let img = try #require(ImageRenderer(content: IslandRootView.preview(phase: .idle).frame(width: 760, height: 300)).cgImage)
        #expect(PixelProbe.allPixelsAreBlackOrTransparent(img, tolerance: 0.02))
    }
}

@Suite struct HaloDerivationTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    @Test func idleIsOff() { #expect(HaloDerivation.state(phase: .idle, layout: .empty, now: now) == .off) }
    @Test func playingMusicBreathesInAccent() {
        let a = Activity.fixture(content: .nowPlaying(.fixture(isPlaying: true)), accent: RGBAColor(red: 0.2, green: 0.6, blue: 1))
        let h = HaloDerivation.state(phase: .compact, layout: .init(primary: a, detached: [], overflowCount: 0), now: now)
        #expect(h.mode == .ambient(breathing: true) && h.color == a.accent)
    }
    @Test func transientPulses() { #expect(HaloDerivation.state(phase: .transient(.fixture()), layout: .empty, now: now).mode == .pulse) }
}
```
`IslandRootView.preview(phase:)` — testler ve `#Preview` için sahte store/zaman/panel ile kurulan statik yardımcı (yalnızca `#if DEBUG`). `PixelProbe` IslandFeatures test hedefine de kopyalanır.

- [ ] **Step 2–4:** IslandCore `--filter HomeComposerTests`, IslandFeatures `--filter "IslandRootViewTests|HaloDerivationTests"` → FAIL → uygula → PASS (4 + 7 + 3 test).
- [ ] **Step 5: Görsel kontrol (cihazda)** — ada kapalıyken notch kenarında görünür bir siyah çerçeve yok; Peek/Expanded geçişinde taşma, titreme yok. Ekran görüntüleri `docs/qa/shots/`.
- [ ] **Step 6: Commit** — `git commit -m "feat(features): island root view, home composition and halo derivation"`
- **Entegrasyon notları:** `IslandWindowManager.sync(make:)` her ekran için `IslandRootView(store:notch:home:onHover: router.islandHoverChanged)`.

---

### T3.6 Bağlam menüsü, global kısayol ve klavye

**Files:**
- Create: `App/Sources/Window/{ContextMenuBuilder,GlobalShortcut}.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Root/PageCycler.swift`
- Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Root/ExpandedView.swift` (klavye işleyicileri)
- Modify: `App/Resources/Localizable.xcstrings` (`menu.settings`, `menu.mute1h`, `menu.unmute`, `menu.quit`, `shortcut.toggleIsland`)
- Test: `App/Tests/ContextMenuTests.swift`, `Packages/IslandFeatures/Tests/IslandFeaturesTests/Root/PageCyclerTests.swift`

**Interfaces:**
- Consumes: T1.9 `SettingsStore` (`muteUntil`); T3.4 `IslandStore.send`.
- Produces:
  - `struct ContextMenuActions { var openSettings: () -> Void; var toggleMute: () -> Void; var quit: () -> Void }`; `enum ContextMenuBuilder { @MainActor static func menu(isMuted: Bool, actions: ContextMenuActions) -> NSMenu }` — öğeler: "Ayarlar…" (⌘,), "1 saat sustur" ya da "Susturmayı kaldır", ayraç, "Lunula'dan çık" (⌘Q).
  - `extension KeyboardShortcuts.Name { static let toggleIsland = Self("toggleIsland", default: .init(.space, modifiers: [.control, .option])) }`; `@MainActor enum GlobalShortcut { static func install(onToggle: @escaping @MainActor () -> Void) }` — `KeyboardShortcuts.onKeyUp(for: .toggleIsland)`.
  - `enum PageCycler { static let pages: [IslandPage] = [.home, .shelf]; static func next(after: IslandPage) -> IslandPage; static func previous(before: IslandPage) -> IslandPage }` — `.activity` sayfasından ← → `.home`.
  - `ExpandedView`: `.focusable()` + `.onKeyPress(.escape)` → `.escapePressed`; `.leftArrow/.rightArrow` → `.pageSelected(...)`.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct ContextMenuTests {
    let noop = ContextMenuActions(openSettings: {}, toggleMute: {}, quit: {})
    @Test func menuHasSettingsMuteSeparatorQuit() {
        let m = ContextMenuBuilder.menu(isMuted: false, actions: noop)
        #expect(m.items.count == 4 && m.items[2].isSeparatorItem && m.items[0].keyEquivalent == "," && m.items[3].keyEquivalent == "q")
    }
    @Test func muteItemTitleReflectsState() {
        #expect(ContextMenuBuilder.menu(isMuted: false, actions: noop).items[1].title != ContextMenuBuilder.menu(isMuted: true, actions: noop).items[1].title)
    }
    @Test func shortcutDefaultIsControlOptionSpace() {
        #expect(KeyboardShortcuts.Name.toggleIsland.defaultShortcut == .init(.space, modifiers: [.control, .option]))
    }
}

@Suite struct PageCyclerTests {
    @Test func arrowsCyclePages() {
        #expect(PageCycler.next(after: .home) == .shelf && PageCycler.next(after: .shelf) == .home)
        #expect(PageCycler.previous(before: .activity("x")) == .home)
    }
}
```

- [ ] **Step 2–4:** `-only-testing:LunulaTests/ContextMenuTests` ve IslandFeatures `--filter PageCyclerTests` → FAIL → uygula → PASS (3 + 1 test).
- [ ] **Step 5: Commit** — `git commit -m "feat: context menu, global toggle shortcut and keyboard navigation"`
- **Entegrasyon notları:** `PointerRouter(showContextMenu:)` → `NSMenu.popUp(positioning:at:in:)`; `GlobalShortcut.install { activeStore.send(.toggleRequested) }` (etkin store: imlecin bulunduğu ekranınki, yoksa ana ekranınki); sustur → `settings.muteUntil = now + 3600`.

---

### T3.7 Tam ekran tespiti ve sistem olayları

**Files:**
- Create: `docs/qa/spikes/fullscreen.md`
- Create: `Packages/IslandCore/Sources/IslandCore/Fullscreen/FullscreenHeuristic.swift`
- Create: `Packages/IslandServices/Sources/IslandServices/Fullscreen/{WindowListReader,FullscreenMonitor}.swift`, `Packages/IslandServices/Sources/IslandServices/System/SystemEventsMonitor.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Fullscreen/FullscreenHeuristicTests.swift`, `Packages/IslandServices/Tests/IslandServicesTests/Fullscreen/{FullscreenMonitorTests,SystemEventsMonitorTests}.swift`

**Interfaces:**
- Consumes: T1.2 `ScreenDescriptor`.
- Produces:
  - `struct WindowInfo: Equatable, Sendable { ownerPID: Int32; layer: Int; bounds: CGRect /* Quartz: sol üst orijin */; isOnscreen: Bool }`
  - `enum FullscreenHeuristic { static let mainMenuLayer = 24; static func isFullscreen(windows: [WindowInfo], frontmostPID: Int32, screen: ScreenDescriptor, primaryScreenHeight: CGFloat) -> Bool }` — ekran çerçevesi Quartz'a çevrilir (`y = primaryScreenHeight − frame.maxY`). Tam ekran ⇔ (a) ön plandaki uygulamanın katman-0, ekranda görünen bir penceresi, ekranın **üst `safeAreaTop` bandı hariç** tüm alanını 1 pt toleransla kaplıyor **ve** (b) o ekranın üst `menuBarHeight` bandıyla kesişen, ekranda görünen katman-24 (menü çubuğu) penceresi yok. (b) maksimize pencere yanlış pozitifini ayırır; spike ile doğrulanır.
  - `protocol WindowListReading: Sendable { func windows() -> [WindowInfo] }`; `struct CGWindowListReader: WindowListReading` — `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)`; yalnızca `kCGWindowOwnerPID`, `kCGWindowLayer`, `kCGWindowBounds`, `kCGWindowIsOnscreen` okunur (ad/sahip adı **okunmaz**, Ekran Kaydı izni istenmez).
  - `@MainActor final class FullscreenMonitor { init(workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter, reader: WindowListReading = CGWindowListReader(), screens: @escaping @MainActor () -> [ScreenDescriptor], frontmostPID: @escaping @MainActor () -> Int32?, settleDelay: Duration = .milliseconds(300)); func updates() -> AsyncStream<[UInt32: Bool]> }` — `activeSpaceDidChangeNotification` ve `didActivateApplicationNotification` sonrası `settleDelay` bekleyip değerlendirir; yoklama yok.
  - `enum SystemEvent: Sendable { willSleep, didWake, screensDidSleep, screensDidWake }`; `@MainActor final class SystemEventsMonitor { init(workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter); func events() -> AsyncStream<SystemEvent> }`

- [ ] **Step 1: Cihazda spike** — Debug derlemesine geçici bir `#if DEBUG` menü öğesi ("Pencere listesini günlüğe yaz") ekle; şu durumların her birinde `CGWindowListReader().windows()` çıktısını kaydet: masaüstü, maksimize Safari, tam ekran Safari, Keynote sunumu, tam ekran Xcode, otomatik gizlenen menü çubuğu. Bulguları (`katman-24 penceresi tam ekranda kayboluyor mu?`, pencere sınırları) `docs/qa/spikes/fullscreen.md`'ye tablo olarak yaz; geçici menü öğesini sil. Bulgular sezgiseli değiştiriyorsa Interfaces'teki kuralı güncelleyip notu ekle.
- [ ] **Step 2: Testler** (fikstürler spike çıktısından)

```swift
@Suite struct FullscreenHeuristicTests {
    let h: CGFloat = 982   // birincil ekran yüksekliği (mbp14)
    func win(_ pid: Int32, layer: Int = 0, _ r: CGRect) -> WindowInfo { .init(ownerPID: pid, layer: layer, bounds: r, isOnscreen: true) }
    let menuBar = WindowInfo(ownerPID: 1, layer: 24, bounds: CGRect(x: 0, y: 0, width: 1512, height: 32), isOnscreen: true)
    @Test func windowCoveringWholeScreenIsFullscreen() {
        #expect(FullscreenHeuristic.isFullscreen(windows: [win(42, CGRect(x: 0, y: 0, width: 1512, height: 982))], frontmostPID: 42, screen: .mbp14, primaryScreenHeight: h))
    }
    @Test func windowBelowNotchCoveringRestIsFullscreen() {
        #expect(FullscreenHeuristic.isFullscreen(windows: [win(42, CGRect(x: 0, y: 32, width: 1512, height: 950))], frontmostPID: 42, screen: .mbp14, primaryScreenHeight: h))
    }
    @Test func maximizedWindowWithMenuBarVisibleIsNotFullscreen() {
        #expect(!FullscreenHeuristic.isFullscreen(windows: [menuBar, win(42, CGRect(x: 0, y: 32, width: 1512, height: 950))], frontmostPID: 42, screen: .mbp14, primaryScreenHeight: h))
    }
    @Test func otherAppsWindowDoesNotCount() {
        #expect(!FullscreenHeuristic.isFullscreen(windows: [win(7, CGRect(x: 0, y: 0, width: 1512, height: 982))], frontmostPID: 42, screen: .mbp14, primaryScreenHeight: h))
    }
    @Test func secondaryScreenUsesQuartzConversion() {
        // external: AppKit (1512, 0, 2560, 1440) → Quartz y = 982 − 1440 = −458
        #expect(FullscreenHeuristic.isFullscreen(windows: [win(42, CGRect(x: 1512, y: -458, width: 2560, height: 1440))], frontmostPID: 42, screen: .external, primaryScreenHeight: h))
    }
}
```
Services testleri: `FullscreenMonitorTests.reevaluatesOnSpaceChange` (sahte okuyucu tam ekran döndürür; `activeSpaceDidChangeNotification` sonrası 50 ms `settleDelay` ile `[1: true]` yayınlanır), `SystemEventsMonitorTests.mapsWorkspaceNotifications` (4 bildirim → 4 olay, sırayla).

- [ ] **Step 3–5:** FAIL → uygula → PASS (5 + 2 test).
- [ ] **Step 6: Commit** — `git commit -m "feat: fullscreen heuristic without screen recording and system event monitor"`
- **Entegrasyon notları:** `FullscreenMonitor` → ilgili ekranın store'una `.fullscreenChanged`; `SystemEventsMonitor` `willSleep` → tüm store'lara `.systemWillSleep`, `didWake` → `.systemDidWake`; `ScreenService` yayını → `IslandWindowManager.sync` + tüm store'lara `.displayConfigurationChanged`.

---

### T3.8 Ayarlar penceresi iskeleti, girişte başlat, menü çubuğu simgesi

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/LaunchAtLogin/LaunchAtLoginService.swift`
- Create: `App/Sources/Settings/{SettingsWindowController,SettingsTab,GeneralSettingsView,AboutSettingsView}.swift`, `App/Sources/Window/StatusItemController.swift`
- Modify: `App/Resources/Localizable.xcstrings` (`settings.*`, `about.*` anahtarları, TR+EN)
- Test: `Packages/IslandServices/Tests/IslandServicesTests/LaunchAtLogin/LaunchAtLoginServiceTests.swift`, `App/Tests/SettingsWindowTests.swift`

**Interfaces:**
- Consumes: T1.9 `SettingsStore`, `IslandSettings`; T3.6 `KeyboardShortcuts.Name.toggleIsland`, `ContextMenuBuilder`.
- Produces:
  - `protocol LoginItemControlling: AnyObject { var status: SMAppService.Status { get }; func register() throws; func unregister() throws }` (`extension SMAppService: LoginItemControlling {}`)
  - `@MainActor @Observable final class LaunchAtLoginService { init(item: LoginItemControlling = SMAppService.mainApp); var isEnabled: Bool; var requiresApproval: Bool; func setEnabled(_ on: Bool) throws; func openSystemSettings() /* SMAppService.openSystemSettingsLoginItems() */ }` — App Review 2.4.5(iii): yalnızca kullanıcı açarsa kaydolur.
  - `struct SettingsTab: Identifiable { id: String; titleKey: LocalizedStringResource; symbol: String; makeView: @MainActor () -> AnyView; @MainActor static func baseTabs(settings: SettingsStore, launchAtLogin: LaunchAtLoginService) -> [SettingsTab] /* general, about */ }`
  - `@MainActor final class SettingsWindowController: NSWindowController { init(tabs: [SettingsTab]); func show() }` — `NSTabViewController` (`tabStyle = .toolbar`), her sekme `NSHostingController`; pencere `[.titled, .closable]`, `toolbarStyle = .preference`, ortalanmış; `show()` önce `NSApp.activate()`. Bu görevde sekmeler: **Genel** ve **Hakkında**; özellik görevleri kendi sekmelerini Entegrasyon notuyla ekler.
  - `GeneralSettingsView`: girişte başlat (onay gerekiyorsa açıklama + "Sistem Ayarları'nı aç"), ekran modu seçici (`DisplayMode`), tam ekranda gizle, tam ekranda kritik uyarılar, `KeyboardShortcuts.Recorder(for: .toggleIsland)`, menü çubuğu simgesi.
  - `AboutSettingsView`: sürüm (`CFBundleShortVersionString`), lisanslar (KeyboardShortcuts — MIT), atıflar listesi (T6.3 Open-Meteo satırını ekler).
  - `@MainActor final class StatusItemController { init(menu: @escaping @MainActor () -> NSMenu); var isVisible: Bool }` — SF Symbol `capsule.fill`; menü bağlam menüsüyle aynı.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct LaunchAtLoginServiceTests {
    @Test func enablingRegistersAndDisablingUnregisters() throws {
        let fake = FakeLoginItem(status: .notRegistered); let s = LaunchAtLoginService(item: fake)
        try s.setEnabled(true); try s.setEnabled(false)
        #expect(fake.calls == ["register", "unregister"])
    }
    @Test func requiresApprovalIsSurfaced() { #expect(LaunchAtLoginService(item: FakeLoginItem(status: .requiresApproval)).requiresApproval) }
}

@MainActor @Suite struct SettingsWindowTests {
    @Test func windowHasGeneralAndAboutTabs() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let c = SettingsWindowController(tabs: SettingsTab.baseTabs(settings: settings, launchAtLogin: LaunchAtLoginService(item: FakeLoginItem(status: .notRegistered))))
        #expect((c.contentViewController as? NSTabViewController)?.tabViewItems.map { $0.identifier as? String } == ["general", "about"])
    }
    @Test func tabStyleIsToolbar() {
        let c = SettingsWindowController(tabs: [])
        #expect((c.contentViewController as? NSTabViewController)?.tabStyle == .toolbar)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (2 + 2 test).
- [ ] **Step 5: Elle doğrula** — bağlam menüsü → Ayarlar açılır, öne gelir, ⌘W kapatır; girişte başlat anahtarı Sistem Ayarları › Giriş Öğeleri'nde görünür; kısayol kaydedici yeni kısayolu hemen uygular.
- [ ] **Step 6: Commit** — `git commit -m "feat(app): settings window, launch at login and optional status item"`
- **Entegrasyon notları:** `SettingsStore` değişince: `displayMode` → `IslandWindowManager.sync`; `hideInFullscreen`/`criticalAlertsInFullscreen` → tüm store'lara `.optionsChanged(settings.islandOptions)`; `showMenuBarIcon` → `StatusItemController.isVisible`.

---

### T3.9 Motor QA'sı ve performans taban çizgisi (QA & Performance)

**Files:**
- Create: `Scripts/perf/measure-idle.sh`, `docs/qa/checklist.md`, `docs/qa/perf-log.md`

**Interfaces:**
- Produces: `Scripts/perf/measure-idle.sh [--seconds N] [--assert-idle]` — çalışan `Lunula` sürecinin PID'ini bulur, `top -l $((N+1)) -s 1 -pid $pid -stats pid,cpu,idlew,mem` örnekler (ilk örnek atılır), medyan CPU, medyan boşta uyanma/sn ve son bellek değerini `cpu_median=… idlew_median=… mem=…` biçiminde yazar; `--assert-idle` verilirse CPU medyanı > 0.1 veya uyanma medyanı > 1 ise `exit 1`. `docs/qa/checklist.md` — bölüm başlıkları: Motor, Şimdi Çalıyor, Zamanlayıcı, Takvim, Hava, Raf, Sinyaller, Otomasyon, Erişilebilirlik, Performans; bu görev yalnızca **Motor** bölümünü doldurur, diğer fazlar kendi bölümlerini ekler.

- [ ] **Step 1: Ölçüm betiğini çalıştırılabilir hâlde yaz ve uygulama kapalıyken dene**
Run: `Scripts/perf/measure-idle.sh --seconds 5; echo "exit=$?"`
Expected: `Lunula is not running`, `exit=2`.
- [ ] **Step 2: Release derleyip boşta ölç**
Run: `xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Release -derivedDataPath build build -quiet && open build/Build/Products/Release/Lunula.app && sleep 10 && Scripts/perf/measure-idle.sh --seconds 60 --assert-idle`
Expected: `cpu_median=0.0 idlew_median=0` civarı, `exit=0`. Sonuç satırını tarih, cihaz ve macOS sürümüyle `docs/qa/perf-log.md`'ye ekle.
- [ ] **Step 3: Motor kontrol listesini yaz ve cihazda uygula** — maddeler: kapalı ada notch'la birebir (yakın çekim fotoğraf) · hover → peek · hızlı geçişte peek yok · 250 ms çıkış toleransı · tık → expanded · Esc / dışarı tık / yukarı kaydırma kapatır · iki parmak aşağı açar · sağ tık menüsü · ⌃⌥Space · ekran modları (yalnız notch / tümü / ana) · kapak kapalı + yalnız harici ekran (hap modu) · uyku/uyanma ×3 (Review Focus #1) · harici ekran tak/çıkar ×3 · tam ekran: Safari, Keynote, Xcode · maksimize pencere yanlış pozitifi · Spaces geçişi, Mission Control, Sahne Yöneticisi · Hareketi Azalt / Şeffaflığı Azalt / Kontrastı Artır · **ada açıkken panelin şeffaf bölgesine tıklama alttaki menü öğesine ulaşıyor mu** (ulaşmıyorsa: panel çerçevesini her faz değişiminde ada + hâle payına küçült ve bunu `docs/qa/spikes/panel-hit-testing.md`'ye yaz) · macOS 27'de menü çubuğu değişikliği sonrası konum.
- [ ] **Step 4: Commit** — `git add Scripts/perf docs/qa && git commit -m "test(qa): idle performance script, engine checklist and baseline"`

**Faz 3 çıkış ölçütü:** ada cihazda uçtan uca çalışır; tüm testler yeşil; `measure-idle.sh --assert-idle` geçer; kontrol listesinin Motor bölümü işaretli.
