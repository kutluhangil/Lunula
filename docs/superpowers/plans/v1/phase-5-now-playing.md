# Faz 5 — Şimdi Çalıyor (Media Engineer)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §5.1, §9 · Araştırma raporu §6 (neden evrensel Now Playing yok)
> Önkoşul: T4.1. Sıra: T5.1 → (T5.2 ∥ T5.3 ∥ T5.5) → T5.4 → (T5.6 ∥ T5.7).
> Kaynaklar yalnızca Music ve Spotify'dır; MediaRemote ve `/usr/bin/perl` hilesi **yasak** (Global Constraints).

---

### T5.1 `ScriptRunner` (seri, ana iş parçacığı dışı, zaman aşımlı)

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/NowPlaying/{ScriptValue,ScriptExecuting,AppleScriptExecutor,ScriptRunner}.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/NowPlaying/ScriptRunnerTests.swift`

**Interfaces:**
- Produces:
  - `enum ScriptValue: Equatable, Sendable { text(String), number(Double), bool(Bool), data(Data), list([ScriptValue]), none }`
  - `enum ScriptOutcome: Equatable, Sendable { success(ScriptValue), notRunning, permissionNeeded, permissionDenied, timedOut, failed(code: Int) }`
  - `protocol ScriptExecuting: Sendable { func execute(_ source: String) -> ScriptOutcome /* eşzamanlı, bloklayan */ }`
  - `final class AppleScriptExecutor: ScriptExecuting, @unchecked Sendable` — `NSAppleScript`, kaynak metne göre derlenmiş betik önbelleği (kilitli sözlük); `NSAppleEventDescriptor` → `ScriptValue` dönüşümü (liste, metin, tamsayı/gerçek, boolean, `typeData`/resim → `data`); `static func outcome(forErrorCode: Int) -> ScriptOutcome`: -1743 → `permissionDenied`, -1744 → `permissionNeeded`, -600 → `notRunning`, -1712 → `timedOut`, diğerleri `failed`.
  - `actor ScriptRunner { init(executor: ScriptExecuting = AppleScriptExecutor(), isRunning: @escaping @Sendable (String) -> Bool = ScriptRunner.isAppRunning, timeout: Duration = .seconds(1)); func run(_ source: String, target bundleID: String) async -> ScriptOutcome; static func isAppRunning(_ bundleID: String) -> Bool /* NSRunningApplication */ }`

Kurallar: hedef çalışmıyorsa betik **hiç yürütülmez** (`tell application` uygulamayı başlatırdı) → `.notRunning`. Yürütme özel bir seri `DispatchQueue(label: "com.kutluhangul.lunula.scripts", qos: .userInitiated)` üzerinde, aynı anda tek betik. Çağrı `timeout` ile yarıştırılır; süre dolarsa `.timedOut` döner (devam süreci tek seferlik sonuç bayrağıyla korunur). Her betik kaynağı ayrıca `with timeout of 1 second … end timeout` ile sarılır (çağıran sorumluluğunda; T5.2/T5.3).

- [ ] **Step 1: Testler** (`FakeExecutor`: verilen süre kadar uyur, iş parçacığını ve eşzamanlılığı kaydeder)

```swift
@Suite struct ScriptRunnerTests {
    @Test func notRunningTargetIsNeverScripted() async {
        let fake = FakeExecutor(result: .success(.none))
        let r = ScriptRunner(executor: fake, isRunning: { _ in false })
        #expect(await r.run("x", target: "com.apple.Music") == .notRunning && fake.callCount == 0)
    }
    @Test func scriptTimeoutReturnsTimedOutWithinOneSecond() async {   // Review Focus #4
        let r = ScriptRunner(executor: FakeExecutor(result: .success(.none), delay: 3), isRunning: { _ in true }, timeout: .milliseconds(300))
        let start = ContinuousClock.now
        #expect(await r.run("x", target: "t") == .timedOut)
        #expect(ContinuousClock.now - start < .seconds(1))
    }
    @Test func executionNeverOnMainThread() async {
        let fake = FakeExecutor(result: .success(.none))
        _ = await ScriptRunner(executor: fake, isRunning: { _ in true }).run("x", target: "t")
        #expect(fake.ranOnMainThread == false)
    }
    @Test func callsAreSerialized() async {
        let fake = FakeExecutor(result: .success(.none), delay: 0.05)
        let r = ScriptRunner(executor: fake, isRunning: { _ in true })
        await withTaskGroup(of: Void.self) { g in for _ in 0..<5 { g.addTask { _ = await r.run("x", target: "t") } } }
        #expect(fake.maxConcurrency == 1)
    }
    @Test func appleEventErrorsMapToOutcomes() {
        #expect(AppleScriptExecutor.outcome(forErrorCode: -1743) == .permissionDenied)
        #expect(AppleScriptExecutor.outcome(forErrorCode: -1744) == .permissionNeeded)
        #expect(AppleScriptExecutor.outcome(forErrorCode: -600) == .notRunning)
        #expect(AppleScriptExecutor.outcome(forErrorCode: -1712) == .timedOut)
    }
}
```

- [ ] **Step 2–4:** `swift test --package-path Packages/IslandServices --filter ScriptRunnerTests` → FAIL → uygula → PASS (5 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): serial off-main AppleScript runner with timeout"`

---

### T5.2 `MusicSource`

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/NowPlaying/{NowPlayingSource,MusicScripts,MusicScriptParser,MusicSource}.swift`
- Create: `docs/qa/spikes/music-scripting.md`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/NowPlaying/{MusicScriptParserTests,MusicSourceTests}.swift`

**Interfaces:**
- Consumes: T1.1 `NowPlayingSnapshot`, `MediaSourceID`; T5.1 `ScriptRunner`, `ScriptValue`.
- Produces:
  - `enum PlaybackCommand: Equatable, Sendable { playPause, next, previous, seek(TimeInterval) }`
  - `enum AutomationPermission: Equatable, Sendable { granted, needsConsent, denied, notRunning }`
  - `protocol AutomationPermissionChecking: Sendable { func status(for bundleID: String) async -> AutomationPermission; func requestConsent(for bundleID: String) async -> AutomationPermission }` (somut uygulaması T5.7'de; T5.4 bu protokolle sahte nesne kullanır)
  - `protocol NowPlayingSource: Sendable { var id: MediaSourceID { get }; var bundleID: String { get }; var notificationName: Notification.Name { get }; func snapshot(now: Date) async -> NowPlayingSnapshot?; func artwork(for trackID: String) async -> Data?; func perform(_: PlaybackCommand) async }`
  - `enum MusicScriptParser { static func parse(_: ScriptValue, now: Date) -> NowPlayingSnapshot? }`
  - `final class MusicSource: NowPlayingSource` — `bundleID = "com.apple.Music"`, `notificationName = "com.apple.Music.playerInfo"`.

Betikler (`MusicScripts`, sabit metinler):
```applescript
with timeout of 1 second
  tell application id "com.apple.Music"
    if player state is stopped then return {"stopped"}
    set t to current track
    return {player state as text, name of t, artist of t, album of t, duration of t, player position, persistent ID of t}
  end tell
end timeout
```
Kapak: `if (count of artworks of current track) > 0 then return raw data of artwork 1 of current track` (aynı `tell`/`timeout` sarmalı; -1728 → `nil`). Komutlar: `playpause`, `next track`, `previous track`, `set player position to <saniye>`.
Ayrıştırma: ilk öğe `"stopped"` → `nil`; ad boşsa → `nil` (Tahoe'daki akış/radyo betik hatası: yanlış bilgi yerine hiç bilgi); süre **saniye**; `isPlaying = (state == "playing")`; `positionTimestamp = now`; `trackID = persistent ID`; `artworkKey = "music:" + persistent ID`.

- [ ] **Step 1: Cihazda doğrulama (spike)** — şu üç komutun çıktısını `docs/qa/spikes/music-scripting.md`'ye yaz:
  1. `sdef /System/Applications/Music.app | grep -o 'access-group identifier="[^"]*"' | sort -u` → `com.apple.Music.playback` ve `com.apple.Music.playerInfo` adları hâlâ var mı? Farklıysa Integrator `project.yml` yetkisini günceller.
  2. Bir parça çalarken yukarıdaki sorgu betiği `osascript` ile → beklenen 7 öğeli liste; bir Apple Music akış parçasında ve radyoda tekrar.
  3. Geçici bir Debug gözlemcisiyle `com.apple.Music.playerInfo` bildirimi geldiğinde `userInfo` anahtarlarını günlüğe yaz (yalnızca belge için; kod userInfo'ya **güvenmez**).
- [ ] **Step 2: Testler**

```swift
@Suite struct MusicScriptParserTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    func list(_ items: ScriptValue...) -> ScriptValue { .list(items) }
    @Test func parsesPlayingTrack() throws {
        let s = try #require(MusicScriptParser.parse(list(.text("playing"), .text("Bir Derdim Var"), .text("mor ve ötesi"), .text("Dünya Yalan Söylüyor"),
                                                         .number(245.3), .number(61.0), .text("ABC123")), now: now))
        #expect(s.title == "Bir Derdim Var" && s.artist == "mor ve ötesi" && s.duration == 245.3 && s.position == 61 && s.isPlaying && s.trackID == "ABC123")
    }
    @Test func pausedTrackIsNotPlaying() {
        #expect(MusicScriptParser.parse(list(.text("paused"), .text("a"), .text("b"), .text("c"), .number(10), .number(1), .text("id")), now: now)?.isPlaying == false)
    }
    @Test func stoppedReturnsNil() { #expect(MusicScriptParser.parse(list(.text("stopped")), now: now) == nil) }
    @Test func emptyTitleReturnsNil() {
        #expect(MusicScriptParser.parse(list(.text("playing"), .text(""), .text(""), .text(""), .number(0), .number(0), .text("id")), now: now) == nil)
    }
    @Test func malformedValueReturnsNil() { #expect(MusicScriptParser.parse(.text("garbage"), now: now) == nil) }
}

@Suite struct MusicSourceTests {
    @Test func appNotRunningProducesNilSnapshot() async {   // Review Focus #4
        let fake = FakeExecutor(result: .success(.none))
        let source = MusicSource(runner: ScriptRunner(executor: fake, isRunning: { _ in false }))
        #expect(await source.snapshot(now: Date()) == nil && fake.callCount == 0)
    }
    @Test func seekSendsSetPlayerPosition() async {
        let fake = FakeExecutor(result: .success(.none))
        await MusicSource(runner: ScriptRunner(executor: fake, isRunning: { _ in true })).perform(.seek(42))
        #expect(fake.lastSource?.contains("set player position to 42") == true)
    }
}
```

- [ ] **Step 3–5:** FAIL → uygula → PASS (7 test).
- [ ] **Step 6: Commit** — `git commit -m "feat(services): Apple Music source via scripting access groups"`

---

### T5.3 `SpotifySource`

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/NowPlaying/{SpotifyScripts,SpotifyScriptParser,SpotifySource}.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/NowPlaying/{SpotifyScriptParserTests,SpotifySourceTests}.swift`

**Interfaces:**
- Consumes: T5.1, T5.2 `NowPlayingSource`, `PlaybackCommand`.
- Produces: `enum SpotifyScriptParser { static func parse(_: ScriptValue, now: Date) -> (snapshot: NowPlayingSnapshot, artworkURL: URL?)? }`; `final class SpotifySource: NowPlayingSource { init(runner: ScriptRunner, session: URLSession = .shared, cacheDirectory: URL) }` — `bundleID = "com.spotify.client"`, `notificationName = "com.spotify.client.PlaybackStateChanged"`.

Sorgu betiği T5.2 kalıbında, dönüş `{player state as text, name of t, artist of t, album of t, duration of t, player position, id of t, artwork url of t}`. Ayrıştırma: `duration` **milisaniye** → `/1000` (sdef saniye dese de); `id` `spotify:ad:` ile başlıyorsa ya da ad boşsa → `nil` (reklam); kapak URL'si yalnızca `https` ise kabul. Kapak indirme: `URLSession`, `cacheDirectory/<trackID SHA-256>.jpg`, varsa diskten. `artworkKey = "spotify:" + id`.
CompositionRoot bu kaynağı yalnızca `#if LUNULA_SPOTIFY` altında kaydeder (MAS yapılandırmasında kapatılabilir; spec §5.1 MAS notu).

- [ ] **Step 1: Testler**

```swift
@Suite struct SpotifyScriptParserTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    func row(id: String = "spotify:track:1", name: String = "Song", duration: Double = 215_000, art: String = "https://i.scdn.co/image/ab") -> ScriptValue {
        .list([.text("playing"), .text(name), .text("Artist"), .text("Album"), .number(duration), .number(12.5), .text(id), .text(art)])
    }
    @Test func durationMillisecondsConvertedToSeconds() { #expect(SpotifyScriptParser.parse(row(), now: now)?.snapshot.duration == 215) }
    @Test func adReturnsNil() { #expect(SpotifyScriptParser.parse(row(id: "spotify:ad:xyz"), now: now) == nil) }
    @Test func emptyTitleReturnsNil() { #expect(SpotifyScriptParser.parse(row(name: ""), now: now) == nil) }
    @Test func rejectsNonHTTPSArtworkURL() { #expect(SpotifyScriptParser.parse(row(art: "http://x/y.jpg"), now: now)?.artworkURL == nil) }
}

@Suite struct SpotifySourceTests {
    @Test func appNotRunningProducesNilSnapshot() async {   // Review Focus #4
        let fake = FakeExecutor(result: .success(.none))
        let s = SpotifySource(runner: ScriptRunner(executor: fake, isRunning: { _ in false }), cacheDirectory: FileManager.default.temporaryDirectory)
        #expect(await s.snapshot(now: Date()) == nil && fake.callCount == 0)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (5 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): Spotify source with ms duration fix and https artwork cache"`

---

### T5.4 `NowPlayingCoordinator`

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/NowPlaying/NowPlayingCoordinator.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/NowPlaying/NowPlayingCoordinatorTests.swift`

**Interfaces:**
- Consumes: T1.1; T4.1 `ActivityProviding`, `AlertProviding`; T5.2 `NowPlayingSource`, `AutomationPermissionChecking`; T5.3; T5.5 `ArtworkAccentProviding`.
- Produces: `@MainActor @Observable final class NowPlayingCoordinator: ActivityProviding, AlertProviding { init(sources: [NowPlayingSource], center: NotificationCenter = DistributedNotificationCenter.default(), time: IslandTime, accents: ArtworkAccentProviding, permissions: AutomationPermissionChecking); private(set) var snapshot: NowPlayingSnapshot?; private(set) var accent: RGBAColor?; private(set) var permissions: [MediaSourceID: AutomationPermission]; private(set) var pendingConsent: MediaSourceID?; func start(); func stop(); func perform(_: PlaybackCommand) async; func setExpanded(_: Bool); func requestConsent(for: MediaSourceID) async; var activities: [Activity] }`

Davranış:
- `start()`: her kaynağın bildirimini **adıyla** gözle (adsız gözlem sandbox'ta çalışmaz); çalışan kaynakları bir kez sorgula. Bildirim yükü yalnızca **tetiktir**; durum her zaman betikle okunur.
- Bir kaynaktan çalan durum gelirse o kaynak **etkin** olur (en son değişen kazanır). Etkin kaynak duraklarsa `isPlaying = false`, etkinlik `expiresAt = duraklama + 600 sn` (10 dk sonra kaybolur).
- Parça kimliği değişince ve önceki parça varsa **bir** `trackChanged` uyarısı (`.normal`, 2.0 sn, `tint: .accent(renk)`, `detail: .track(...)`).
- Genişlemişken (`setExpanded(true)`) her 10 sn'de etkin kaynağı doğrulama sorgusu; kapalıyken sorgu yok.
- İzin: sorgudan önce `permissions.status(for:)`; `needsConsent` ise betik gönderilmez ve `pendingConsent = kaynak`. `permissionNeeded` uyarısı açılışta değil, o kaynaktan **ilk bildirim** geldiğinde (kullanıcı gerçekten müzik çalarken) ve oturum başına **bir kez** üretilir. `denied` ise sessiz (Ayarlar'daki izin merkezi gösterir, T9.2). Test yardımcıları `make(_:permissions:)`, `settle()` ve `NowPlayingCoordinator.make(sources:permissions:)` test hedefinde tanımlıdır.
- Etkinlik kimliği `"nowPlaying"`, vurgu `accent`.

- [ ] **Step 1: Testler** (`FakeSource`: betik yerine hazır anlık görüntüler döndürür, komutları kaydeder; `FakeAccents`; `FakePermissions`)

```swift
@MainActor @Suite struct NowPlayingCoordinatorTests {
    let time = ManualTime(); let center = NotificationCenter()
    @Test func mostRecentlyChangedSourceWins() async {
        let music = FakeSource(.music, playing: true), spotify = FakeSource(.spotify, playing: false)
        let c = make([music, spotify]); c.start(); await settle()
        spotify.state = .playing; center.post(name: spotify.notificationName, object: nil); await settle()
        #expect(c.snapshot?.source == .spotify)
    }
    @Test func pausedSourceExpiresAfter10Minutes() async {
        let music = FakeSource(.music, playing: false); let c = make([music]); c.start(); await settle()
        #expect(c.activities.first?.expiresAt == time.now.addingTimeInterval(600))
    }
    @Test func trackChangeRaisesAlertOnce() async {
        let music = FakeSource(.music, playing: true); let c = make([music]); var alerts = 0; c.onAlert = { _ in alerts += 1 }
        c.start(); await settle(); music.trackID = "2"; center.post(name: music.notificationName, object: nil); await settle()
        center.post(name: music.notificationName, object: nil); await settle()
        #expect(alerts == 1)
    }
    @Test func verificationQueriesOnlyWhileExpanded() async {
        let music = FakeSource(.music, playing: true); let c = make([music]); c.start(); await settle()
        let base = music.queryCount; time.advance(by: 30); await settle(); #expect(music.queryCount == base)
        c.setExpanded(true); time.advance(by: 10); await settle(); #expect(music.queryCount == base + 1)
    }
    @Test func commandsRoutedToActiveSource() async {
        let music = FakeSource(.music, playing: true); let c = make([music]); c.start(); await settle()
        await c.perform(.next); #expect(music.commands == [.next])
    }
    @Test func notificationPayloadIsOnlyATrigger() async {
        let music = FakeSource(.music, playing: true); let c = make([music]); c.start(); await settle()
        center.post(name: music.notificationName, object: nil, userInfo: ["Name": "SAHTE"]); await settle()
        #expect(c.snapshot?.title == music.title)
    }
    @Test func consentNeededSkipsScriptAndAlertsOncePerSession() async {
        let music = FakeSource(.music, playing: true); let perms = FakePermissions([.music: .needsConsent])
        let c = make([music], permissions: perms); var kinds: [AlertKind] = []; c.onAlert = { kinds.append($0.kind) }
        c.start(); await settle(); center.post(name: music.notificationName, object: nil); await settle()
        #expect(music.queryCount == 0 && kinds == [.permissionNeeded] && c.pendingConsent == .music)
    }
}
```
(`settle()` = birkaç `await Task.yield()`.)

- [ ] **Step 2–4:** FAIL → uygula → PASS (7 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): now playing coordinator with event-driven refresh"`

---

### T5.5 Kapak rengi çıkarımı

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/NowPlaying/{ArtworkColorExtractor,ArtworkAccentStore}.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/NowPlaying/ArtworkColorTests.swift`

**Interfaces:**
- Consumes: T1.10 `WeightedColor`, `ArtworkPalette`.
- Produces:
  - `enum ArtworkColorExtractor { static func weightedColors(from imageData: Data) -> [WeightedColor] }` — `CIImage(data:)` → 64 px'e `CILanczosScaleTransform` → `CIFilter.kMeans()` (`count = 4`, `passes = 5`, `perceptual = true`) → 4×1 RGBAf çıktı tek bir paylaşılan `CIContext` ile okunur; ağırlık = alfa kanalı (0 ise 1).
  - `protocol ArtworkAccentProviding: Sendable { func accent(for key: String, data: @Sendable () async -> Data?) async -> RGBAColor? }`
  - `actor ArtworkAccentStore: ArtworkAccentProviding` — anahtar başına sonuç önbelleği (en çok 50 giriş, LRU); hesap ana iş parçacığı dışında.

- [ ] **Step 1: Testler** (`ImageFixtures.png(color:size:)` CGContext ile düz renk PNG üretir)

```swift
@Suite struct ArtworkColorTests {
    @Test func solidRedImageGivesRedAccent() throws {
        let c = try #require(ArtworkPalette.accent(from: ArtworkColorExtractor.weightedColors(from: ImageFixtures.png(color: .init(red: 0.85, green: 0.1, blue: 0.1)))))
        #expect(c.hsl.hue < 0.03 || c.hsl.hue > 0.97)
    }
    @Test func blackImageGivesNoAccent() {
        #expect(ArtworkPalette.accent(from: ArtworkColorExtractor.weightedColors(from: ImageFixtures.png(color: .black))) == nil)
    }
    @Test func cachedAccentIsNotRecomputed() async {
        let store = ArtworkAccentStore(); var loads = 0
        let png = ImageFixtures.png(color: .init(red: 0.1, green: 0.5, blue: 0.9))
        _ = await store.accent(for: "k") { loads += 1; return png }
        _ = await store.accent(for: "k") { loads += 1; return png }
        #expect(loads == 1)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): artwork accent extraction with k-means and cache"`

---

### T5.6 Şimdi Çalıyor görünümleri

**Files:**
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/NowPlaying/{NowPlayingActions,NowPlayingCompact,NowPlayingExpandedCard,NowPlayingProgressBar,MarqueeText,ArtworkImage}.swift`
- Modify: `App/Resources/Localizable.xcstrings` (`nowPlaying.*`, erişilebilirlik etiketleri)
- Test: `Packages/IslandFeatures/Tests/IslandFeaturesTests/NowPlaying/NowPlayingViewTests.swift`

**Interfaces:**
- Consumes: T1.1 `NowPlayingSnapshot`; T2.1 token'lar.
- Produces:
  - `struct NowPlayingActions { var playPause, next, previous: () -> Void; var seek: (TimeInterval) -> Void; var artwork: (String) -> NSImage? }` + `EnvironmentValues.nowPlayingActions`.
  - `struct NowPlayingCompactLeading: View { init(snapshot:) }` — 20 pt kapak, köşe `Radii.artworkSmall`; kapak yoksa `music.note`.
  - `struct NowPlayingCompactTrailing: View { init(snapshot:) }` — `Image(systemName: "waveform").symbolEffect(.variableColor.iterative, options: .repeating, isActive: snapshot.isPlaying && !reduceMotion)`; vurgu renginde. (CPU T9.5'te ölçülür; bütçeyi aşarsa durağan simgeye düşülür.)
  - `struct NowPlayingExpandedCard: View { init(snapshot:accent:) }` — 64 pt kapak (`Radii.artworkLarge`), başlık (`TypeToken.title`, taşarsa yalnızca hover'da `MarqueeText`), sanatçı (`body`, ikincil), `NowPlayingProgressBar`, denetimler (`backward.fill`, `play.fill`/`pause.fill`, `forward.fill`; isabet alanı ≥ 28 pt).
  - `enum NowPlayingProgress { static func fraction(position: TimeInterval, duration: TimeInterval?) -> Double /* 0...1, süre yok/0 → 0 */ }`
  - `struct NowPlayingProgressBar: View` — `TimelineView(.periodic(from: .now, by: 1))` **yalnızca görünürken**; sürükleyerek konum; sürüklerken her 10 sn sınırında `HapticKind.generic`.

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct NowPlayingViewTests {
    @Test func progressFractionIsClamped() {
        #expect(NowPlayingProgress.fraction(position: 50, duration: 100) == 0.5)
        #expect(NowPlayingProgress.fraction(position: 150, duration: 100) == 1)
        #expect(NowPlayingProgress.fraction(position: 10, duration: nil) == 0)
    }
    @Test func compactAndExpandedRender() {
        let s = NowPlayingSnapshot.fixture()
        #expect(ImageRenderer(content: NowPlayingCompactLeading(snapshot: s)).cgImage != nil)
        #expect(ImageRenderer(content: NowPlayingExpandedCard(snapshot: s, accent: nil).frame(width: 492)).cgImage != nil)
    }
    @Test func longTurkishTitleStaysInsideCard() {   // Review Focus #3
        let s = NowPlayingSnapshot.fixture(title: "Gönülçelen Şarkılar Antolojisi — Uzun Versiyon Özel Kayıt", artist: "Müzeyyen Senar & İstanbul Senfoni Orkestrası")
        let r = ImageRenderer(content: NowPlayingExpandedCard(snapshot: s, accent: nil).frame(width: 492).environment(\.locale, Locale(identifier: "tr_TR")))
        #expect(r.cgImage?.width == Int(492 * r.scale))
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(features): now playing compact and expanded views"`
- **Entegrasyon notları:** `ActivityContentView` `.nowPlaying` dalları; `HomeCardView` `.nowPlaying`; `nowPlayingActions` ortamı coordinator'a bağlanır; `store` faz `expanded` olunca `coordinator.setExpanded(true)`.

---

### T5.7 Otomasyon izni akışı

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/NowPlaying/AutomationPermissionChecker.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/NowPlaying/PermissionCard.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/NowPlaying/AutomationPermissionTests.swift`

**Interfaces:**
- Consumes: T5.2 `AutomationPermission`, `AutomationPermissionChecking`; T5.4 `NowPlayingCoordinator` (test için).
- Produces:
  - `struct AutomationPermissionChecker: AutomationPermissionChecking` (protokol T5.2'de) — `AEDeterminePermissionToAutomateTarget(hedef tanımlayıcı, typeWildCard, typeWildCard, askUserIfNeeded)`; ana iş parçacığı dışında; `requestConsent` öncesinde `await MainActor.run { NSApp.activate() }`. `static func permission(forStatus: OSStatus) -> AutomationPermission`: `noErr` → `granted`, -1744 → `needsConsent`, -1743 → `denied`, -600 → `notRunning`.
  - `struct PermissionCard: View { init(source: MediaSourceID, onAllow: () -> Void) }` — tek cümle açıklama ("Lunula, Music'te çalanı göstermek için izin istiyor.") + "İzin ver" düğmesi; `HomeCard.permission` bu kartı kullanır.
  - Reddedildiğinde açılacak URL sabiti: `x-apple.systempreferences:com.apple.preference.security?Privacy_Automation` (T9.2 kullanır).

- [ ] **Step 1: Testler**

```swift
@Suite struct AutomationPermissionTests {
    @Test func statusCodesMapToPermission() {
        #expect(AutomationPermissionChecker.permission(forStatus: noErr) == .granted)
        #expect(AutomationPermissionChecker.permission(forStatus: -1744) == .needsConsent)
        #expect(AutomationPermissionChecker.permission(forStatus: -1743) == .denied)
        #expect(AutomationPermissionChecker.permission(forStatus: -600) == .notRunning)
    }
    @MainActor @Test func grantingConsentStartsSnapshotQuery() async {
        let music = FakeSource(.music, playing: true); let perms = FakePermissions([.music: .needsConsent], afterRequest: .granted)
        let c = NowPlayingCoordinator.make(sources: [music], permissions: perms); c.start(); await settle()
        await c.requestConsent(for: .music); await settle()
        #expect(c.pendingConsent == nil && music.queryCount == 1 && c.snapshot != nil)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (2 test).
- [ ] **Step 5: Cihazda doğrula** — temiz kullanıcı hesabında (veya `tccutil reset AppleEvents com.kutluhangul.lunula`): Music çal → adada tek uyarı → tıkla → Ev'de izin kartı → "İzin ver" → sistem izin penceresi → kabul → kapak ve başlık görünür. Reddet → uyarı bu oturumda tekrar gelmez.
- [ ] **Step 6: Commit** — `git commit -m "feat: automation consent flow without surprise prompts"`
- **Entegrasyon notları:** `hub.register(coordinator, feature: .nowPlaying)` (+ uyarılar); `HomeInputs.pendingPermission = coordinator.pendingConsent`, `hasNowPlaying = coordinator.snapshot != nil`; Ayarlar'a "Şimdi Çalıyor" satırı (T9.2).

**Faz 5 çıkış ölçütü:** Music ve Spotify'da çalan parça compact'ta kapak + dalga, expanded'da denetimler ve konum çubuğuyla görünür; uygulamalar kapalıyken **hiçbir** betik gönderilmez (Konsol'da doğrula); izin akışı cihazda geçer; müzik çalarken compact'ta `measure-idle.sh` medyanı < %1.
