# Faz 6 — Takvim ve Hava (Productivity Engineer ∥ Weather Engineer)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §5.3, §5.4, §6.4 (gün ışığı), §7 (kademeli izin)
> Önkoşul: T4.1. Takvim (T6.1→T6.2) ve Hava (T6.3→T6.4) iki bağımsız hat olarak paralel yürür.

---

### T6.1 `CalendarService` (EventKit)

**Files:**
- Create: `Packages/IslandServices/Sources/IslandServices/Calendar/{CalendarEventRecord,EventReading,EventKitReader,CalendarService}.swift`
- Test: `Packages/IslandServices/Tests/IslandServicesTests/Calendar/CalendarServiceTests.swift`

**Interfaces:**
- Consumes: T1.1 `EventSnapshot`, `IslandTime`; T1.6 `MeetingLinkDetector`; T4.1 `ActivityProviding`.
- Produces:
  - `struct CalendarEventRecord: Equatable, Sendable { id: String; title: String; start: Date; end: Date; isAllDay: Bool; calendarColor: RGBAColor?; location: String?; structuredLocationTitle: String?; url: URL?; notes: String?; isDeclined: Bool; isCanceled: Bool }`
  - `enum CalendarAuthorization: Equatable, Sendable { notDetermined, fullAccess, denied, restricted, writeOnly }`
  - `protocol EventReading: Sendable { func authorization() -> CalendarAuthorization; func requestAccess() async -> CalendarAuthorization; func events(from: Date, to: Date) async -> [CalendarEventRecord] }`
  - `final class EventKitReader: EventReading, @unchecked Sendable` — tek `EKEventStore`; `requestFullAccessToEvents()`; izin verilince `store.reset()`; `isDeclined` = `attendees` içinde `isCurrentUser` olanın `participantStatus == .declined`; `isCanceled` = `status == .canceled`.
  - `@MainActor @Observable final class CalendarService: ActivityProviding { init(reader: EventReading, time: IslandTime, center: NotificationCenter = .default); private(set) var nextEvent: EventSnapshot?; private(set) var allDayToday: [EventSnapshot]; private(set) var authorization: CalendarAuthorization; func start(); func requestAccess() async; var activities: [Activity] }`

Davranış: `start()` **asla izin istemez**; yalnızca `fullAccess` ise okur. Yenileme: başlangıçta, `.EKEventStoreChanged` geldiğinde, gece yarısında ve bir sonraki sınırda (`start − 600`, `start + 300`) — tek zamanlayıcı. Pencere: `now … now + 12 saat`; tüm gün, reddedilmiş ve iptal edilmiş etkinlikler `nextEvent` olamaz (tüm gün olanlar `allDayToday`'e). Toplantı bağlantısı: `MeetingLinkDetector.detect(in: [url?.absoluteString, location, structuredLocationTitle, notes])`. Etkinlik (`id = "calendar.<eventID>"`) yalnızca `[start − 600, start + 300)` aralığında vardır; vurgu takvim rengi. Okuma `Task` içinde ana iş parçacığı dışında yapılır.

- [ ] **Step 1: Testler** (`FakeReader`: sabit kayıtlar, `requestAccess` çağrı sayacı)

```swift
@MainActor @Suite struct CalendarServiceTests {
    let time = ManualTime()
    func rec(_ id: String, startsIn s: TimeInterval, allDay: Bool = false, declined: Bool = false, canceled: Bool = false, notes: String? = nil) -> CalendarEventRecord {
        .init(id: id, title: id, start: time.now.addingTimeInterval(s), end: time.now.addingTimeInterval(s + 1800), isAllDay: allDay, calendarColor: nil,
              location: nil, structuredLocationTitle: nil, url: nil, notes: notes, isDeclined: declined, isCanceled: canceled)
    }
    @Test func nextEventSkipsAllDayDeclinedAndCanceled() async {
        let r = FakeReader(.fullAccess, [rec("allday", startsIn: 60, allDay: true), rec("no", startsIn: 120, declined: true), rec("x", startsIn: 180, canceled: true), rec("ok", startsIn: 240)])
        let s = CalendarService(reader: r, time: time); s.start(); await settle()
        #expect(s.nextEvent?.eventID == "ok" && s.allDayToday.map(\.eventID) == ["allday"])
    }
    @Test func activityExistsOnlyFromTenMinutesBeforeToFiveAfter() async {
        let s = CalendarService(reader: FakeReader(.fullAccess, [rec("m", startsIn: 900)]), time: time); s.start(); await settle()
        #expect(s.activities.isEmpty)
        time.advance(by: 300); await settle(); #expect(s.activities.count == 1)      // 10 dk kala
        time.advance(by: 900); await settle(); #expect(s.activities.isEmpty)         // başlangıç + 5 dk
    }
    @Test func storeChangeTriggersRefresh() async {
        let center = NotificationCenter(); let r = FakeReader(.fullAccess, [])
        let s = CalendarService(reader: r, time: time, center: center); s.start(); await settle()
        r.records = [rec("new", startsIn: 600)]; center.post(name: .EKEventStoreChanged, object: nil); await settle()
        #expect(s.nextEvent?.eventID == "new")
    }
    @Test func noAccessEmitsNothingAndNeverPrompts() async {
        let r = FakeReader(.notDetermined, [rec("m", startsIn: 60)])
        let s = CalendarService(reader: r, time: time); s.start(); await settle()
        #expect(s.activities.isEmpty && s.nextEvent == nil && r.requestCount == 0)
    }
    @Test func meetingLinkAttached() async {
        let s = CalendarService(reader: FakeReader(.fullAccess, [rec("m", startsIn: 60, notes: "https://meet.google.com/abc-defg-hij")]), time: time)
        s.start(); await settle(); #expect(s.nextEvent?.meetingLink?.service == .googleMeet)
    }
}
```

- [ ] **Step 2–4:** `swift test --package-path Packages/IslandServices --filter CalendarServiceTests` → FAIL → uygula → PASS (5 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): EventKit calendar service with boundary refresh"`

---

### T6.2 Takvim görünümleri

**Files:**
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Calendar/{CalendarActions,CalendarLabel,CalendarCompact,CalendarExpandedCard,NextEventTile,CalendarAccessTile}.swift`
- Modify: `App/Resources/Localizable.xcstrings` (`calendar.*`)
- Test: `Packages/IslandFeatures/Tests/IslandFeaturesTests/Calendar/CalendarViewTests.swift`

**Interfaces:**
- Consumes: T1.1 `EventSnapshot`.
- Produces:
  - `struct CalendarActions { var join: (URL) -> Void; var requestAccess: () -> Void }` + `EnvironmentValues.calendarActions`.
  - `enum CalendarLabelState: Equatable { countdown, now, started }`; `enum CalendarLabel { static func state(start: Date, now: Date) -> CalendarLabelState }` — `start − now > 60` → `countdown`; `−60 … 60` → `now`; `< −60` → `started`.
  - `CalendarCompactLeading` (takvim renginde 6 pt nokta + bağlantı varsa `video.fill`), `CalendarCompactTrailing` (`countdown` → `Text(timerInterval: now...start, countsDown: true)`; `now` → "Şimdi"; `started` → "Başladı"), `CalendarExpandedCard` (başlık 2 satır, `Text(start, format: .dateTime.hour().minute())`–`end`, konum, yalnızca bağlantı varsa "Katıl" düğmesi), `NextEventTile` ("Sıradaki" + saat + başlık), `CalendarAccessTile` ("Takvimi bağla" → `requestAccess`; istekten önce `NSApp.activate()`).

- [ ] **Step 1: Testler**

```swift
@MainActor @Suite struct CalendarViewTests {
    let now = Date(timeIntervalSinceReferenceDate: 0)
    @Test func labelSwitchesAroundStart() {
        #expect(CalendarLabel.state(start: now.addingTimeInterval(300), now: now) == .countdown)
        #expect(CalendarLabel.state(start: now.addingTimeInterval(30), now: now) == .now)
        #expect(CalendarLabel.state(start: now.addingTimeInterval(-120), now: now) == .started)
    }
    @Test func joinButtonOnlyWithMeetingLink() {
        #expect(CalendarExpandedCard(event: .fixture(meetingLink: nil)).showsJoinButton == false)
        #expect(CalendarExpandedCard(event: .fixture(meetingLink: .init(service: .zoom, url: URL(string: "https://zoom.us/j/1")!))).showsJoinButton)
    }
    @Test func viewsRender() {
        #expect(ImageRenderer(content: CalendarExpandedCard(event: .fixture()).frame(width: 492)).cgImage != nil)
        #expect(ImageRenderer(content: NextEventTile(event: .fixture()).frame(width: 160)).cgImage != nil)
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(features): calendar compact, card and home tiles"`
- **Entegrasyon notları:** `hub.register(calendar, feature: .calendar)`; `ActivityContentView` `.calendar` dalları; `HomeCardView` `.meeting`, `.nextEvent`, `.calendarAccess`; `HomeInputs.hasImminentMeeting / hasUpcomingEvent / calendarAccessUndetermined`; `calendarActions.join` → `NSWorkspace.shared.open(url)`; Ayarlar'a "Takvim" satırı (T9.2).

---

### T6.3 Hava servisi (Open-Meteo)

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Weather/WeatherProviding.swift`
- Create: `Packages/IslandServices/Sources/IslandServices/Weather/{OpenMeteoParser,OpenMeteoProvider,WeatherCache,LocationService,WeatherService}.swift`
- Create: `Packages/IslandServices/Tests/IslandServicesTests/Resources/{open-meteo-forecast.json,open-meteo-geocoding-tr.json}` (+ `Package.swift`'te test kaynakları — Integrator)
- Modify: `App/Sources/Settings/AboutSettingsView.swift` (atıf satırı)
- Test: `Packages/IslandServices/Tests/IslandServicesTests/Weather/{OpenMeteoParserTests,WeatherServiceTests}.swift`

**Interfaces:**
- Consumes: T1.1 `WeatherSnapshot`, `WeatherCondition`; T1.9 `WeatherLocationSetting`.
- Produces:
  - `struct GeoPlace: Equatable, Sendable, Codable { name: String; admin1: String?; country: String?; latitude: Double; longitude: Double }`
  - `protocol WeatherProviding: Sendable { func current(latitude: Double, longitude: Double, now: Date) async throws -> WeatherSnapshot; func search(_ query: String, language: String) async throws -> [GeoPlace] }` (IslandCore)
  - `enum OpenMeteoParser { static func forecast(_: Data, fetchedAt: Date) throws -> WeatherSnapshot; static func places(_: Data) throws -> [GeoPlace]; static func condition(wmoCode: Int) -> WeatherCondition; static func forecastURL(latitude: Double, longitude: Double) -> URL; static func geocodingURL(query: String, language: String) -> URL }`
  - `struct OpenMeteoProvider: WeatherProviding { init(session: URLSession = .shared) }`
  - `struct WeatherCache: Sendable { init(fileURL: URL); func load() -> WeatherSnapshot?; func save(_: WeatherSnapshot); static func isFresh(_: WeatherSnapshot, now: Date, maxAge: TimeInterval = 1800) -> Bool }`
  - `protocol LocationProviding: Sendable { func currentCoordinate() async throws -> (latitude: Double, longitude: Double) }`; `final class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate` — tek seferlik `requestLocation()`, `desiredAccuracy = kCLLocationAccuracyThreeKilometers`; yetki gerekiyorsa önce `NSApp.activate()` sonra `requestWhenInUseAuthorization()`; macOS'ta izinli durumlar `.authorizedAlways`/`.authorized`.
  - `@MainActor @Observable final class WeatherService { init(provider: WeatherProviding, cache: WeatherCache, location: LocationProviding, settings: SettingsStore, time: IslandTime); private(set) var snapshot: WeatherSnapshot?; func islandBecameVisible() async }`

Sabitler: tahmin URL'si `https://api.open-meteo.com/v1/forecast?latitude=<2 ondalık>&longitude=<2 ondalık>&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto&forecast_days=1` (koordinatlar 2 ondalığa yuvarlanır: gizlilik + önbellek). Coğrafi kodlama `https://geocoding-api.open-meteo.com/v1/search?name=<yüzde-kodlu>&count=5&language=<tr|en>&format=json`. WMO eşlemesi: 0 → clear; 1, 2 → partlyCloudy; 3 → cloudy; 45, 48 → fog; 51–57 → drizzle; 61–67, 80–82 → rain; 71–77, 85, 86 → snow; 95–99 → thunderstorm; diğer → cloudy. Davranış: `islandBecameVisible()` yalnızca önbellek bayatsa (> 30 dk) ağ isteği yapar; ağ hatasında son değer korunur; konum: ayar `.city` ise koordinatları, `.automatic` ise `LocationService`. Yer adı yalnızca elle seçilen şehir için gösterilir (ters coğrafi kodlama yok). Atıf (Hakkında): "Hava durumu verileri: Open-Meteo.com (CC BY 4.0)".

- [ ] **Step 1: Testler**

```swift
@Suite struct OpenMeteoParserTests {
    @Test(arguments: [(0, WeatherCondition.clear), (2, .partlyCloudy), (3, .cloudy), (45, .fog), (53, .drizzle), (63, .rain),
                      (81, .rain), (73, .snow), (86, .snow), (95, .thunderstorm), (99, .thunderstorm), (42, .cloudy)])
    func wmoCodesMapToConditions(code: Int, expected: WeatherCondition) { #expect(OpenMeteoParser.condition(wmoCode: code) == expected) }
    @Test func parsesForecastFixture() throws {
        let s = try OpenMeteoParser.forecast(Fixture.data("open-meteo-forecast.json"), fetchedAt: .distantPast)
        #expect(s.temperatureC == 18.4 && s.highC == 21.2 && s.lowC == 12.9 && s.condition == .partlyCloudy && s.isDaylight)
    }
    @Test func parsesGeocodingFixtureInTurkish() throws {
        #expect(try OpenMeteoParser.places(Fixture.data("open-meteo-geocoding-tr.json")).first?.name == "İzmir")
    }
    @Test func forecastURLRoundsCoordinates() {
        #expect(OpenMeteoParser.forecastURL(latitude: 41.008237, longitude: 28.978358).query?.contains("latitude=41.01&longitude=28.98") == true)
    }
}

@MainActor @Suite struct WeatherServiceTests {
    let time = ManualTime()
    @Test func cacheServedWithin30Minutes() async {
        let p = FakeWeather(); let s = make(provider: p, cached: .fixture(fetchedAt: time.now.addingTimeInterval(-600)))
        await s.islandBecameVisible(); #expect(p.calls == 0 && s.snapshot != nil)
    }
    @Test func staleCacheFetches() async {
        let p = FakeWeather(); let s = make(provider: p, cached: .fixture(fetchedAt: time.now.addingTimeInterval(-3600)))
        await s.islandBecameVisible(); #expect(p.calls == 1)
    }
    @Test func networkFailureKeepsLastCachedValue() async {
        let cached = WeatherSnapshot.fixture(fetchedAt: time.now.addingTimeInterval(-3600))
        let s = make(provider: FakeWeather(fails: true), cached: cached)
        await s.islandBecameVisible(); #expect(s.snapshot == cached)
    }
    @Test func nothingFetchedUntilIslandVisible() async {
        let p = FakeWeather(); _ = make(provider: p, cached: nil); await settle(); #expect(p.calls == 0)
    }
}
```
Fikstür JSON'ları gerçek bir Open-Meteo yanıtından alınıp (tek seferlik `curl`) yukarıdaki değerlere göre düzenlenir; `make(provider:cached:)` geçici dizinde `WeatherCache` ve sahte konum kurar.

- [ ] **Step 2–4:** FAIL → uygula → PASS (15 + 4 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(services): Open-Meteo weather with cache and visible-only refresh"`

---

### T6.4 Hava karosu ve gün ışığı hâlesi

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Weather/DaylightPhase.swift`
- Create: `Packages/IslandDesign/Sources/IslandDesign/Tokens/Daylight.swift`
- Create: `Packages/IslandFeatures/Sources/IslandFeatures/Weather/{WeatherSymbol,WeatherTileView}.swift`
- Modify: `App/Resources/Localizable.xcstrings` (`weather.condition.*` 8 anahtar, TR + EN)
- Test: `Packages/IslandCore/Tests/IslandCoreTests/Weather/DaylightPhaseTests.swift`, `Packages/IslandFeatures/Tests/IslandFeaturesTests/Weather/WeatherTileTests.swift`

**Interfaces:**
- Consumes: T1.1 `WeatherSnapshot`; T1.5 `IslandFormat.temperature`, `UnitPreferences`.
- Produces:
  - `enum DaylightPhase: Equatable, Sendable { dawn, day, dusk, night; static func phase(now: Date, sunrise: Date?, sunset: Date?, isDaylight: Bool) -> DaylightPhase }` — gün doğumu ±45 dk → `dawn`; gün batımı ±45 dk → `dusk`; arası `day`; dışı `night`; saatler yoksa `isDaylight ? .day : .night`.
  - `enum Daylight { static func color(_: DaylightPhase) -> RGBAColor }` — dawn `#FFB3C1`, day `#FFFFFF`, dusk `#FF9F43`, night `#6E8BFF` (yalnızca Ev'de, `HaloLevel.ambient` yoğunluğunun yarısıyla).
  - `enum WeatherSymbol { static func name(_: WeatherCondition, isDaylight: Bool) -> String }` — clear `sun.max.fill`/`moon.stars.fill`; partlyCloudy `cloud.sun.fill`/`cloud.moon.fill`; cloudy `cloud.fill`; fog `cloud.fog.fill`; drizzle `cloud.drizzle.fill`; rain `cloud.rain.fill`; snow `cloud.snow.fill`; thunderstorm `cloud.bolt.rain.fill`.
  - `struct WeatherTileView: View { init(snapshot: WeatherSnapshot, units: UnitChoice) }` — simge (çok renkli), sıcaklık, "Y 21° D 13°", durum metni (`weather.condition.<case>`), elle seçilen şehir varsa yer adı.

- [ ] **Step 1: Testler**

```swift
@Suite struct DaylightPhaseTests {
    let sunrise = Date(timeIntervalSinceReferenceDate: 6 * 3600), sunset = Date(timeIntervalSinceReferenceDate: 18 * 3600)
    @Test func dawnWindowIs45MinutesAroundSunrise() {
        #expect(DaylightPhase.phase(now: sunrise.addingTimeInterval(-40 * 60), sunrise: sunrise, sunset: sunset, isDaylight: false) == .dawn)
        #expect(DaylightPhase.phase(now: sunrise.addingTimeInterval(50 * 60), sunrise: sunrise, sunset: sunset, isDaylight: true) == .day)
    }
    @Test func nightAfterDusk() {
        #expect(DaylightPhase.phase(now: sunset.addingTimeInterval(2 * 3600), sunrise: sunrise, sunset: sunset, isDaylight: false) == .night)
    }
    @Test func missingTimesFallBackToIsDaylight() { #expect(DaylightPhase.phase(now: sunrise, sunrise: nil, sunset: nil, isDaylight: true) == .day) }
}

@MainActor @Suite struct WeatherTileTests {
    @Test func symbolExistsForEveryCondition() {
        for c in WeatherCondition.allCases { for day in [true, false] {
            #expect(NSImage(systemSymbolName: WeatherSymbol.name(c, isDaylight: day), accessibilityDescription: nil) != nil, "\(c) \(day)")
        } }
    }
    @Test func tileRendersLongestTurkishConditionWithinTile() {   // Review Focus #3
        let tile = WeatherTileView(snapshot: .fixture(condition: .thunderstorm), units: .init(temperature: .celsius, speed: .kilometersPerHour))
            .frame(width: 160).environment(\.locale, Locale(identifier: "tr_TR"))
        let r = ImageRenderer(content: tile); #expect(r.cgImage?.width == Int(160 * r.scale))
    }
}
```

- [ ] **Step 2–4:** FAIL → uygula → PASS (3 + 2 test).
- [ ] **Step 5: Cihazda doğrula (Review Focus #3)** — sistem dili Türkçe, bölge Türkiye: karo °C gösterir, "Gök gürültülü fırtına" kesilmez; dil İngilizce + bölge ABD: °F. Ekran görüntüleri `docs/qa/shots/weather-tr.png`, `weather-en.png`.
- [ ] **Step 6: Commit** — `git commit -m "feat: weather tile with daylight halo tint"`
- **Entegrasyon notları:** `HomeCardView` `.weather`; `HomeInputs.hasWeather`; faz `expanded(.home)` olunca `weather.islandBecameVisible()`; Ayarlar'a **Hava** sekmesi (konum: otomatik / şehir arama → `provider.search`, birim tercihi).

**Faz 6 çıkış ölçütü:** takvim izni yalnızca karoya tıklayınca istenir; 10 dk kala compact geri sayım ve "Katıl" çalışır; hava Ev'de görünür, 30 dk içinde ikinci istek atılmaz (Konsol/ağ günlüğü); Türkçe yerelde birimler doğru.
