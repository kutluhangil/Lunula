# Lunula v2 — Tasarım Modları (Alcove / Boring / Liquid Glass), Su Damlası Fiziği ve 7 Yeni Özellik Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan phase-by-phase. Steps use checkbox (`- [ ]`) syntax for tracking. Do **not** run `git commit` or `git push` without explicit user instruction (`~/Neural-Vault/Core/Kurallar.md`).

**Goal:** Lunula'ya su damlası (water-droplet) imleç esneme fiziği, seçilebilir `Lunula v2 / Alcove Minimal / Boring Expressive` tasarım dilleri, hem `#000000` Obsidyen Siyah hem gerçek macOS 26 `Liquid Glass` (`.glassEffect`) yüzey seçeneği ve GitHub rakip analizinden çıkan 7 eksik özelliği (Yüzen Bırakma Sepeti, Dar Kanat Canlı Şarkı Sözü, Canlı Ağ Hızı, Ada İçi Mini AI Hızlı Sor, Hızlı Ekran/GIF Kaydedici, Canlı Ses Spektrumu ve Kamera Aynası) eksiksiz eklemek.

**Architecture:** Mevcut 4 yerel Swift paketi (`IslandCore` saf mantık → `IslandDesign` token/şekil/cam/hareket → `IslandServices` sistem bağdaştırıcıları → `IslandFeatures` SwiftUI görünümleri) ve `App/` (`CompositionRoot` tekli bağlayıcı) sınırları korunur. Paylaşılan dosyalar (`project.yml`, `CompositionRoot.swift`, `HomeCardView.swift`) ana oturum (Integrator) tarafından birleştirilir; her faz kendi birim testleriyle doğrulanır.

**Tech Stack:** Swift 6 (`strict concurrency`), SwiftUI + AppKit (macOS 26 Tahoe `.glassEffect`), CoreAudio (`CATapDescription` Process Tap + `Accelerate/vDSP`), `AVFoundation` (`AVCaptureSession`), `ScreenCaptureKit` (`SCRecordingOutput` + `ImageIO` GIF), POSIX `getifaddrs`, Security `Keychain`.

**Spec:** `docs/design/lunula-benchmark-mockup.html` ve `docs/superpowers/specs/2026-10-28-v1-design.md`

## Global Constraints

- **App Sandbox + Hardened Runtime** her derlemede açık kalır (`Scripts/check-entitlements.sh`).
- **Özel API yasağı (`Scripts/check-architecture.sh`):** Sistem ses/parlaklık HUD değişimi (`CoreBrightness`), Kilit Ekranı widget'ları (`SLSWindow`), Face Unlock ve Pencere değiştirici (`AXUIElement`) bilinçli kapsam dışıdır ve eklenmez.
- **Sıfır sürpriz izin istemi:** Kamera (`AVCaptureSession`), Sistem Sesi (`CATapDescription`) ve Ekran Kaydı (`ScreenCaptureKit`) **asla uygulama açılışında çalışmaz**; yalnızca kullanıcı ilgili özelliği bizzat açtığında/tıkladığında başlar, kapanınca anında durur.
- **Sıfır arka plan yoklaması:** Ağ hızı, ses spektrumu ve su damlası fiziği yalnızca ilgili görünüm açık/etkileşimdeyken çalışır; boşta `< %0.1` CPU bütçesi korunur.
- **Tasarım değişmezleri:** En küçük yazı `11 pt`, yay sıçraması `≤ 0.12`, geçiş süresi `≤ 2.0 sn`, `Reduce Motion` / `Reduce Transparency` / `Increase Contrast` tam uyumlu, tüm metinler TR + EN String Catalog içinde ve `!` içermez.
- **Sır güvenliği:** Mini AI API anahtarı yalnızca macOS Keychain içinde saklanır; `UserDefaults` veya diske düz metin yazılmaz.

## Review Focus

1. **Liquid Glass modunda donanım çentiği uyumu:** `.liquidGlass` seçiliyken donanım çentiğinin tam kamera kesim dikdörtgeni (`notch.size.width × notch.size.height`) opak `#000000` kalarak fiziksel çentiği gizlemeli; kanatlar ve genişleyen gövde `.glassEffect` almalı; `Reduce Transparency` açıkken otomatik `#000000`'a düşmeli.
2. **Su damlası fiziğinde üst kenar kilidi:** İmleç adanın üzerinde gezerken sol/sağ duvarlar ve alt menisküs su damlası gibi esnemeli ancak çentikli ekranda üst kenar (`y = 0`) ekran çerçevesinden asla ayrılmamalı; imleç çıkınca `.zero`'a yaylanmalı; `Reduce Motion` açıkken devre dışı kalmalı.
3. **CoreAudio Process Tap sessizlik ve izin düşüşü:** Kullanıcı Sistem Sesi Kaydı iznini reddederse CoreAudio `0.0` sessizlik döner; `AudioSpectrumService` tüm bantlar sıfırken zarifçe simüle ritmik dalgaya düşmeli ve ada kapanınca aggregate aygıtı/tap'i tamamen serbest bırakmalı.
4. **Kamera Aynası gizlilik garantisi:** `AVCaptureSession` yalnızca Ayna görünümü ekrandayken (`onAppear`) çalışmalı; sekme değiştiğinde veya ada kapandığında (`onDisappear`) `stopRunning()` çağrılıp yeşil kamera ışığı sönmeli.
5. **Ekran/GIF kaydı sandbox dosya yolu:** Kayıt doğrudan uygulama geçici dizinine (`FileManager.default.temporaryDirectory`) yazılıp bitince `ShelfStore.add([url])` ile Rafa eklenmeli; rastgele klasörlere yazmaya çalışıp sandbox hatası üretmemeli.

---

## Faz Planı

### Faz 1: Su Damlası (Water-Droplet) İmleç Fiziği ve Akışkan Kenar Kırılması
- **Files:**
  - Create: `Packages/IslandCore/Sources/IslandCore/Interaction/DropletPhysics.swift`
  - Create: `Packages/IslandCore/Tests/IslandCoreTests/Interaction/DropletPhysicsTests.swift`
  - Create: `Packages/IslandDesign/Sources/IslandDesign/Shape/FluidIslandShape.swift`
  - Create: `Packages/IslandDesign/Tests/IslandDesignTests/Shape/FluidIslandShapeTests.swift`
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`waterDropletEffect: Bool = true`)
  - Modify: `Packages/IslandCore/Tests/IslandCoreTests/Settings/IslandSettingsTests.swift`
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Tools/QuickToolsActions.swift` (`waterDropletEffect`, `pointerTension`)
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Root/IslandSurface.swift`
  - Modify: `App/Sources/Window/IslandWindowController.swift`, `App/Sources/Window/PointerRouter.swift`, `App/Sources/Settings/AppearanceSettingsView.swift`, `App/Resources/Localizable.xcstrings`, `App/Sources/CompositionRoot.swift`
- [x] **Step 1:** `DropletPhysics` (`DropletTension`: `pullX`, `pullY`, `focusX`, `intensity`; imleç konum + hızından sınırlandırılmış yüzey gerilimi hesabı) ve `DropletPhysicsTests` yaz.
- [x] **Step 2:** `FluidIslandShape` (`Animatable` Bézier menisküs esnemesi, üst kenar `y = 0` kilitli, mevcut `IslandShape` testlerini bozmadan) + su damlası iç ışık yansıması (`DropletSpecularHighlight`) ve `FluidIslandShapeTests` yaz.
- [x] **Step 3:** `IslandContainerView` / `HotZoneView` üzerinden panel-içi imleç noktasını `CompositionRoot` → `IslandSurface` içine bağla; `AppearanceSettingsView` içine `Su damlası imleç esnemesi` anahtarı ekle; testleri çalıştır.

### Faz 2: Alcove + Boring Notch Tasarım Stilleri, 3. "Araçlar" Sekmesi ve macOS 26 Liquid Glass Yüzeyi
- **Files:**
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`visualStyle: IslandVisualStyle`, `surfaceMaterial: IslandSurfaceMaterial`)
  - Modify: `Packages/IslandCore/Sources/IslandCore/State/IslandState.swift` (`IslandPage.tools`), `Packages/IslandFeatures/Sources/IslandFeatures/Root/PageCycler.swift`
  - Create: `Packages/IslandDesign/Sources/IslandDesign/Surface/IslandSurfaceMaterialModifier.swift`
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Root/IslandSurface.swift`, `ExpandedView.swift`, `NowPlayingExpandedCard.swift`
  - Modify: `App/Sources/Settings/AppearanceSettingsView.swift`, `SettingsStagePreview.swift`, `App/Resources/Localizable.xcstrings`, `Packages/IslandFeatures/Sources/IslandFeatures/Resources/Localizable.xcstrings`, `App/Sources/CompositionRoot.swift`
  - Test: `IslandSettingsTests.swift`, `PageCyclerTests.swift`, `IslandRootViewTests.swift`
- [x] **Step 1:** `IslandVisualStyle` (`.lunula`, `.alcove`, `.boring`) ve `IslandSurfaceMaterial` (`.obsidian`, `.liquidGlass`) modellerini `IslandSettings` içine ekle.
- [x] **Step 2:** `IslandSurfaceMaterialModifier` ile `.liquidGlass` modunda macOS 26 `.glassEffect(.regular, in: shape)` + donanım çentiği `#000000` üst kapak maskesini uygula (`Reduce Transparency` / `Increase Contrast` korumalı).
- [x] **Step 3:** `ExpandedView` içinde 3. `Araçlar` (`IslandPage.tools`) sekmesini, `Alcove Minimal` (araç çubuksuz tek odak kahraman kartı) ve `Boring Expressive` (radyal kapak ambiyansı + ekolayzer şeridi + sağ mini takvim kutusu) düzenlerini uygula; `AppearanceSettingsView` seçicilerini bağla.

### Faz 3: Dar Kanat Canlı Şarkı Sözü, Canlı Ağ Hızı Telemetrisi ve Yüzen Dosya Bırakma Sepeti
- **Files:**
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`compactWingLyrics: Bool = true`, `floatingShelfBasket: Bool = true`)
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/NowPlaying/NowPlayingCompact.swift`, `Packages/IslandCore/Sources/IslandCore/Layout/IslandMetrics.swift`
  - Modify: `Packages/IslandServices/Sources/IslandServices/System/SystemStatsService.swift` (POSIX `getifaddrs` byte sayaçlarından `downloadBytesPerSec` / `uploadBytesPerSec`)
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Tools/QuickToolsActions.swift`, `QuickToolPopovers.swift`
  - Create: `App/Sources/Window/FloatingShelfBasketController.swift`
  - Modify: `App/Sources/Window/FileDragMonitor.swift`, `App/Sources/Settings/AppearanceSettingsView.swift`, `App/Sources/Settings/ActivitiesSettingsView.swift`, `App/Sources/CompositionRoot.swift`
  - Test: `NowPlayingViewTests.swift`, `SystemStatsTests.swift`, `IslandPanelTests.swift`
- [x] **Step 1:** `SystemStatsService` içine `getifaddrs` tabanlı anlık `downloadBytesPerSec` / `uploadBytesPerSec` hesaplayıcısını ekle ve `SystemStatsPopover` + Lunula v2 Ev 3. mikro karosunda göster.
- [x] **Step 2:** `NowPlayingCompact` sağ kanadında `compactWingLyrics` açıkken aktif senkronize şarkı sözünü (`11 pt`) göster.
- [x] **Step 3:** `FloatingShelfBasketController` ile ekranın herhangi bir yerinde dosya sürüklenirken kenarda açılan, bırakılan dosyaları doğrudan `ShelfStore`'a ekleyen yüzen bırakma sepetini oluştur.

### Faz 4: Ada İçi Mini AI Hızlı Sor (Yerel Ollama + Keychain BYOK)
- **Files:**
  - Create: `Packages/IslandCore/Sources/IslandCore/AI/QuickAIConfig.swift`
  - Create: `Packages/IslandServices/Sources/IslandServices/AI/KeychainSecretStore.swift`
  - Create: `Packages/IslandServices/Sources/IslandServices/AI/QuickAIService.swift`
  - Create: `Packages/IslandServices/Tests/IslandServicesTests/AI/QuickAIServiceTests.swift`
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Tools/QuickToolsActions.swift`, `QuickToolPopovers.swift`, `ExpandedView.swift`
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`QuickToolID.ai`, `quickAIConfig`), `App/Sources/Settings/ToolsSettingsView.swift`, `App/Sources/CompositionRoot.swift`
- [x] **Step 1:** `QuickAIConfig` (`ollama`, `openAI`, `anthropic`, `gemini`, model adı, endpoint) ve macOS `Security` Keychain sarmalayıcısını (`KeychainSecretStore`) yaz.
- [x] **Step 2:** `QuickAIService` (`URLSession` ile Ollama `/api/generate` ve OpenAI/Anthropic/Gemini istemcisi, mock `URLProtocol` testli) oluştur.
- [x] **Step 3:** Ada içi `QuickAIPopover` ve `ToolsSettingsView` model/anahtar yapılandırma arayüzünü (TR/EN) bağla.

### Faz 5: Gerçek Canlı Ses Spektrumu (CoreAudio Process Tap) ve Kamera Aynası (Quick Mirror)
- **Files:**
  - Create: `Packages/IslandServices/Sources/IslandServices/Audio/AudioSpectrumService.swift`
  - Create: `Packages/IslandServices/Tests/IslandServicesTests/Audio/AudioSpectrumAnalyzerTests.swift`
  - Create: `Packages/IslandServices/Sources/IslandServices/Camera/CameraMirrorService.swift`
  - Create: `Packages/IslandFeatures/Sources/IslandFeatures/Tools/CameraMirrorView.swift`
  - Create: `Packages/IslandFeatures/Sources/IslandFeatures/NowPlaying/AudioSpectrumBarsView.swift`
  - Modify: `project.yml` (`NSCameraUsageDescription`, `NSAudioCaptureUsageDescription`, `com.apple.security.device.camera`), `App/Info.plist`, `App/Lunula.entitlements`
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`liveAudioSpectrumEnabled`, `QuickToolID.mirror`), `NowPlayingExpandedCard.swift`, `NowPlayingCompact.swift`, `ActivitiesSettingsView.swift`, `App/Sources/CompositionRoot.swift`
- [x] **Step 1:** `Accelerate/vDSP` tabanlı 8-bant FFT hesaplayıcısını (`AudioSpectrumMath`) ve `CATapDescription` + özel aggregate aygıt kullanan `AudioSpectrumService` servisini (yalnız görünürken ve kullanıcı izin verdiğinde çalışan, sessizlikte zarifçe ritmik moda düşen) yaz.
- [x] **Step 2:** `CameraMirrorService` (`AVCaptureSession`, yatay aynalı önizleme, `onDisappear`'da kesin `stopRunning()`) ve `CameraMirrorView` bileşenini yaz.
- [x] **Step 3:** `project.yml` + `./Scripts/bootstrap.sh` ile kamera/ses açıklamalarını üret, `AudioSpectrumBarsView` ve Ayna aracını adaya bağla, `check-entitlements.sh` doğrula.

### Faz 6: Çentikten Hızlı Ekran / GIF Kaydedici (ScreenCaptureKit → Raf) ve Son Bütünleştirme
- **Files:**
  - Create: `Packages/IslandServices/Sources/IslandServices/Capture/ScreenRecorderService.swift`
  - Create: `Packages/IslandServices/Sources/IslandServices/Capture/GIFExporter.swift`
  - Create: `Packages/IslandServices/Tests/IslandServicesTests/Capture/GIFExporterTests.swift`
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`QuickToolID.record`), `QuickToolsActions.swift`, `ExpandedView.swift`, `QuickToolPopovers.swift`
  - Modify: `App/Sources/CompositionRoot.swift`, `CHANGELOG.md`, `README.md`, `docs/features/notchy-ozellik-listesi.md`
- [x] **Step 1:** `ScreenRecorderService` (`SCShareableContent` + `SCStream` + `SCRecordingOutput` MP4 kaydı + `GIFExporter` ile arka planda animasyonlu GIF dönüşümü) ve `GIFExporterTests` yaz.
- [x] **Step 2:** Kayıt sırasında çentikte canlı kırmızı `REC 00:xx` etkinliği ve tek tıkla Durdur → otomatik `ShelfStore.add` akışını `CompositionRoot` içine bağla.
- [x] **Step 3:** Tüm 6 faz için `swift format`, `./Scripts/lint.sh`, `./Scripts/check-architecture.sh`, `./Scripts/test-all.sh` ve Release `./Scripts/check-entitlements.sh` doğrulamasını çalıştır, dokümanları güncelle.
