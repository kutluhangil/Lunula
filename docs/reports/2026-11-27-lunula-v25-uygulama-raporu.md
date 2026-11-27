# Lunula v2.5 — Kapsamlı Tasarım, Akışkan Animasyon, Yüzey Bütünlüğü ve Güçlendirme Raporu

**Tarih:** 27 Kasım 2026  
**Depo:** `/Volumes/ProjectClaude/Lunula`  
**Plan:** `docs/superpowers/plans/2026-11-27-v25-craft-motion-settings-plan.md`  
**Canlı Mockup Stüdyoları:**
- `docs/design/lunula-v25-craft-studio.html` *(v2.5 Akışkan Hareket, Liquid Glass, 7'li İzin Merkezi & Streaming AI Stüdyosu)*
- `docs/design/lunula-benchmark-mockup.html` *(v2 Rakip Analizi & Tasarım Karşılaştırma Stüdyosu)*

---

## 1. Yönetici Özeti

v2 dalgasında eklenen `Alcove / Boring` stilleri, `Liquid Glass`, su damlası imleç fiziği ve 7 rakip aracın ardından yapılan derin denetimde tespit edilen **tüm geçiş, yüzey, Ayarlar, izin, kayıt, Mini AI ve mimari eksikler** 5 fazlı bir mühendislik planıyla tamamlandı.

Uygulama boyunca sıfır özel API, App Sandbox + Hardened Runtime, sıfır arka plan yoklaması (`< %0.1` boşta CPU bütçesi), en küçük `11 pt` tipografi, `Reduce Motion` / `Reduce Transparency` / `Increase Contrast` erişilebilirlik düşüşleri ve TR + EN String Catalog kuralları eksiksiz korundu.

---

## 2. Faz Faz Yapılan Geliştirmeler

### Paket 1 — Akışkan Animasyon ve Fizik Cilası (`IslandCore`, `IslandDesign`, `IslandFeatures`)

1. **`Compact ↔ Peek ↔ Expanded` Uçarak Büyüyen Kahraman Öğeler (`matchedGeometryEffect`):**
   - `Packages/IslandDesign/Sources/IslandDesign/Tokens/IslandMorphNamespace.swift` ile paylaşılan `EnvironmentValues.islandMorphNamespace` eklendi.
   - `IslandSurface.swift` içinde oluşturulan `@Namespace` üzerinden `ArtworkImage` (`20×20 pt` sol çentik kanadı → `34×34 pt` Göz Atma → `64×64 pt` Genişlemiş kart) ve `TimerCompactView` ↔ `TimerExpandedCard` maskot/sayaç ikonları artık kesilip yeniden çizilmek yerine fiziksel olarak uçarak boyut değiştiriyor (`Reduce Motion` açıkken otomatik devre dışı).
2. **`Ev / Raf / Araçlar` Kayan Sekme Kapsülü ve Yönlü `.blurReplace` Sayfa Geçişi:**
   - `ExpandedView.swift` üst çubuğundaki aktif sekme arka plan kapsülüne `matchedGeometryEffect(id: "expandedTabCapsule")` eklendi; sekme değiştirildiğinde kapsül pürüzsüzce kayıyor ve sayfa gövdesi macOS yerel `.blurReplace` geçişiyle akıyor.
3. **Çift Yönlü (Doğma + Adaya Geri Emilme) ve Cam Uyumlu `MetaballBridge`:**
   - `MetaballBridge.swift` artık `surfaceMaterial: IslandSurfaceMaterial` parametresi alıyor; `Liquid Glass` modunda katı siyah leke yerine yarı saydam füme cam + ince beyaz kenar kırılması çiziyor.
   - `IslandSurface.swift` yalnız baloncuk eklenirken (`0 → 1`) değil, ayrık etkinlik bittiğinde veya birleştiğinde baloncuğun adaya geri emilmesini (`1 → 0` reverse metaball) de canlandırıyor.
4. **3 Kademeli Su Damlası Hassasiyeti (`DropletSensitivity`) ve Alt Kenar Kopma Uzaması (`1.22×`):**
   - `DropletPhysics.swift` içine `.subtle` (`0.65×`), `.balanced` (`1.0×`) ve `.expressive` (`1.45×`, `±8 pt / +6.5 pt` menisküs tavanı) eklendi.
   - İmleç adanın alt kenarından aşağı doğru hızla çıkarken (`velocity.height > 30`) yüzey gerilimi kopmadan önce `1.22×` esneyip yaylanarak geri topluyor; üst kenar çentikli ekranlarda her zaman `y = 0`'da kilitli kalıyor.
   - `FluidIslandShape.swift` içindeki `DropletSpecularOverlay`'e ikinci bir iç kostik ışık kırılma halkası eklendi.
5. **Canlı Zamanlayıcı Maskot Mikro-Etkileşimleri:**
   - `TimerCompactView.swift` ve `TimerExpandedCard.swift` içinde seçilen maskota göre faz duyarlı sembol efektleri (`flame` için `.variableColor.iterative`, `hare` için faz geçişinde `.bounce` + `.pulse`, `cat/bird/tortoise` için `.breathe`) bağlandı.

---

### Paket 2 — Yüzey & Stil Bütünlüğü (`IslandDesign`, `IslandFeatures`, `App/Window`)

1. **Tüm İkincil Yüzeylerde `Liquid Glass` Uyumu:**
   - `IslandSurfaceMaterialModifier.swift` içine `IslandBubbleBackground` ve `.islandPopoverChrome(_:cornerRadius:)` eklendi.
   - Sağdaki ayrık etkinlik baloncukları (`BubbleView.swift`), yüzen dosya bırakma sepeti (`FloatingShelfBasketController.swift`), Kamera Aynası (`CameraMirrorPopoverView.swift`), Mini AI, Sistem İstatistikleri, Pano, Teleprompter, Komut Paleti, Başlatıcı ve Menü Çubuğu Hub popover'ları (`QuickToolPopovers.swift`, `ExpandedView.swift`) artık `Liquid Glass` seçildiğinde otomatik cam kabuğa geçiyor (`Reduce Transparency` / `Increase Contrast` açıkken `Palette.obsidian`'a düşer).
2. **Yüzen Bırakma Sepetinde Canlı Raf Öğe Sayısı Rozeti:**
   - `FloatingShelfBasketController.swift` artık Rafta bekleyen dosya sayısını sağ üstte `11 pt` kehribar rozet olarak gösteriyor.
3. **Boring Stilinde Görünür `Shuffle / Repeat` ve Sağ `Bugün` Mini Takvim Kutusu:**
   - `NowPlayingExpandedCard.swift` içinde `Boring` seçildiğinde oynatma kontrollerinin iki yanında doğrudan `shuffle` ve `repeat` düğmeleri yer alıyor; kartın sağ kenarında ise bugünün yaklaşan 2 etkinliğini gösteren (toplantı linki varsa tek tıkla katılan) kompakt `Bugün` ajanda kutusu açılıyor.
4. **Stile Duyarlı `PeekView` (Göz Atma):**
   - `PeekView.swift` artık `Alcove` modunda üst kanat tekrarını kaldırıp dingin tek şerit Dynamic Island düzenine geçiyor; `Boring` modunda ise radyal kapak ambiyansı ve 6-bant mini ses spektrumu gösteriyor.

---

### Paket 3 — Canlı v2.5 Ayarlar Sahnesi, 7'li İzin Merkezi, İlk Açılış Seçici ve Sıfırlama (`App/Settings`, `App/Onboarding`)

1. **Fareyle Etkileşimli v2.5 `SettingsStagePreview` (`656 × 88 pt`):**
   - `SettingsStagePreview.swift` artık `visualStyle`, `surfaceMaterial`, `expandedWidth`, `waterDropletEffect` ve `dropletSensitivity` ayarlarını canlı yansıtıyor; kullanıcı Ayarlar penceresindeki önizleme sahnesinin üzerinde fareyi gezdirdiğinde su damlası esnemesini ve `Liquid Glass` kırılmasını anında test edebiliyor.
   - `SettingsWindowView.swift` kaydırma çubuğu (`showsIndicators: true`) ve alt kenar yumuşak solma maskesiyle alt kısımdaki kartların görünürlüğünü netleştiriyor.
2. **7'li Birleşik İzin Merkezi (`PermissionRow` + `ExtraPermissionKind`):**
   - Mevcut `Apple Music`, `Takvim` ve `Konum` izinlerinin yanına **Apple Anımsatıcılar** (`EventKit`), **Kamera Aynası** (`AVCaptureDevice`), **Canlı Ses Spektrumu** (`CoreAudio`), **Ekran & GIF Kaydı** (`CGPreflightScreenCaptureAccess` — izin penceresi açmadan salt-okunur kontrol) ve `#if LUNULA_SPOTIFY` derlemesinde **Spotify Otomasyonu** durum satırları eklendi.
3. **İlk Açılış (`OnboardingView`) Stil & Yüzey Seçicisi (`420 × 320 pt`):**
   - İlk kurulum penceresi `420 × 320 pt` boyutunu ve sıfır izin istemi garantisini koruyarak kullanıcının daha ilk saniyede `Lunula / Alcove / Boring` stilini ve `Obsidyen / Liquid Glass` yüzeyini seçmesine olanak tanıyor.
4. **İki Adımlı Güvenli "Varsayılanlara Dön":**
   - `GeneralSettingsView.swift` altına yanlış tıklamayı önleyen iki adımlı (`Varsayılanlara Dön` → `Onayla / Vazgeç`) sıfırlama kartı eklendi.

---

### Paket 4 — Seçili Alan MP4/GIF Kaydedici, Akışlı Mini AI ve Modüler `CompositionRoot` (`IslandServices`, `App`)

1. **`ScreenRegionSelector` ile Bölge Seçerek MP4 / GIF Kaydetme ve Canlı `00:xx` Sayaç:**
   - `App/Sources/Window/ScreenRegionSelector.swift` tam ekran artı imleçli (`NSCursor.crosshair`) bölge seçici paneli eklendi; AppKit sol-alt koordinatlarını `SCStreamConfiguration.sourceRect` sol-üst koordinat uzayına çeviriyor ve `Escape` / sağ tık ile iptali destekliyor.
   - Kayıt menüsü 4 seçeneğe çıkarıldı: **Tam Ekran MP4**, **Seçili Alan MP4**, **Tam Ekran GIF**, **Seçili Alan GIF**.
   - Kayıt sürerken hem araç çubuğunda hem genişlemiş ızgarada sistem saatiyle (`Text(timerInterval:)`, sıfır CPU uyanması) canlı geçen süre sayacı gösteriliyor.
2. **Kelime Kelime Akışlı (Streaming) Mini AI, Ollama Model Keşfi ve Pano Kısayol Çipleri:**
   - `QuickAIService.swift` `URLSession.bytes(for:)` ile Ollama NDJSON ve bulut sağlayıcı SSE akışlarını satır satır okuyup yanıtı kelime kelime büyütüyor; tek parça JSON yanıtlarla da geriye dönük uyumlu çalışıyor.
   - `fetchOllamaModels(endpoint:)` (`GET /api/tags`) ile yerel Ollama modelleri Ayarlar'dan tek tıkla listelenip seçilebiliyor; `testConnection(config:)` ile hem yerel hem BYOK bağlantı doğrulaması yapılıyor.
   - `QuickAIPopover` içine panoda metin varken tek tıkla çalışan **Panoyu Özetle**, **Çevir** ve **Açıkla** kısayol çipleri eklendi.
3. **`CompositionRoot` Modüler Dosya Bölünmesi:**
   - Tek somut bağlayıcı mimari kuralı korunarak `1.163` satırlık `CompositionRoot` dört odaklı dosyaya ayrıldı:
     - `App/Sources/CompositionRoot.swift` *(çekirdek yaşam döngüsü, pencere/hot-zone ve su damlası senkronu)*
     - `App/Sources/CompositionRoot+QuickTools.swift` *(hızlı araçlar, ses spektrumu, alan/ekran kaydı, renk/uygulama seçici)*
     - `App/Sources/CompositionRoot+Shelf.swift` *(raf eylemleri, görsel dönüştürme, ZIP, Vision OCR, AirDrop)*
     - `App/Sources/CompositionRoot+Settings.swift` *(ayar gözlemcisi, 7'li izin merkezi, Ollama/AI bağlantı köprüleri, sıfırlama ve bağlam menüsü)*

---

## 3. Doğrulama Özeti

- `swift format lint --strict`: **0 uyarı / 0 hata**
- `./Scripts/check-architecture.sh`: **`architecture OK`**
- `./Scripts/test-all.sh`: **96 test dosyası / 437 birim ve render testi %100 yeşil** (`IslandCoreTests`: 203/203, `IslandDesignTests`: 53/53, `IslandServicesTests`: 91/91, `IslandFeaturesTests`: 50/50, `LunulaTests`: 40/40)
- Release `./Scripts/check-entitlements.sh`: **`entitlements OK (sandbox, hardened runtime)`**
