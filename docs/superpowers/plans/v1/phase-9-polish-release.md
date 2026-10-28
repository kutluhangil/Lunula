# Faz 9 — Cila, erişilebilirlik, performans ve sürüm

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §1, §6, §7, §8, §10, §11
> Önkoşul: Faz 4–8. T9.1, T9.2, T9.3 paralel; T9.4 ve T9.5 onlardan sonra; T9.6 cihaz matrisi; T9.7 en son.
> Bu fazın görevlerinde "test" çoğunlukla ölçüm ve kontrol listesidir; her adımın çıktısı belgeye yazılır.

---

### T9.1 İlk açılış deneyimi (Design Engineer)

**Files:**
- Create: `App/Sources/Onboarding/{OnboardingWindowController,OnboardingView,OnboardingLightAnimation}.swift`
- Create: `Packages/IslandCore/Sources/IslandCore/Coexistence/CompetingApps.swift`, `App/Sources/Onboarding/CompetingAppNotice.swift`
- Test: `App/Tests/OnboardingTests.swift`, `Packages/IslandCore/Tests/IslandCoreTests/Coexistence/CompetingAppsTests.swift`

**Interfaces:**
- Consumes: T1.9 `IslandSettings.hasCompletedOnboarding`; T3.8 `LaunchAtLoginService`; T2.3 hâle.
- Produces: `@MainActor final class OnboardingWindowController: NSWindowController { init(settings: SettingsStore, launchAtLogin: LaunchAtLoginService, onFinish: @escaping () -> Void); static func shouldShow(_: IslandSettings) -> Bool }` — tek ekran: siyah zemin üzerinde adanın notch çevresinde ışıkla belirdiği ≤ 2 sn animasyon (Hareketi Azalt → statik), bir cümlelik tanıtım, "Girişte başlat" anahtarı (varsayılan kapalı), "Başla" düğmesi. **Hiçbir izin istenmez** (spec §7).
- Çakışma uyarısı (spec §4.5): `enum CompetingApps { static let bundleIDs: Set<String>; static func detect(running: [String], alreadyNotified: Set<String>) -> String? }` — bilinen notch uygulamalarının paket kimlikleri (Boring Notch, NotchNook, Alcove, Atoll, NotchDrop, MewNotch, DynamicNotch, Sapphire, MediaMate); liste T9.6'da cihazda `mdls -name kMDItemCFBundleIdentifier /Applications/<Uygulama>.app` ile doğrulanır. Açılışta ve `NSWorkspace.didLaunchApplicationNotification`'da kontrol; her uygulama için **bir kez** adada nazik bir geçici uyarı ("<Uygulama> da notch'u kullanıyor; ikisi üst üste binebilir"), `settings`'te bildirilenler saklanır.

- [ ] **Step 1: Testler** — `shouldShowOnlyBeforeCompletion` (`hasCompletedOnboarding == false` → true), `finishingMarksCompletedAndDoesNotRegisterLoginItemUnlessToggled` (sahte `LoginItemControlling` çağrı almaz), `CompetingAppsTests.detectsKnownCompetitorOnce` (`detect(running: [boringNotchID], alreadyNotified: [])` → kimlik; `alreadyNotified` içindeyse → `nil`).
- [ ] **Step 2–4:** FAIL → uygula → PASS (3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(app): one-screen onboarding without permission prompts"`

---

### T9.2 İzin merkezi ve etkinlik ayarları (Integrator + özellik sahipleri)

**Files:**
- Create: `App/Sources/Settings/{ActivitiesSettingsView,PermissionRow,AppearanceSettingsView}.swift`
- Test: `App/Tests/PermissionRowTests.swift`

**Interfaces:**
- Consumes: T5.7 `AutomationPermission` + Sistem Ayarları URL'si; T6.1 `CalendarAuthorization`; T6.3 `LocationService` durumu; T1.9 `enabledFeatures`, `haloIntensity`, `hapticsEnabled`, `soundsEnabled`.
- Produces: `enum PermissionState: Equatable { notRequested, granted, denied, unavailable }`; `struct PermissionRow: View { init(titleKey:, state:, onRequest:, onOpenSettings:) }` — `denied` → "Sistem Ayarları'nı aç" (Otomasyon: `x-apple.systempreferences:com.apple.preference.security?Privacy_Automation`, Takvim: `…?Privacy_Calendars`, Konum: `…?Privacy_LocationServices`); `ActivitiesSettingsView` her `IslandFeature` için aç/kapa + ilgili izin satırı; `AppearanceSettingsView`: hâle yoğunluğu kaydırıcısı (0–1), dokunsal, ses.

- [ ] **Step 1: Testler** — `deniedShowsOpenSettingsButton`, `grantedShowsNoAction`, `everyFeatureHasToggle` (`IslandFeature.allCases.count` satır).
- [ ] **Step 2–4:** FAIL → uygula → PASS (3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(app): permission center and appearance settings"`

---

### T9.3 Yerelleştirme geçişi (Localization & Docs)

**Files:**
- Modify: `App/Resources/{Localizable,InfoPlist,AppShortcuts}.xcstrings`
- Create: `App/Tests/LocalizationTests.swift`, `docs/qa/l10n-glossary.md`

**Interfaces:**
- Produces: `LocalizationTests.everyStringHasTurkishAndEnglish` — üç katalog JSON olarak okunur (`Bundle.main` kaynakları), her anahtarın `en` ve `tr` yerelleştirmesi `state == "translated"` ve boş değil; `LocalizationTests.noStringContainsExclamationMark` (spec §6.8: ünlem yok). Sözlük (`l10n-glossary.md`): ada = island, raf = shelf, hâle = halo, geçici uyarı = alert, "Katıl" = Join … ve ton kuralları (kısa, fiil öncelikli).

- [ ] **Step 1:** Testleri yaz → çalıştır → eksik çevirilerle FAIL.
- [ ] **Step 2:** Eksik çevirileri tamamla; Xcode "Double-Length Pseudolanguage" ve "Right-to-Left" şema seçenekleriyle adayı aç, taşma olan her yeri düzelt (ekran görüntüleri `docs/qa/shots/pseudo-*.png`).
- [ ] **Step 3:** PASS (2 test) → `git commit -m "chore(l10n): complete Turkish and English catalogs"`

---

### T9.4 Erişilebilirlik geçişi (Design Engineer — `design:accessibility-review` becerisiyle)

**Files:**
- Modify: Faz 3–8 görünümleri (yalnızca erişilebilirlik değiştiricileri)
- Create: `App/Tests/AccessibilityTests.swift`, `docs/qa/accessibility.md`

**Interfaces:**
- Produces: ada kökü `accessibilityElement(children: .contain)` + etiket "Lunula, <birincil etkinlik özeti>" + `.isButton`; her denetim etiketli (oynat/duraklat durumuna göre değişen etiket); Ev sayfaları ←/→ ile gezilebilir; Hareketi Azalt / Şeffaflığı Azalt / Kontrastı Artır her bileşende uygulanmış; vurgu renkleri siyah üzerinde ≥ 3:1 (T1.10), metin ≥ 4.5:1.
- Tüm denetim etiketleri tek yerde: `Packages/IslandFeatures/Sources/IslandFeatures/Accessibility/AccessibilityLabels.swift` (`enum AccessibilityLabels { static func playPause(isPlaying: Bool) -> LocalizedStringResource; static let next, previous, seek, startTimer, pauseTimer, join, removeShelfItem, openSettings: LocalizedStringResource; static func island(summary: String) -> LocalizedStringResource }`); görünümler `.accessibilityLabel(Text(AccessibilityLabels.…))` kullanır.
- `AccessibilityTests`: `everyLabelResolvesInTurkishAndEnglish` (her etiket `String(localized:locale:)` ile `tr` ve `en`'de boş değil ve anahtarın kendisi değil), `textColorsMeetContrast` (`textPrimary`, `textSecondary` siyah üzerinde ≥ 4.5).

- [ ] **Step 1:** Testleri yaz → FAIL → düzelt → PASS.
- [ ] **Step 2:** VoiceOver ile tam tur (Motor, Şimdi Çalıyor, Zamanlayıcı, Takvim, Raf, Ayarlar); bulguları ve düzeltmeleri `docs/qa/accessibility.md`'ye yaz.
- [ ] **Step 3:** `git commit -m "feat(a11y): labels, keyboard navigation and contrast checks"`

---

### T9.5 Performans geçişi (QA & Performance)

**Files:**
- Modify: sıcak noktalar (ölçüme göre)
- Create: `App/Sources/Support/Signposts.swift`
- Modify: `docs/qa/perf-log.md`

**Interfaces:**
- Produces: `enum Signposts { static let island = OSSignposter(subsystem: "com.kutluhangul.lunula", category: "island") }` — açılış/kapanış geçişleri, betik çağrıları, hava isteği, renk çıkarımı aralık olarak işaretlenir.

- [ ] **Step 1: Ölç** (Release, `/Applications`'a kopyalanmış derleme, 120 Hz ekran):
  - Boşta, etkinlik yok: `measure-idle.sh --seconds 120 --assert-idle` → CPU medyanı < %0.1, uyanma < 1/sn.
  - Müzik çalıyor (compact): `measure-idle.sh --seconds 120` → CPU medyanı < %1.
  - Zamanlayıcı çalışıyor: < %1.
  - Instruments **Animation Hitches**: 20 kez aç/kapa → kare kaybı yok; **Time Profiler**: ilk kare < 16 ms.
  - Bellek: 8 saat açık bırak (müzik + zamanlayıcı döngüsü) → < 120 MB ve düz.
  - Düşük Güç Modu açık → nefes animasyonu yok.
- [ ] **Step 2:** Bütçeyi aşan her madde için kök nedeni bul (`superpowers:systematic-debugging`), düzelt, tekrar ölç. Bilinen geri dönüş: `waveform` sembol efekti bütçeyi aşarsa durağan simge.
- [ ] **Step 3:** Tüm sonuçları tarih/cihaz/OS ile `docs/qa/perf-log.md`'ye yaz → `git commit -m "perf: signposts and budget verification"`

---

### T9.6 Cihaz matrisi QA'sı (QA & Performance)

**Files:**
- Modify: `docs/qa/checklist.md` (tüm bölümler), `Packages/IslandCore/Sources/IslandCoreTestSupport/ScreenFixtures.swift` (gerçek ölçümler)

- [ ] **Step 1:** Erişilebilen her cihazda (14"/16" MacBook Pro, MacBook Air, notch'suz Mac + harici ekran, kapak kapalı) `ScreenDescriptor(NSScreen.main!)` değerlerini günlüğe yaz; gerçek değerleri test fikstürlerine ekle ve `NotchGeometryTests`'e her cihaz için `notchRectMatchesDevice_<model>` testi ekle.
- [ ] **Step 2:** `docs/qa/checklist.md`'nin tüm bölümlerini macOS 26 ve macOS 27'de uygula; her başarısızlık için ayrı görev aç (GitHub issue), düzeltilmeden sürüm yok.
- [ ] **Step 3:** `git commit -m "test(qa): device matrix results and real notch fixtures"`

---

### T9.7 Sürüm hattı (Integrator)

**Files:**
- Create: `.github/workflows/release.yml`, `Scripts/release/{build-dmg.sh,notarize.sh}`, `docs/release.md`, `CHANGELOG.md`

**Interfaces:**
- `release.yml`: `v*` etiketiyle tetiklenir, `macos-26`; Release derleme → `Scripts/release/build-dmg.sh` (`hdiutil create -format UDZO`) → GitHub Secrets (`DEVELOPER_ID_CERT_P12`, `DEVELOPER_ID_CERT_PASSWORD`, `APPSTORE_CONNECT_KEY_ID`, `APPSTORE_CONNECT_ISSUER_ID`, `APPSTORE_CONNECT_KEY_P8`, `DEVELOPMENT_TEAM`) ile geçici anahtar zincirine sertifika yükle → Developer ID ile imzala (`--options runtime --timestamp`, **`--deep` yok**) → `xcrun notarytool submit --wait` → `xcrun stapler staple` → `spctl -a -vv` doğrulaması → GitHub Release'e yükle. Sırlardan biri eksikse iş **başarısız olur** (imzasız sürüm yayımlanmaz).
- `docs/release.md` (kullanıcının Developer Program üyeliği var): Developer ID Application sertifikasının oluşturulması (yalnızca Account Holder), `.p12` dışa aktarımı, App Store Connect API anahtarı, GitHub Secrets'a eklenmesi, yerelde `xcrun notarytool store-credentials lunula-notary` ile deneme, sürüm etiketleme adımları. Sparkle bu sürümde yok (backlog).
- Yayından önce: "Lunula" için TÜRKPATENT, USPTO ve EUIPO (sınıf 9 ve 42) marka taraması; sonuç `docs/release.md`'ye.

- [ ] **Step 1:** Yerelde `Scripts/release/build-dmg.sh` → `build/Lunula-0.1.0.dmg` oluşur; `spctl -a -vv` sonucu belgeye yazılır.
- [ ] **Step 2:** Bir `v0.1.0-rc1` etiketiyle iş akışını dene; yapıt GitHub Release'te görünür.
- [ ] **Step 3:** `git commit -m "ci: release workflow with optional notarization"`

**Faz 9 / v1.0 çıkış ölçütü:** spec §2.1'deki F1–F10'un her kabul ölçütü cihazda işaretli; spec §8 bütçesi ölçülmüş ve tutuyor; tüm testler ve CI yeşil; `docs/release.md` hangi yolun izlendiğini söylüyor; `v1.0.0` etiketi.
