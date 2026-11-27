# Lunula v2.5 — Akışkan Animasyon Cilası, Cam Yüzey Bütünlüğü, Canlı Ayarlar Sahnesi ve Kayıt/AI Güçlendirme Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan phase-by-phase. Steps use checkbox (`- [ ]`) syntax for tracking. Do **not** run `git commit` or `git push` without explicit user instruction (`~/Neural-Vault/Core/Kurallar.md`).

**Goal:** Lunula v2'nin üzerine Apple/Alcove kalitesinde geçiş sürekliliği (`Compact ↔ Peek ↔ Expanded` hero morphing, kayan sekme kapsülü, çift yönlü cam uyumlu metaball köprüsü, hassasiyet ayarlı su damlası kopma fiziği), tüm ikincil yüzeylerde (`BubbleView`, `PeekView`, `FloatingShelfBasket`, Popover'lar) `Liquid Glass` + `Alcove/Boring` bütünlüğü, Boring sağ mini takvim kutusu, v2.5 ayarlarına canlı tepki veren interaktif `SettingsStagePreview` + 7'li İzin Merkezi + İlk Açılış stil seçici + "Varsayılanlara Dön", alan seçmeli ve canlı sayaçlı `ScreenCaptureKit` MP4/GIF kaydedici, akışlı (streaming) + pano çipli + Ollama model keşifli `QuickAIService`, modüler `CompositionRoot`, detaylı `.md` uygulama raporu ve interaktif HTML Craft & Motion Mockup Stüdyosu eklemek.

**Architecture:** Mevcut 4 yerel Swift paketi (`IslandCore` → `IslandDesign` → `IslandServices` / `IslandFeatures`) ve `App/` katman sınırları (`Scripts/check-architecture.sh`) birebir korunur. `1.163` satırlık `CompositionRoot` aynı `@MainActor final class` içinde `CompositionRoot+QuickTools.swift`, `CompositionRoot+Shelf.swift` ve `CompositionRoot+Settings.swift` uzantılarına bölünerek okunabilirlik artırılır. Paralel alt ajanlar tamamen ayrık dosya kümelerinde çalışır; paylaşılan bağlayıcı dosyalar ana oturum (Integrator) tarafından birleştirilir.

**Tech Stack:** Swift 6 (`strict concurrency`), SwiftUI + AppKit (macOS 26 Tahoe `.glassEffect`, `.blurReplace`, `matchedGeometryEffect`), `ScreenCaptureKit`, `AVFoundation`, `CoreAudio`, `EventKit`, `URLSession` (`bytes(for:)` SSE/NDJSON akışı), `Security` Keychain.

**Spec:** `docs/superpowers/specs/2026-10-28-v1-design.md` ve `docs/design/lunula-benchmark-mockup.html`

## Global Constraints

- **App Sandbox + Hardened Runtime** her derlemede açık kalır (`Scripts/check-entitlements.sh`).
- **Özel API yasağı (`Scripts/check-architecture.sh`):** `IslandCore` yalnız `Foundation`/`Observation` (`#if canImport(CoreGraphics)` istisnasıyla), `IslandFeatures` asla `IslandServices` import etmez, `IslandServices` asla `SwiftUI` import etmez, `DispatchQueue.main.sync` ve özel semboller yasak.
- **Sıfır sürpriz izin istemi:** Kamera, Sistem Sesi, Ekran Kaydı, Takvim, Anımsatıcılar ve Konum açılışta asla izin istemez; `CGPreflightScreenCaptureAccess()` gibi salt-okunur durum sorguları izin penceresi tetiklemez.
- **Tasarım değişmezleri:** En küçük yazı `11 pt`, yay sıçraması `≤ 0.12`, geçiş süresi `≤ 2.0 sn`, boşta `.idle` fazında `.obsidian` iken yalnızca `#000000` veya şeffaf piksel, `Reduce Motion` / `Reduce Transparency` / `Increase Contrast` tam uyumlu, tüm kullanıcı metinleri TR + EN String Catalog içinde ve `!` içermez.
- **Git kuralı:** Kullanıcı açıkça söylemeden `git commit` veya `git push` çalıştırılmaz; hiçbir yerde model/AI adı geçmez.

## Review Focus

1. **`IslandRootViewTests.idleRendersOnlyBlackOrClearPixels()` korunumu:** `.idle` fazında `surfaceMaterial` ne olursa olsun ada çekirdeği `#000000` kalmalı ve sıfır gerilimde `FluidIslandShape` birebir `IslandShape`'e delege etmeli.
2. **`Reduce Motion` & `Reduce Transparency` düşüşleri:** `matchedGeometryEffect` hero geçişi, `blurReplace` sayfa geçişi, çift yönlü `MetaballBridge` ve su damlası esnemesi `Reduce Motion` açıkken devre dışı kalmalı; `Liquid Glass` baloncuk/popover/sepet yüzeyleri `Reduce Transparency` veya `Increase Contrast` açıkken opak `Palette.obsidian`'a düşmeli.
3. **Ekran Alanı Seçici koordinat uzayı:** `NSEvent` / `NSScreen` sol-alt orijinlidir, `SCStreamConfiguration.sourceRect` ise ekran-içi sol-üst orijinlidir; dönüşüm `y = screenFrame.maxY - selectionRect.maxY` olarak hesaplanmalı ve `Escape` ile iptalde kayıt başlamamalı.
4. **Akışlı (Streaming) Mini AI geriye dönük uyumluluk:** `QuickAIService` hem satır satır NDJSON/SSE akışını hem tek parça JSON yanıtlarını (mevcut mock `URLProtocol` testleri dahil) hatasız ayrıştırmalı.
5. **String Catalog bütünlüğü (`LocalizationTests`):** Eklenen her yeni anahtar hem `tr` hem `en` çevirisine sahip olmalı ve hiçbir çeviride `!` karakteri bulunmamalı.

---

## Faz Planı

### Faz 1: Akışkan Animasyon Cilası (Hero Morphing, Kayan Sekme, Çift Yönlü Metaball, Su Damlası Hassasiyeti)
- **Files:**
  - Modify: `Packages/IslandCore/Sources/IslandCore/Interaction/DropletPhysics.swift` (`DropletSensitivity`, alt kenar kopma uzaması)
  - Modify: `Packages/IslandCore/Tests/IslandCoreTests/Interaction/DropletPhysicsTests.swift`
  - Modify: `Packages/IslandCore/Sources/IslandCore/Settings/IslandSettings.swift` (`dropletSensitivity`)
  - Modify: `Packages/IslandCore/Tests/IslandCoreTests/Settings/IslandSettingsTests.swift`
  - Create: `Packages/IslandDesign/Sources/IslandDesign/Tokens/IslandMorphNamespace.swift`
  - Modify: `Packages/IslandDesign/Sources/IslandDesign/Shape/FluidIslandShape.swift` (`±8 / +6.5 pt` tavan + çift halkalı kostik parıltı)
  - Modify: `Packages/IslandDesign/Tests/IslandDesignTests/Shape/FluidIslandShapeTests.swift`
  - Modify: `Packages/IslandDesign/Sources/IslandDesign/Bud/MetaballBridge.swift` (`surfaceMaterial` cam uyumu)
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Root/IslandSurface.swift` (`@Namespace` hero morph + ayrılan baloncuğun adaya geri emilme `retreat` animasyonu)
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/NowPlaying/ArtworkImage.swift`, `TimerCompactView.swift`, `TimerExpandedCard.swift`, `ExpandedView.swift`
- [x] **Step 1:** `DropletSensitivity` (`.subtle`, `.balanced`, `.expressive`), kopma (snap-stretch) fiziği, `FluidIslandShape` kostik parıltısı, cam uyumlu `MetaballBridge` ve `IslandMorphNamespace` altyapısını testleriyle kur.
- [x] **Step 2:** `IslandSurface`, `ArtworkImage`, `TimerCompactView`/`TimerExpandedCard` arasında `matchedGeometryEffect` hero geçişini, çift yönlü baloncuk tomurcuklanma/emilme köprüsünü ve `ExpandedView` içinde kayan sekme kapsülü + yönlü `.blurReplace` sayfa geçişini uygula.

### Faz 2: Yüzey & Stil Bütünlüğü (Liquid Glass İkincil Yüzeyler, Boring Mini Takvim & Kontroller, Stile Duyarlı Peek)
- **Files:**
  - Modify: `Packages/IslandDesign/Sources/IslandDesign/Surface/IslandSurfaceMaterialModifier.swift` (`IslandBubbleShell`, `.islandPopoverChrome(_:)`)
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Root/BubbleView.swift`, `PeekView.swift`
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/NowPlaying/NowPlayingExpandedCard.swift`
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Tools/QuickToolPopovers.swift`, `CameraMirrorPopoverView.swift`
  - Modify: `App/Sources/Window/FloatingShelfBasketController.swift`
- [x] **Step 1:** `IslandBubbleShell` ve `.islandPopoverChrome(_:)` ile `BubbleView`, tüm araç popover'ları, `DetachedMenuBarHubView` ve `FloatingShelfBasketController` (raf öğe sayısı rozeti dahil) yüzeylerini `Liquid Glass` seçimine duyarlı hale getir.
- [x] **Step 2:** `NowPlayingExpandedCard` içinde Boring moduna görünür `shuffle/repeat` düğmelerini ve sağ `Bugün` mini takvim kutusunu ekle; `PeekView` görünümünü `Lunula / Alcove / Boring` stillerine göre farklılaştır.

### Faz 3: Canlı v2.5 Ayarlar Sahnesi, 7'li İzin Merkezi, İlk Açılış Stil Seçici ve Varsayılanlara Dön
- **Files:**
  - Modify: `App/Sources/Settings/SettingsStagePreview.swift`, `SettingsWindowView.swift`, `SettingsWindowController.swift`
  - Modify: `App/Sources/Settings/AppearanceSettingsView.swift`, `ActivitiesSettingsView.swift`, `ToolsSettingsView.swift`, `GeneralSettingsView.swift`
  - Modify: `App/Sources/Onboarding/OnboardingView.swift`, `OnboardingWindowController.swift`
  - Modify: `App/Resources/Localizable.xcstrings`
- [x] **Step 1:** `SettingsStagePreview` sahnesini `visualStyle`, `surfaceMaterial`, `expandedWidth`, `waterDropletEffect` ve `dropletSensitivity` ayarlarına + sahne içi canlı fare gezintisine tepki verir hale getir; kaydırma çubuğu ve alt solma maskesini ekle.
- [x] **Step 2:** Kamera, Sistem Sesi, Ekran Kaydı (`CGPreflightScreenCaptureAccess`), Apple Reminders ve `#if LUNULA_SPOTIFY` izin satırlarını Ayarlar'a ekle; `OnboardingView`'a ilk gün stil/yüzey seçicisini ve `GeneralSettingsView`'a iki adımlı "Varsayılanlara Dön" kontrolünü ekle.

### Faz 4: Seçili Alan MP4/GIF Kaydedici + Canlı Sayaç, Akışlı Mini AI + Ollama Model Keşfi ve `CompositionRoot` Bölünmesi
- **Files:**
  - Create: `App/Sources/Window/ScreenRegionSelector.swift`
  - Modify: `Packages/IslandServices/Sources/IslandServices/Capture/ScreenRecorderService.swift`
  - Modify: `Packages/IslandServices/Sources/IslandServices/AI/QuickAIService.swift`, `Packages/IslandServices/Tests/IslandServicesTests/AI/QuickAIServiceTests.swift`
  - Modify: `Packages/IslandFeatures/Sources/IslandFeatures/Tools/QuickToolsActions.swift`, `QuickToolPopovers.swift`, `ExpandedView.swift`
  - Create: `App/Sources/CompositionRoot+QuickTools.swift`, `App/Sources/CompositionRoot+Shelf.swift`, `App/Sources/CompositionRoot+Settings.swift`
  - Modify: `App/Sources/CompositionRoot.swift`
- [x] **Step 1:** `ScreenRegionSelector` ile ekranda dikdörtgen alan seçerek MP4/GIF kaydetme (`Tam Ekran / Seçili Alan × MP4 / GIF`) ve kayıt boyunca canlı `00:xx` sayaç gösterimini ekle.
- [x] **Step 2:** `QuickAIService` içine kelime kelime akış (SSE/NDJSON streaming), Ollama `/api/tags` model listeleme, bağlantı testi ve `QuickAIPopover` içine tek tık pano kısayol çiplerini (`Panoyu Özetle`, `Çevir`, `Açıkla`) ekle.
- [x] **Step 3:** `CompositionRoot.swift` dosyasını 4 odaklı dosyaya bölüp tüm yeni servisleri ve `./Scripts/bootstrap.sh` proje üretimini bağla.

### Faz 5: Görsel Regresyon Testleri, Detaylı Uygulama Raporu (`.md`) ve İnteraktif v2.5 Craft Mockup Stüdyosu (`.html`)
- **Files:**
  - Create: `Packages/IslandFeatures/Tests/IslandFeaturesTests/Root/IslandV25CraftTests.swift`
  - Create: `docs/reports/2026-11-27-lunula-v25-uygulama-raporu.md`
  - Create: `docs/design/lunula-v25-craft-studio.html`
- [x] **Step 1:** Yeni v2.5 görsel stillerini, cam ikincil yüzeyleri, çift yönlü metaball'u ve su damlası hassasiyetini doğrulayan birim/render testlerini çalıştır (`lint`, `check-architecture`, `test-all`, Release `check-entitlements`).
- [x] **Step 2:** Yapılan tüm çalışmaları madde madde belgeleyen [2026-11-27-lunula-v25-uygulama-raporu.md](file:///Volumes/ProjectClaude/Lunula/docs/reports/2026-11-27-lunula-v25-uygulama-raporu.md) raporunu ve canlı su damlası fiziği + hero morphing + cam yüzeyler + v2.5 Ayarlar simülatörünü içeren [lunula-v25-craft-studio.html](file:///Volumes/ProjectClaude/Lunula/docs/design/lunula-v25-craft-studio.html) mockup stüdyosunu oluştur.
