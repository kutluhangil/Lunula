# Faz 7 — Raf ve sistem sinyalleri (Shelf & Signals Engineer)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §5.5, §5.6
> Önkoşul: T4.1 (T7.2 ayrıca T3.3'e bağlı). T7.1→T7.2 bir hat; T7.3, T7.4, T7.5 birbirinden bağımsız.
> **Odak (Focus) v1'de yok** (spec §2.2): `INFocusStatusCenter` Communication Notifications yetkisi ister ve App Review riski taşır → backlog.

---

### T7.1 `ShelfStore`

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/Shelf/{ShelfItem,BookmarkCoding,ShelfStore}.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/Shelf/ShelfStoreTests.swift`

**Interfaces:**
- Consumes: T1.1 `IslandTime`; T1.9 `SettingsStore` (`shelfCopiesFiles`, `shelfRetentionDays`).
- Produces:
  - `struct ShelfItem: Identifiable, Codable, Equatable, Sendable { id: UUID; displayName: String; addedAt: Date; storage: ShelfStorage; byteCount: Int64? }`; `enum ShelfStorage: Codable, Equatable, Sendable { reference(bookmark: Data), copy(relativePath: String) }`; `enum ShelfItemStatus: Equatable, Sendable { available(URL), missing }`
  - `protocol BookmarkCoding: Sendable { func bookmark(for: URL) throws -> Data; func resolve(_: Data) throws -> (url: URL, isStale: Bool) }`; `struct SecurityScopedBookmarkCoding: BookmarkCoding` (`.withSecurityScope`, çözümlemede `.withSecurityScope`); `struct PlainBookmarkCoding: BookmarkCoding` (testler için, kapsam yok).
  - `@MainActor @Observable final class ShelfStore { init(directory: URL, bookmarks: BookmarkCoding, time: IslandTime, settings: SettingsStore); private(set) var items: [ShelfItem]; func add(_ urls: [URL]) throws; func remove(_ id: UUID); func status(of: ShelfItem) -> ShelfItemStatus; func withAccess<T>(to: ShelfItem, _ body: (URL) throws -> T) rethrows -> T?; func cleanUp() }`
  - `enum ShelfLimits { static let maxItems = 64 }`

Davranış: kalıcılık `<directory>/items.json`; kopyalar `<directory>/Files/<uuid>/<ad>`. Varsayılan **referans** (spec §5.5); ayar açıksa kopya. `withAccess` referanslarda `startAccessingSecurityScopedResource()` / `stop…` çiftini garanti eder. Bayat yer imi çözülünce yenilenir ve kaydedilir. Aynı dosya tekrar eklenirse kopya oluşmaz, öğe en üste taşınır. 64'ü aşınca en eski düşer. Temizlik: açılışta ve günde bir (tek zamanlayıcı) `retentionDays`'ten eski öğeler; `nil` = asla. Kopya silinince dosyası da silinir.

- [ ] **Step 1: Testler** (geçici dizin, `PlainBookmarkCoding`)

```swift
@MainActor @Suite struct ShelfStoreTests {
    let time = ManualTime()
    func make(copy: Bool = false, retention: Int? = 7) throws -> (ShelfStore, URL) {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        settings.update { $0.shelfCopiesFiles = copy; $0.shelfRetentionDays = retention }
        return (ShelfStore(directory: dir, bookmarks: PlainBookmarkCoding(), time: time, settings: settings), dir)
    }
    func tempFile(_ name: String = "a.txt") throws -> URL {
        let u = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString)-\(name)"); try Data("x".utf8).write(to: u); return u
    }
    @Test func addingFilePersistsAcrossInstances() throws {
        let (s, dir) = try make(); try s.add([tempFile()])
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(ShelfStore(directory: dir, bookmarks: PlainBookmarkCoding(), time: time, settings: settings).items.count == 1)
    }
    @Test func missingOriginalShowsAsMissing() throws {
        let (s, _) = try make(); let f = try tempFile(); try s.add([f]); try FileManager.default.removeItem(at: f)
        #expect(s.status(of: s.items[0]) == .missing)
    }
    @Test func copyModeSurvivesOriginalDeletion() throws {
        let (s, _) = try make(copy: true); let f = try tempFile(); try s.add([f]); try FileManager.default.removeItem(at: f)
        guard case .available = s.status(of: s.items[0]) else { Issue.record("copy should survive"); return }
    }
    @Test func cleanupRemovesItemsOlderThanRetention() throws {
        let (s, _) = try make(retention: 7); try s.add([tempFile()]); time.advance(by: 8 * 86_400); s.cleanUp()
        #expect(s.items.isEmpty)
    }
    @Test func neverRetentionKeepsItems() throws {
        let (s, _) = try make(retention: nil); try s.add([tempFile()]); time.advance(by: 365 * 86_400); s.cleanUp()
        #expect(s.items.count == 1)
    }
    @Test func removeDeletesCopiedFile() throws {
        let (s, dir) = try make(copy: true); try s.add([tempFile()]); s.remove(s.items[0].id)
        #expect((try? FileManager.default.contentsOfDirectory(atPath: dir.appending(path: "Files").path()))?.isEmpty ?? true)
    }
    @Test func duplicateAddMovesToTop() throws {
        let (s, _) = try make(); let a = try tempFile("a"), b = try tempFile("b"); try s.add([a]); try s.add([b]); try s.add([a])
        #expect(s.items.count == 2 && s.items.first?.displayName.hasSuffix("a") == true)
    }
    @Test func maxItemsDropsOldest() throws {
        let (s, _) = try make(); for _ in 0..<65 { try s.add([tempFile()]) }
        #expect(s.items.count == 64)
    }
}
```

- [ ] **Step 2–4:** `--filter ShelfStoreTests` → FAIL → uygula → PASS (8 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): shelf store with security-scoped references and retention"`

---

### T7.2 Raf arayüzü ve sürükleme mıknatısı

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Pointer/DragProximity.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Shelf/{ShelfActions,ShelfPage,ShelfItemView,ShelfEmptyView}.swift`
- Create: `App/Sources/Window/FileDragMonitor.swift`
- Modify: `App/Resources/Localizable.xcstrings` (`shelf.*`)
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Pointer/DragProximityTests.swift`, `Packages/IslandFeatures/Tests/IslandFeaturesTests/Shelf/ShelfPageTests.swift`

**Interfaces:**
- Consumes: T7.1 `ShelfItem`, `ShelfItemStatus`; T3.4 `IslandStore.send`.
- Produces:
  - `enum DragProximity { static let band: CGFloat = 120; static func isApproaching(point: CGPoint, screenFrame: CGRect) -> Bool }` — nokta ekranın içinde ve `screenFrame.maxY − band` üstünde.
  - `struct ShelfItemModel: Identifiable, Equatable { id: UUID; name: String; icon: NSImage; isReference: Bool; isMissing: Bool }`
  - `struct ShelfSelection: Equatable { private(set) var ids: Set<UUID>; mutating func click(_ id: UUID, command: Bool) /* ⌘ yoksa tek seçim, ⌘ ile ekle/çıkar */; mutating func clear() }` — seçili öğeler birlikte sürüklenir, AirDrop'lanır ve kaldırılır (spec §5.5 çoklu seçim).
  - `struct ShelfActions { var add: ([URL]) -> Void; var remove: (UUID) -> Void; var reveal: (UUID) -> Void; var airDrop: (UUID) -> Void; var share: (UUID, NSView) -> Void; var dragItem: (UUID) -> NSItemProvider? }` + ortam değeri.
  - `struct ShelfPage: View { init(items: [ShelfItemModel]) }` — 4 sütun ızgara; öğe: simge, ad (11 pt, 2 satır), referanssa `link` rozeti, kayıpsa soluk + `exclamationmark.triangle`; hover'da `×`; bağlam menüsü: Finder'da göster, AirDrop (`NSSharingService(named: .sendViaAirDrop)`), Paylaş… (`NSSharingServicePicker`), Kaldır; `.onDrop(of: [.fileURL])` → `add` + `HapticKind.levelChange`; boşken "Dosyaları buraya bırak" (`tray`).
  - `@MainActor final class FileDragMonitor { init(screens: @escaping @MainActor () -> [ScreenDescriptor], send: @escaping @MainActor (UInt32, IslandEvent) -> Void); func start(); func stop() }` — `NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp])` (yalnızca sürüklemede tetiklenir; boşta maliyet yok). Sürüklemede `NSPasteboard(name: .drag)` `changeCount` son `mouseUp`'tan farklı ve türler `.fileURL` içeriyorsa, imleç bir ekranın bandına girince o ekrana **bir kez** `.fileDragApproached`; banttan çıkınca ya da `mouseUp`'ta `.fileDragLeft`.

- [ ] **Step 1: Testler**

```swift
@Suite struct DragProximityTests {
    let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    @Test func pointWithin120ptOfTopApproaches() { #expect(DragProximity.isApproaching(point: CGPoint(x: 700, y: 900), screenFrame: screen)) }
    @Test func pointBelowBandDoesNot() { #expect(!DragProximity.isApproaching(point: CGPoint(x: 700, y: 800), screenFrame: screen)) }
    @Test func pointOnOtherScreenDoesNot() { #expect(!DragProximity.isApproaching(point: CGPoint(x: 2000, y: 950), screenFrame: screen)) }
}

@MainActor @Suite struct ShelfPageTests {
    @Test func rendersEmptyAndFilled() {
        #expect(ImageRenderer(content: ShelfPage(items: []).frame(width: 492, height: 140)).cgImage != nil)
        let item = ShelfItemModel(id: UUID(), name: "Sunum.key", icon: NSImage(systemSymbolName: "doc", accessibilityDescription: nil)!, isReference: true, isMissing: false)
        #expect(ImageRenderer(content: ShelfPage(items: [item]).frame(width: 492, height: 140)).cgImage != nil)
    }
    @Test func airDropServiceIsAvailable() { #expect(NSSharingService(named: .sendViaAirDrop) != nil) }
    @Test func commandClickTogglesSelection() {
        let a = UUID(), b = UUID(); var s = ShelfSelection()
        s.click(a, command: false); s.click(b, command: true); #expect(s.ids == [a, b])
        s.click(a, command: true); #expect(s.ids == [b]); s.click(a, command: false); #expect(s.ids == [a])
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (3 + 3 test).
- [ ] **Step 5: Cihazda doğrula** — Finder'dan dosyayı ekranın üstüne sürükle → ada rafa açılır (mıknatıs) → bırak → dokunsal tık; raftan Masaüstü'ne sürükle; AirDrop paneli açılır; uygulamayı yeniden başlat → öğeler durur; orijinali sil → "bulunamadı".
- [ ] **Step 6: Commit** — `git commit -m "feat: shelf page, AirDrop/share and drag magnet"`
- **Entegrasyon notları:** `ShelfActions` → `ShelfStore` (ikon: `NSWorkspace.shared.icon(forFile:)` erişim bloğu içinde); `FileDragMonitor.start()`; Ayarlar'a **Raf** sekmesi (kopyala/bağlantı, temizleme süresi: 1 / 7 / 30 gün / asla).

---

### T7.3 Güç servisi ve pil uyarıları

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Signals/BatteryAlertRules.swift`
- Create: `Packages/IslandServices/Sources/IslandServices/Power/{PowerSourceParser,PowerMonitor}.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Signals/BatteryAlertRulesTests.swift`, `Packages/IslandServices/Tests/IslandServicesTests/Power/PowerSourceParserTests.swift`

**Interfaces:**
- Consumes: T1.1 `BatterySnapshot`, `TransientAlert`; T4.1 `AlertProviding`.
- Produces:
  - `struct BatteryAlertSession: Equatable, Sendable { var fullShownThisPlug = false; var lowShown: Set<Int> = [] }`; `enum BatteryAlertRules { static func alerts(from old: BatterySnapshot?, to new: BatterySnapshot, session: inout BatteryAlertSession) -> [TransientAlert] }`
  - `enum PowerSourceParser { static func snapshot(from description: [String: Any], providingSource: String, lowPowerMode: Bool) -> BatterySnapshot }` — anahtarlar: `kIOPSCurrentCapacityKey`, `kIOPSMaxCapacityKey`, `kIOPSIsChargingKey`, `kIOPSPowerSourceStateKey` (`"AC Power"`/`"Battery Power"`), `"Is Charged"`; pil yoksa `hasBattery = false`.
  - `@MainActor @Observable final class PowerMonitor: AlertProviding { init(); private(set) var battery: BatterySnapshot?; private(set) var isLowPowerMode: Bool; func start() }` — `IOPSNotificationCreateRunLoopSource` (C geri çağrısı, bağlam `Unmanaged` ile; Copy/Create → `takeRetainedValue`, Get → `takeUnretainedValue`), `ProcessInfo.isLowPowerModeEnabled` + `.NSProcessInfoPowerStateDidChange`. İzin/yetki gerekmez.

Kurallar: `hasBattery == false` → hiç uyarı. İlk anlık görüntü (`old == nil`) → uyarı yok. Takıldı → `charging` (2.6 sn, `.green`, `.normal`, `detail: .batteryLevel`). Çıkarıldı → `unplugged` (2.0 sn, `.neutral`, `.normal`) ve `fullShownThisPlug = false`, `lowShown` sıfırlanmaz. Pildeyken 20'nin altına iniş (`old.level > 20 ≥ new.level`) → `batteryLow` (2.6 sn, `.orange`, `.high`) bir kez; 10 → ikinci `batteryLow` (`.critical`); takılınca `lowShown` sıfırlanır. Takılıyken `isCharged` ya da `level == 100` ve `!fullShownThisPlug` → `batteryFull` (2.0 sn, `.green`, `.normal`).

- [ ] **Step 1: Testler**

```swift
@Suite struct BatteryAlertRulesTests {
    func b(_ level: Int, plugged: Bool, charged: Bool = false, hasBattery: Bool = true) -> BatterySnapshot {
        .init(level: level, isCharging: plugged && !charged, isPluggedIn: plugged, isCharged: charged, isLowPowerMode: false, hasBattery: hasBattery)
    }
    @Test func firstSnapshotEmitsNothing() { var s = BatteryAlertSession(); #expect(BatteryAlertRules.alerts(from: nil, to: b(50, plugged: true), session: &s).isEmpty) }
    @Test func pluggingInRaisesChargingAlert() { var s = BatteryAlertSession(); #expect(BatteryAlertRules.alerts(from: b(50, plugged: false), to: b(50, plugged: true), session: &s).map(\.kind) == [.charging]) }
    @Test func unpluggingRaisesUnpluggedAlert() { var s = BatteryAlertSession(); #expect(BatteryAlertRules.alerts(from: b(50, plugged: true), to: b(50, plugged: false), session: &s).map(\.kind) == [.unplugged]) }
    @Test func crossing20DownRaisesLowOnce() {
        var s = BatteryAlertSession()
        #expect(BatteryAlertRules.alerts(from: b(21, plugged: false), to: b(20, plugged: false), session: &s).map(\.kind) == [.batteryLow])
        #expect(BatteryAlertRules.alerts(from: b(20, plugged: false), to: b(19, plugged: false), session: &s).isEmpty)
    }
    @Test func crossing10DownRaisesCriticalLow() {
        var s = BatteryAlertSession(lowShown: [20])
        #expect(BatteryAlertRules.alerts(from: b(11, plugged: false), to: b(10, plugged: false), session: &s).first?.priority == .critical)
    }
    @Test func noLowAlertWhileCharging() { var s = BatteryAlertSession(); #expect(BatteryAlertRules.alerts(from: b(21, plugged: true), to: b(20, plugged: true), session: &s).isEmpty) }
    @Test func fullAlertOncePerPlugSession() {
        var s = BatteryAlertSession()
        #expect(BatteryAlertRules.alerts(from: b(99, plugged: true), to: b(100, plugged: true, charged: true), session: &s).map(\.kind) == [.batteryFull])
        #expect(BatteryAlertRules.alerts(from: b(100, plugged: true, charged: true), to: b(100, plugged: true, charged: true), session: &s).isEmpty)
    }
    @Test func desktopWithoutBatteryEmitsNothing() {
        var s = BatteryAlertSession(); #expect(BatteryAlertRules.alerts(from: b(0, plugged: false, hasBattery: false), to: b(0, plugged: true, hasBattery: false), session: &s).isEmpty)
    }
}

@Suite struct PowerSourceParserTests {
    @Test func parsesBatteryDescription() {
        let d: [String: Any] = [kIOPSCurrentCapacityKey: 54, kIOPSMaxCapacityKey: 100, kIOPSIsChargingKey: true, kIOPSPowerSourceStateKey: kIOPSACPowerValue]
        #expect(PowerSourceParser.snapshot(from: d, providingSource: kIOPMACPowerKey, lowPowerMode: false)
                == BatterySnapshot(level: 54, isCharging: true, isPluggedIn: true, isCharged: false, isLowPowerMode: false, hasBattery: true))
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (8 + 1 test).
- [ ] **Step 5: Commit** — `git commit -m "feat: battery alerts from IOKit power source notifications"`
- **Entegrasyon notları:** `hub.register(alerts: power, feature: .battery)`; `HaloAccessibility.lowPowerMode = power.isLowPowerMode`.

---

### T7.4 İndirmeler izleyicisi

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Signals/DownloadTracker.swift`
- Create: `Packages/IslandServices/Sources/IslandServices/Downloads/DownloadsWatcher.swift`
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Signals/DownloadTrackerTests.swift`, `Packages/IslandServices/Tests/IslandServicesTests/Downloads/DownloadsWatcherTests.swift`

**Interfaces:**
- Consumes: T1.1 `TransientAlert`; T4.1 `AlertProviding`.
- Produces:
  - `struct FileEntry: Hashable, Sendable { name: String; size: Int64 }`; `struct DownloadTracker: Sendable { static let temporaryExtensions: Set<String> = ["crdownload", "download", "part", "partial", "opdownload", "tmp"]; mutating func ingest(_ entries: Set<FileEntry>) -> [FileEntry] }` — ilk çağrı taban çizgisidir (mevcut dosyalar için uyarı yok); gizli (`.` ile başlayan) ve geçici uzantılı dosyalar yok sayılır; yeni bir dosya, **ardışık iki** `ingest`'te aynı boyutla görülünce bir kez bildirilir.
  - `@MainActor final class DownloadsWatcher: AlertProviding { init(directory: URL = DownloadsWatcher.realDownloadsDirectory(), stabilityDelay: Duration = .milliseconds(1200)); func start(); func stop(); static func realDownloadsDirectory() -> URL }` — gerçek ev dizini `getpwuid(getuid()).pw_dir` + `/Downloads`, sembolik bağlar çözülür (sandbox kabındaki `Downloads` bir bağdır). İzleme: dizin tanımlayıcısı (`O_EVTONLY`) üzerinde `DispatchSource.makeFileSystemObjectSource(eventMask: .write)` → 0.5 sn birleştirme → liste + `ingest`; yeni ama henüz kararsız dosya varsa `stabilityDelay` sonra bir kez daha. Uyarı: `downloadFinished`, 2.6 sn, `.normal`, `detail: .file(name:url:)`.

- [ ] **Step 1: Testler**

```swift
@Suite struct DownloadTrackerTests {
    @Test func existingFilesAtStartAreBaseline() { var t = DownloadTracker(); #expect(t.ingest([.init(name: "old.pdf", size: 10)]).isEmpty) }
    @Test func fileReportedOnceWhenSizeStable() {
        var t = DownloadTracker(); _ = t.ingest([])
        #expect(t.ingest([.init(name: "a.zip", size: 5)]).isEmpty)
        #expect(t.ingest([.init(name: "a.zip", size: 5)]).map(\.name) == ["a.zip"])
        #expect(t.ingest([.init(name: "a.zip", size: 5)]).isEmpty)
    }
    @Test func temporaryAndHiddenFilesIgnored() {
        var t = DownloadTracker(); _ = t.ingest([])
        let tmp: Set<FileEntry> = [.init(name: "a.zip.crdownload", size: 5), .init(name: ".DS_Store", size: 1), .init(name: "b.part", size: 2)]
        _ = t.ingest(tmp); #expect(t.ingest(tmp).isEmpty)
    }
    @Test func renamedFromCrdownloadIsReported() {
        var t = DownloadTracker(); _ = t.ingest([]); _ = t.ingest([.init(name: "a.zip.crdownload", size: 9)])
        _ = t.ingest([.init(name: "a.zip", size: 9)]); #expect(t.ingest([.init(name: "a.zip", size: 9)]).map(\.name) == ["a.zip"])
    }
}

@MainActor @Suite struct DownloadsWatcherTests {
    @Test func realDownloadsPathIsNotInsideContainer() { #expect(!DownloadsWatcher.realDownloadsDirectory().path().contains("/Library/Containers/")) }
    @Test func watcherAlertsForNewFile() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let w = DownloadsWatcher(directory: dir, stabilityDelay: .milliseconds(200)); var names: [String] = []
        w.onAlert = { if case .file(let n, _) = $0.detail { names.append(n) } }; w.start()
        try Data(count: 100).write(to: dir.appending(path: "rapor.pdf")); try await Task.sleep(for: .seconds(2))
        #expect(names == ["rapor.pdf"]); w.stop()
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (4 + 2 test).
- [ ] **Step 5: Commit** — `git commit -m "feat: download finished alerts without polling"`
- **Entegrasyon notları:** `hub.register(alerts: downloads, feature: .downloads)`; `AlertActions.reveal` → `NSWorkspace.shared.activateFileViewerSelecting`, `addToShelf` → `ShelfStore.add` (salt okunur kapsamlı yer imi: `.securityScopeAllowOnlyReadAccess`).

---

### T7.5 Kamera / mikrofon kullanım göstergesi

**Files:**
- Create: `docs/qa/spikes/camera-microphone-indicator.md`
- Create: `Packages/IslandServices/Sources/IslandServices/Privacy/{DeviceUsageReading,DeviceUsageMonitor}.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Signals/PrivacyDotView.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/Privacy/DeviceUsageMonitorTests.swift`, `Packages/IslandFeatures/Tests/IslandFeaturesTests/Signals/PrivacyDotTests.swift`

**Interfaces:**
- Consumes: T1.1 `PrivacySnapshot`; T3.5 `PrivacySlot`.
- Produces:
  - `protocol DeviceUsageReading: AnyObject { var onChange: (() -> Void)? { get set }; func cameraInUse() -> Bool; func microphoneInUse() -> Bool; func start(); func stop() }`
  - `final class SystemDeviceUsageReader: DeviceUsageReading` — mikrofon: her giriş aygıtında `kAudioDevicePropertyDeviceIsRunningSomewhere` dinleyicisi, `kAudioHardwarePropertyDevices` değişince yeniden tarama; kamera: spike sonucuna göre `AVCaptureDevice.isInUseByAnotherApplication` KVO (tercih) ya da `kCMIODevicePropertyDeviceIsRunningSomewhere`.
  - `@MainActor @Observable final class DeviceUsageMonitor { init(reader: DeviceUsageReading); private(set) var privacy: PrivacySnapshot; func start() }`
  - `struct PrivacyDotView: View { init(privacy: PrivacySnapshot) }` — notch'un sağında 6 pt nokta(lar): kamera `Palette.signalGreen`, mikrofon `Palette.signalOrange` (macOS renkleri); ikisi birden → 4 pt arayla iki nokta; ikisi de kapalı → hiçbir şey.
  - `enum PrivacyDotColors { static func colors(for: PrivacySnapshot) -> [Color] }`

- [ ] **Step 1: Cihazda spike (karar kuralıyla)** — sandbox'lı Debug derlemesinde, `device.camera`/`device.audio-input` yetkisi **olmadan**: (a) `AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external], mediaType: .video, position: .unspecified).devices` ve `isInUseByAnotherApplication` KVO; (b) CoreMediaIO özelliği; (c) CoreAudio özelliği. FaceTime'ı açıp kapatarak değerleri ve `log stream --style compact --predicate 'eventMessage CONTAINS "deny"'` çıktısını kaydet; TCC izin penceresi çıktı mı? Sonucu `docs/qa/spikes/camera-microphone-indicator.md`'ye yaz. **Karar:** yetkisiz ve izin penceresiz çalışıyorsa → olduğu gibi; yalnızca yetki gerekip izin penceresi çıkmıyorsa → Integrator yetkiyi `project.yml`'a ekler (spec §9 güncellenir); izin penceresi çıkıyorsa → o aygıt v1'den çıkar, backlog'a yazılır (yalnızca mikrofon ya da hiç gösterge). Kullanıcıyı şaşırtan bir izin istemi **kabul edilmez** (ilke 5).
- [ ] **Step 2: Testler**

```swift
@MainActor @Suite struct DeviceUsageMonitorTests {
    @Test func monitorPublishesChangesFromReader() {
        let r = FakeUsageReader(); let m = DeviceUsageMonitor(reader: r); m.start()
        r.camera = true; r.onChange?()
        #expect(m.privacy == PrivacySnapshot(cameraInUse: true, microphoneInUse: false))
    }
}

@Suite struct PrivacyDotTests {
    @Test func dotColorsMatchSystemConvention() {
        #expect(PrivacyDotColors.colors(for: .init(cameraInUse: true, microphoneInUse: true)) == [Palette.signalGreen, Palette.signalOrange])
        #expect(PrivacyDotColors.colors(for: .none).isEmpty)
    }
}
```

- [ ] **Step 3–5:** FAIL → uygula → PASS (1 + 1 test).
- [ ] **Step 6: Commit** — `git commit -m "feat: camera/microphone in-use indicator (per spike decision)"`
- **Entegrasyon notları:** `PrivacySlot` içinde `PrivacyDotView(privacy: monitor.privacy)` (`settings.enabledFeatures.contains(.privacyIndicator)` ise).

**Faz 7 çıkış ölçütü:** raf sürükle-bırak/AirDrop/kalıcılık cihazda geçer; şarj tak/çıkar, %20 inişi (pil simülasyonu yerine gerçek ya da `pmset -g batt` gözlemiyle) ve indirme bitişi uyarı üretir; spike kararları belgelenmiş; boşta CPU hâlâ ~%0.
