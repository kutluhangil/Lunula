# Notchy 57 Özellik Araştırması, Tasarım Sistemi ve Uygulama Yol Haritası → Lunula

Kaynak: <https://notchy.dev/#features> (İlk kayıt: 2026-10-29, Tam teknik ve görsel araştırma güncellemesi: 2026-11-05).
Tasarım dili: [`docs/design/Lunula — Ada.pdf`](../design/Lunula%20—%20Ada.pdf) (**"Obsidyen ve Işık"** — `#000000` opak ada çekirdeği, `#111113` yükseltilmiş kart, `#1C1C1F` etkileşimli hap, `#F5F5F7` birincil metin, `1 pt` kenar + `14 pt` hâle, yay sıçraması `≤ 0.12`).

İşaretler:
- `[x]` Lunula'da tamamlandı ve test edildi
- `[~]` Kısmen var / genişletiliyor
- `[ ]` Kurallara ve App Sandbox'a tam uyumlu — sıradaki dalgada eklenecek
- ⚠️ Karar gerektiriyor (ek sistem izni, üçüncü parti bağımlılık veya yoklama istisnası)
- 🚫 Mevcut `AGENTS.md` / `Scripts/check-architecture.sh` kurallarıyla yasak (özel API, `Process()`, `AXUIElement`, `CGEventPost`, `CoreBrightness` veya `sharingType` gerektirir; yalnızca kullanıcı kuralı gevşetirse açılır)

---

## Kategori A — Lunula'da Tamamlanan ve Bu Dalgada Zenginleştirilen Çekirdek Özellikler

### 01. Now Playing `[x]`
- **Teknik Mimari:** `ScriptingBridge` / `NSAppleScript` (`com.apple.Music.playerInfo`, `com.apple.Music.playback`; `LUNULA_SPOTIFY` bayrağı ile Spotify), `DistributedNotificationCenter` (`com.apple.Music.playerInfo` / `com.spotify.client.PlaybackStateChanged`), sıfır yoklama (`IslandTime` tek zamanlayıcı).
- **Tasarım & Animasyon:**
  - **C (Dar — `276 × 32 pt`):** Sol kanatta `20 × 20 pt` (`6 pt` köşe) albüm kapağı, sağ kanatta kapak vurgusunda `16 × 16 pt` `.variableColor.iterative` dalga sembolü, `ambient 0.16` nefes alan hâle.
  - **G (Genişlemiş Ev — `520 × 192 pt`):** Dolgusuz kahraman satırı (`64 × 64 pt` `12 pt` köşeli kapak, 2 satır başlık, `1:02 [çubuk] 4:05` sürüklenebilir ilerleme çubuğu, sağda `32 × 32 pt` geri / oynat-duraklat / ileri, karıştır / tekrar / favori düğmeleri).

### 02. Peek on Hover `[x]`
- **Teknik Mimari:** `PointerSpeedEstimator` (`< 1200 pt/s`) + `100 ms` dwell eşiği (`IslandTiming.dwell`), AppKit `NSTrackingArea` üzerinden sarsıntısız bölge takibi.
- **Tasarım & Animasyon:**
  - **F (Göz Atma — `340 × 62 pt`, Omuz `12`, Köşe `26`):** `.spring(duration: 0.30, bounce: 0.08)` ile açılır. Sol üstte `34 × 34 pt` (`12 pt` köşe) kapak, sağ üst kanatta `16 × 16 pt` dalga sembolü, alt satırda `12 pt` kenar sönümlü kayan başlık (`MarqueeText`) ve doğrudan tıklanabilir mini medya kontrolleri (`backward.fill`, `play.fill`/`pause.fill`, `forward.fill`).

### 03. Pomodoro Timer `[x]`
- **Teknik Mimari:** `TimerController` + `CountdownTimer` + `PomodoroPlan` (`25 / 5 / 15 × 4`), duvar saati (`Date`) tabanlı kalıcılık (`UserDefaults`), uykudan uyanınca kaçırılan bitiş kontrolü, 7 günlük odak serisi (`FocusStreak`) kaydı.
- **Tasarım & Animasyon:**
  - **D (Dar — `292 × 32 pt`):** Sol kanatta `#FF9F0A` aşama sembolü (veya seçili maskot), sağ kanatta `13 pt semibold rounded monospacedDigit` geri sayım, `active 0.32` turuncu hâle ve geçen süreyle saat yönünde ilerleyen `1 pt` kenar ışığı (`HaloMode.progress`).
  - **Genişlemiş Kart:** `28 pt semibold rounded` sayaç, oturum zinciri (`Oturum 2 / 4`), 7 günlük odak çubuk grafiği ve `36 × 36 pt` dairesel `#1C1C1F` kontrol düğmeleri.

### 04. Drift-free Stopwatch `[x]`
- **Teknik Mimari:** `TimerPhase.stopwatch` ile `Date` başlangıç zamanına bağlı (`Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)`), uygulama sürecini her saniye uyandırmadan WindowServer tarafından çizilen sıfır-sapmalı kronometre.
- **Tasarım & Animasyon:** Dar adada (`292 × 32 pt`) `stopwatch` sembolü + canlı artan sayaç; genişlemiş görünümde duraklat / sürdür / sıfırla kontrolleri.

### 05. Timer Mascots `[x]`
- **Teknik Mimari:** `IslandSettings.timerMascot` (`none`, `hare`, `tortoise`, `cat`, `bird`, `flame`) tercihi; Reduce Motion açıkken sabit, kapalıyken `.symbolEffect(.bounce)` / `.pulse` ile geri sayıma eşlik eden sembol.
- **Tasarım & Animasyon:** Zamanlayıcı sol kanadında `#FF9F0A` vurgu renginde `16 × 16 pt` hiyerarşik SF Symbol maskot.

### 06. File Shelf `[x]`
- **Teknik Mimari:** `ShelfStore` içinde security-scoped bookmark (`URL.bookmarkData(options: .withSecurityScope)`) veya isteğe bağlı yerel kopya, otomatik günlük temizlik (`1 / 7 / 30 gün / Asla`), `FileDragMonitor` ile dosya sürüklenirken adanın otomatik açılması.
- **Tasarım & Animasyon:**
  - **H (Dolu Raf — `520 × 208 pt`):** 4 sütunlu ızgara (`117 × 70 pt` hücre, `12 pt` köşe, `32 × 32 pt` ikon, referans dosyalar için `14 × 14 pt` `#1C1C1F` zincir rozeti, üzerine gelince sol üstte `16 × 16 pt` `×` silme düğmesi).
  - **H′ (Boş Raf — `520 × 160 pt`):** `#111113` kart, `24 pt` tepsi ikonu, sürükleme sırasında `#1C1C1F` dolgu ve `1 pt` kesikli beyaz kenarlık.

### 07. AirDrop from the Shelf `[x]`
- **Teknik Mimari:** `NSSharingService(named: .sendViaAirDrop)` ve `NSSharingServicePicker`, çoklu seçim (`⌘`-tık) desteği, işlem sonunda dokunsal (`NSHapticFeedbackManager`) ve görsel geri bildirim.
- **Tasarım & Animasyon:** Raf hücrelerinin bağlam menüsünde ve raf üst çubuğunda tek tıkla AirDrop paylaşımı.

### 08. Image Converter (Shelf) `[x]`
- **Teknik Mimari:** `CGImageSource` + `CGImageDestination` (`ImageIO` ve `UniformTypeIdentifiers`) ile tamamen çevrimdışı, sandbox içi `PNG`, `JPEG`, `HEIC`, `TIFF` ve `PDF` dönüştürme.
- **Tasarım & Animasyon:** Raftaki görüntü dosyalarının bağlam menüsünde **"Biçimi Dönüştür ▸ (PNG / JPEG / HEIC / TIFF / PDF)"** seçeneği; dönüştürülen dosya anında rafa eklenir ve `.levelChange` dokunsal geri bildirimi verir.

### 09. Zip & Unzip (Native Archive) `[x]`
- **Teknik Mimari:** Yasaklı `/usr/bin/ditto` veya `Process()` yerine `NSFileCoordinator` (`readingOptions: .forUploading` ile standart `.zip` üretimi) ve `AppleArchive` (`ArchiveByteStream` / `ArchiveStream`) kullanılarak tamamen süreç-içi (in-process) sıkıştırma ve açma.
- **Tasarım & Animasyon:** Rafta seçili bir veya birden fazla öğe için bağlam menüsünde **"Arşivle (.zip)"**; arşiv dosyaları için **"Arşivi Aç"** eylemi.

### 10. Live Weather `[x]`
- **Teknik Mimari:** `OpenMeteoProvider` + `CoreLocation` (`LocationService`) + 30 dakikalık disk önbelleği (`WeatherCache`), güneş doğuş/batış saatine göre `DaylightPhase` hesaplaması.
- **Tasarım & Animasyon:** Ev sayfasında `56 pt` yüksekliğinde `#111113` karo; solda `20 × 20 pt` hiyerarşik hava sembolü, sağ üstte şehir + `13 pt semibold rounded` sıcaklık, sağ altta durum + `Y / D` (`11 pt medium textSecondary`).

### 11. Menu Bar Calendar & Meeting Island `[x]`
- **Teknik Mimari:** `EventKit` (`EKEventStore`), `.EKEventStoreChanged` bildirimi + toplantıdan 10 dk önce başlayan ve 1 dk kala kritik önceliğe geçen `CalendarService` zamanlayıcısı; Zoom, Google Meet, Teams, FaceTime, Webex bağlantı algılayıcısı (`MeetingLinkDetector`).
- **Tasarım & Animasyon:**
  - **I (Genişlemiş Toplantı — `520 × 160 pt`):** Üstte toplantı başlığı ve `14:30–15:00 · Zoom` alt satırı; altta `492 × 36 pt` `#F5F5F7` dolgulu, `#000000` metinli `"Katıl"` düğmesi; toplantı yaklaşırken nötrden `#FF9F0A` turuncuya ısınan (`HaloMode.warming`) hâle.

### 12. Download Alerts `[x]`
- **Teknik Mimari:** `DispatchSource.makeFileSystemObjectSource` ile `~/Downloads` klasörü izleme (yalnızca kullanıcı Ayarlar'dan etkinleştirdiğinde başlar), `.crdownload` / `.part` geçici uzantı filtreleme ve ardışık boyut doğrulaması (`DownloadTracker`).
- **Tasarım & Animasyon:**
  - **J3 (`380 × 70 pt`, Göz Atma ölçeği, Omuz `12`, Köşe `26`):** Sol altta `42 × 42 pt` `#111113` dosya kutusu, sağ üst kanatta `"İndirildi"`, alt satırda dosya adı + `"Finder'da göster"` ve `"Rafa ekle"` hap düğmeleri (`24 pt` yükseklik, `#1C1C1F`).

### 13. Privacy Indicator `[x]`
- **Teknik Mimari:** `CoreMediaIO` (`kCMIODevicePropertyDeviceIsRunningSomewhere`) ve `CoreAudio` (`kAudioDevicePropertyDeviceIsRunningSomewhere`) özellik dinleyicileri (`DeviceUsageMonitor`) — sıfır yoklama, sıfır izin istemi.
- **Tasarım & Animasyon:**
  - **K1–K2:** Adanın (veya son ayrık baloncuğun) sağ dış kenarından `8 pt` açıkta, `32 pt` şeritte dikey ortalanmış (`y = 13`) `6 pt` yeşil (`#32D74B` kamera) ve `6 pt` turuncu (`#FF9F0A` mikrofon) noktalar (`4 pt` aralık); ada genişledikçe aynı yay fiziğiyle sağa kayar.

### 14. Battery HUD & Full Charge Island `[x]`
- **Teknik Mimari:** `IOPSCopyPowerSourcesInfo` + `IOPSNotificationCreateRunLoopSource` (`PowerMonitor`) ve `BatteryAlertRules`; kullanıcının Ayarlar'dan seçebildiği **%80–%100 Tam Şarj Eşiği** (`fullChargeThreshold`).
- **Tasarım & Animasyon:**
  - **J1 (Şarj Oluyor — `276 × 32 pt`):** Sol kanatta `#32D74B` şimşekli pil sembolü, sağ kanatta `#32D74B` `%54`, `HaloMode.fill` ile pil yüzdesi kadar dolan yeşil kenar ışığı.
  - **J2 (Düşük Pil — `276 × 32 pt`):** `#FF9F0A` turuncu tek nabız (`0 → 0.55 → 0`, `0.9 sn`) ve `%20` / `%10` uyarısı.

### 15. Pill on Any Mac & Resizable Panel `[x]`
- **Teknik Mimari:** `NotchGeometry` (`auxiliaryTopLeftArea == nil` olduğunda `180 × 22 pt` hap modu), `IslandSettings` içinde özelleştirilebilir genişlemiş ada genişliği (`520...600 pt`) ve hap dikey ofseti (`0...8 pt`).
- **Tasarım & Animasyon:**
  - **L1 (Boşta):** Görünmez (`opacity = 0`), menü çubuğu tamamen temiz.
  - **L2 (Etkin — `180 × 22 pt`, Köşe `11 pt`):** Üst kenardan `1 pt` (artı kullanıcı ofseti) aşağıda, `12 pt` sembol + `11 pt` başlık + `11 pt rounded` süre.

### 16. Multiple Live Activities (Bud & Detached Bubbles) `[x]`
- **Teknik Mimari:** `ActivityScheduler` + `ActivityPriorityRules` (kritik > yüksek > normal > ortam); birincil etkinlik adada, ikincil etkinlikler sağda `32 × 32 pt` dairesel baloncuklarda.
- **Tasarım & Animasyon:**
  - **E (`276 × 32 + 8 + 32 × 32 pt`):** Yeni baloncuk ayrılırken `0.55 sn` boyunca `MetaballBridge` (`Canvas` `blur(6) + alphaThreshold(0.5)`) ile sıvımsı kopma animasyonu; durağan durumda sıfır GPU maliyeti.

### 17. Keep Awake (Caffeine) `[x]`
- **Teknik Mimari:** `IOPMAssertionCreateWithName` (`kIOPMAssertPreventUserIdleDisplaySleep` ve `kIOPMAssertPreventUserIdleSystemSleep`), `KeepAwakeController` ile **Süresiz**, **30 dk**, **1 saat**, **2 saat** modları; süre bitiminde `IslandTime` üzerinden otomatik kapanma.
- **Tasarım & Animasyon:** Genişlemiş ada üst çubuğunda ve bağlam menüsünde tek tıkla çalışan kahve fincanı (`cup.and.saucer.fill`) anahtarı; etkin olduğunda `#FF9F0A` kehribar vurgu ve durum rozeti.

### 18. Audio Switcher & Mic Mute `[x]`
- **Teknik Mimari:** `CoreAudio` (`kAudioHardwarePropertyDevices`, `kAudioHardwarePropertyDefaultOutputDevice`, `kAudioHardwarePropertyDefaultInputDevice`, `kAudioDevicePropertyMute`) üzerinden sistem genelinde giriş mikrofonunu tek tıkla susturma ve ses çıkış aygıtını (`Hoparlör`, `AirPods`, `Monitör`) değiştirme.
- **Tasarım & Animasyon:** Genişlemiş ada üst/alt araç şeridinde mikrofon susturma (`mic.fill` / `mic.slash.fill` `#FF453A` kırmızı vurgu) ve ses çıkış seçici açılır menüsü.

### 19. Quick Notes `[x]`
- **Teknik Mimari:** `QuickNotesStore` (`Application Support/Notes.json` içinde kalıcı), hızlı not ekleme, sabitleme ve kopyalama/silme.
- **Tasarım & Animasyon:** Genişlemiş adada `Ev` ve `Raf` hap sekmelerinin yanında **`Notlar`** (`Notes`) sekmesi; `#111113` kart içinde anında yazılabilir metin alanı ve kayıtlı hızlı not fişleri (`#1C1C1F`).

### 20. Color Eyedropper `[x]`
- **Teknik Mimari:** AppKit `NSColorSampler` (Ekran Kaydı izni gerektirmez), seçilen pikseli sRGB `#RRGGBB` hex koduna çevirip `NSPasteboard.general`'a kopyalar ve `TransientAlert` olarak seçilen rengin kendi hâlesiyle (`SignalTint.accent`) gösterir.
- **Tasarım & Animasyon:** Üst çubuktan veya bağlam menüsünden tetiklenen damlalık (`eyedropper`); renk seçildiğinde seçilen renkte parlayan `316 × 32 pt` ada uyarısı (`#32D74B Kopyalandı`).

### 21. 100% Native `[x]`
- **Teknik Mimari:** Saf Swift 6 (`strict concurrency`), SwiftUI + AppKit + Core Animation (`HaloLayer`), boşta `< %0.1` CPU ve `< 1` wakeup/sn bütçesi.

### 22. Gestures & Hover Open `[x]`
- **Teknik Mimari:** `SwipeDetector` (aşağı kaydır = aç, yukarı kaydır = kapat), `PageCycler` (sol/sağ ok veya yatay kaydırma ile sekmeler arası geçiş), Ayarlar'da hareket tercihleri.

### 23. Developer API & Agent Activity `[x]`
- **Teknik Mimari:** `lunula://show`, `lunula://update`, `lunula://end`, `lunula://timer`, `lunula://toggle` URL şeması (`IslandURLParser`, `RateLimiter` 10 istek / 10 sn) ve yerel `AppIntents` (`ShowActivityIntent`, `UpdateActivityIntent`, `EndActivityIntent`, `StartTimerIntent`, `ToggleIslandIntent`). Claude Code / Codex kancaları bu şemayla sıfır arka plan sunucusu maliyetiyle doğrudan canlı etkinlik oluşturur.

---

## Kategori B — Bu Dalgada Tamamlanan Ek Sandbox-Uyumlu Özellikler (`[x]`)

| # | Özellik | Durum | Teknik Mimari & macOS API | Lunula Tasarım & Animasyon Kurgusu |
|---|---|---|---|---|
| 24 | **Synced Lyrics** | `[x]` | `LRCLIB` (`https://lrclib.net/api/get`) üzerinden API anahtarsız LRC zaman damgalı şarkı sözü çekme, `NowPlayingSnapshot.position(at:)` ile eşleme. | Şimdi Çalıyor kahraman kartının altında `13 pt medium` aktif satır (`#F5F5F7`) ve `11 pt textSecondary` sonraki satır. |
| 25 | **Apple Shortcuts Runner** | `[x]` | `shortcuts://run-shortcut?name=` URL şeması ve `AppLauncherStore` entegrasyonu. | Başlatıcı & Hub içinde `#1C1C1F` tek-tık kestirme fişleri. |
| 26 | **Command Palette** | `[x]` | `SearchAndPalettePopover` ile ada içi arama ve tüm Lunula eylemlerine tek listeden erişim. | `#111113` arama alanı, altında klavye/tık ile çalışan `#1C1C1F` komut satırları. |
| 27 | **Search & Translate** | `[x]` | Güvenli recursive-descent matematik ifadeleri çözücüsü (`QuickExpressionEvaluator`), 8 arama/çeviri motoru yönlendiricisi. | Arama & Komut paleti içinde anında hesaplama sonucu (`= 42`) ve çeviri yönlendirmesi. |
| 28 | **OCR & Search** | `[x]` | `Vision` (`VNRecognizeTextRequest`, `.accurate`, cihaz üstü) ile rafa bırakılan görselden metin çıkarma (`ShelfConverter.extractText`). | Raftaki görselin bağlam menüsünde **"Metni kopyala (OCR)"**; çıkarılan metin panoya kopyalanır ve geçici onay adası gösterir. |
| 29 | **Camera Mirror** | ⚠️ | `AVFoundation` (`AVCaptureSession`) `com.apple.security.device.camera` TCC izni tetikler; `docs/qa/spikes/camera-microphone-indicator.md` kararı gereği varsayılan olarak kapalıdır. | İzin politikası değişirse açılabilir. |
| 30 | **Zoom Teleprompter (Cuely)** | `[x]` | Kamera merceğinin tam altında (`TeleprompterStore` + `TeleprompterPopover`) `TimelineView(.animation)` ile akan metin, ayarlanabilir hız (`10...80 pt/sn`). | Üst-orta hizalı akan metin, oynat/duraklat ve başa sarma kontrolleri. |
| 31 | **Apple Reminders / Checklist** | `[x]` | `QuickRemindersStore` ile ada içi hızlı yapılacaklar/anımsatıcılar listesi, tamamlama ve silme. | Başlatıcı & Hub görünümünde dairesel onay kutulu anımsatıcı satırları. |
| 32 | **Drive Eject** | `[x]` | `NSWorkspace.didMountNotification` / `didUnmountNotification` ve `NSWorkspace.shared.unmountAndEjectDevice(at:)` (`ExternalDriveMonitor`). | USB/disk takıldığında `TransientAlert` + tek tıkla `eject.fill` çıkarma düğmesi ve `"Güvenle çıkarılabilir"` onayı. |
| 33 | **App Launcher** | `[x]` | `AppLauncherStore` + `NSWorkspace.shared.openApplication(at:configuration:)` ile sabitlenen uygulamaları tek tıkla başlatma. | Başlatıcı sekmesinde `#1C1C1F` uygulama düğmeleri. |
| 34 | **System Stats** | `[x]` | `mach_host_self()` (`HOST_CPU_LOAD_INFO` ve `HOST_VM_INFO64` ile CPU yükü ve bellek kullanımı, yalnızca ada açıkken örneklenir). | `SystemStatsPopover` içinde `CPU % · RAM GB (%)` göstergesi. |
| 35 | **Device Battery** | `[x]` | `IOKit` (`AppleDeviceManagementHIDEventService`) ile Magic Mouse, Klavye, Trackpad ve Bluetooth kulaklık pil yüzdeleri. | `SystemStatsPopover` içinde bağlı kablosuz aygıtların pil yüzdesi listesi. |
| 36 | **Stocks Ticker** | `[x]` | `StocksService` + `StocksWatchlistStore` ile sembol fiyatı, günlük değişim ve piyasa seans durumu (`REGULAR`, `PRE`, `POST`, `CLOSED`). | Başlatıcı & Hub Borsa sekmesinde sembol, seans rozeti, fiyat ve `#32D74B` / `#FF453A` yüzde değişimi. |
| 37 | **Menu Bar Detach** | `[x]` | `StatusItemController.togglePopover` + `DetachedMenuBarHubView` ile ada araçlarını bağımsız `NSPopover` penceresine ayırma. | Genişlemiş ada üst çubuğunda `pip.exit` düğmesi; başlığında tek tıkla Uyanık Tut anahtarı bulunan `#000000` menü çubuğu penceresi. |
| 38 | **Hide the Notch** | `[x]` | `IslandSettings.hideNotchBar` etkinleştirildiğinde çentik yüksekliğinde tam genişlikte `#000000` şerit çizerek donanım çentiğini gizleme. | Ayarlar › Görünüm'de anahtar; Lunula hâlesi üzerinde parlamaya devam eder. |
| 39 | **Clipboard Screenshot Staging** | `[x]` | `ShelfConverter.stageClipboardImage` ile panodaki ekran görüntüsünü (`⌘⌃⇧4`) tek tıkla `.png` olarak Rafa ekleme. | Raf bağlam menüsünde **"Panodaki görseli rafa ekle"**. |
| 40 | **Liquid Glass UI (Kart Seçeneği)** | `[x]` | `AGENTS.md` kuralı gereği ada çekirdeği her zaman opak `#000000` kalır; `IslandSettings.useGlassCards` ile iç kartlarda ince üst ışık kırılması (`islandCardGlass`). | Ayarlar › Görünüm'de anahtar; Reduce Transparency ve Increase Contrast açıkken otomatik devre dışı kalır. |
| 41 | **Agent Approvals & AI Usage Hooks** | `[x]` | `lunula://ai/usage`, `lunula://agent/approval` ve `lunula://agent/resolve` URL şeması (`IslandURLParser` + `URLRouter` + `AIUsageStore`) ve `DistributedNotificationCenter` (`com.kutluhangul.lunula.agentDecision`) yanıt yayını. | Ajan onay istediğinde kritik öncelikli ada uyarısı ve `SystemStatsPopover` içinde `#32D74B` **İzin ver** / `#FF453A` **Reddet** hap düğmeleri. |
| 42 | **Clipboard History & Snippets** | `[x]` | Sıfır arka plan yoklamasıyla (yalnızca uygulama/ada açılışında `PasteboardMonitor.checkNow()`) URL, e-posta, `#RRGGBB` renk ve metin algılayan `ClipboardHistoryStore` + iğneleme + `TextSnippet` şablonları. | `ClipboardAndSnippetsPopover` içinde arama, tek tıkla kopyalama, URL açma, sabitleme ve şablonlar sekmesi. |
| 43 | **Caps Lock HUD** | `[x]` | Input Monitoring izni istemeden `NSEvent.flagsChanged` üzerinden çalışan `CapsLockMonitor`. | Caps Lock geçişlerinde `capslock.fill` / `capslock` geçici ada bildirimi. |

---

## Kategori C — Kullanıcı Kararı Gerektiren Özellikler (`⚠️`)

Bu özellikler teknik olarak yapılabilir ancak `AGENTS.md` içindeki **"No polling"**, **"App Sandbox"** veya **"No third-party dependency without approval"** kuralları için açık onayını gerektirir:

1. ⚠️ **Clipboard History / Smart Actions / Text Snippets (#42–#44):** macOS'ta `NSPasteboard` için sistem bildirimi yoktur; `changeCount` değerini 0.5–1.0 saniyede bir kontrol etmek gerekir. Ayrıca otomatik yapıştırma (`⌘V` simülasyonu) `CGEventPost` ve Erişilebilirlik izni ister.
2. ⚠️ **AI Usage Tracker (#45):** Claude Code (`~/.claude`), Codex ve Cursor yerel logları App Sandbox dışındadır; kullanıcının `NSOpenPanel` ile klasör seçmesi (security-scoped bookmark) veya Keychain'e API anahtarı girmesi gerekir.
3. ⚠️ **Screenshot Shelf & Screen Capture (#46–#47):** Masaüstü klasörünü izlemek için kullanıcı klasör izni veya `ScreenCaptureKit` için Ekran Kaydı izni gerekir.
4. ⚠️ **Live Audio Spectrum (#48) & Sound Mixer (#49):** macOS 14.4+ `CATapDescription` (CoreAudio Process Tap) ses yakalama izni ister.
5. ⚠️ **Caps Lock HUD (#50):** `NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged)` ile izin istemeden okunabilir; istenirse hemen Kategori A'ya alınabilir.
6. ⚠️ **Automatic Updates (Sparkle) (#51) & Custom Idle Animation (Lottie) (#52):** Üçüncü parti paket (`Sparkle`, `lottie-ios`) eklenmesi `AGENTS.md` gereği senin onayına bağlıdır.

---

## Kategori D — Mevcut Mimari Kurallarla Yasaklı Özellikler (`🚫`)

`Scripts/check-architecture.sh` ve `AGENTS.md` ("Forbidden: private APIs, SkyLight/SLS, CGS, DisplayServices, CoreBrightness, dlopen/dlsym, Accessibility APIs, CGEventPost, Process/NSTask, sharingType, disabling App Sandbox") tarafından engellenen özellikler:

- 🚫 **#53 Face Unlock:** Kilit ekranı üzerinde görüntü yakalama ve parola alanına otomatik giriş özel API / `CGEventPost` gerektirir.
- 🚫 **#54 Knock to Control:** Apple Silicon ivmeölçer (`AppleSPUHIDDevice`) veya ham trackpad dokunuşu (`MultitouchSupport.framework`) özel API'dir. (Yalnızca *"çift tuşa basma"* modu genel `flagsChanged` ile yapılabilir.)
- 🚫 **#55 System HUDs / Alt HUD Styles / Keyboard Backlight / External Display DDC:** Sistem HUD'unu bastırmak, `CoreBrightness` ve `IOAVService` kullanmak özel API'dir.
- 🚫 **#56 Window Snapping / Message Island / Keystroke HUD / Keyboard Cleaning Lock:** Başka uygulamaların pencerelerini taşımak ve Mesajlar'ı okumak `AXUIElement` (Erişilebilirlik) ve `CGEvent.tapCreate` gerektirir.
- 🚫 **#57 Hidden from Screen Capture / Lock Screen Widgets / Notch Terminal / Call Island / Focus Mode:** `NSWindow.sharingType`, `SLSWindow` kilit ekranı katmanı, `Process()` / `forkpty` kabuğu ve özel çağrı bildirimleri mevcut kurallarla yasaktır.
