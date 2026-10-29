# Notchy özellik listesi → Lunula

Kaynak: <https://notchy.dev/#features> (2026-10-29). Notchy tasarım ve özellik **ilhamı**; kodu, görselleri ve metni kopyalanmaz.

İşaretler:
- `[x]` Lunula'da var
- `[~]` kısmen var (not satırında ne eksik)
- `[ ]` yok, yapılabilir
- 🚫 proje kurallarıyla yasak (CLAUDE.md "Forbidden" / sandbox), kural değişmeden yapılamaz
- ⚠️ yapılabilir ama karar gerekiyor (izin, bağımlılık, polling)

Bir özellik eklendikçe kutusu işaretlenir ve commit'i nota yazılır.

## Lunula'da olanlar / kısmen olanlar

- [~] **Now Playing**: Music + Spotify, kapak, oynat/duraklat/ileri/geri. Eksik: kaydırma (scrub), karıştır/tekrar, uygulama sesi, tarayıcı video hızı.
- [~] **Pomodoro Timer**: Pomodoro + 5/15/25 dk + özel süre, duvar saatine bağlı. Eksik: oturum zinciri, kronometre, seri, 7 günlük grafik.
- [x] **File Shelf**: sürükle-bırak, yeniden açılışta kalıcı (security-scoped bookmark).
- [x] **Live Weather**: Open-Meteo, Ana sayfa kartı.
- [x] **Download Alerts**: İndirmeler klasörü (Ayarlar'dan açılınca), Finder'da göster.
- [x] **Privacy Indicator**: CoreMediaIO + CoreAudio kamera/mikrofon noktası (spike cihazda doğrulanacak).
- [~] **Battery HUD**: düşük pil ve şarj uyarısı. Eksik: canlı şarj göstergesi.
- [~] **Full Charge Island**: şarj uyarı kuralları var. Eksik: kullanıcı seçimli %80–100 eşiği.
- [x] **Pill on Any Mac**: çentiksiz ekranda hap. Eksik: boyut/yükseklik ayarı.
- [~] **Multiple Live Activities**: birincil etkinlik + yandaki baloncuklar, önceliğe göre sıralı.
- [~] **Peek on Hover**: üzerine gelince önizleme. Eksik: önizlemede müzik kontrolleri.
- [~] **Gestures & Hover Open**: aşağı kaydır = aç, yukarı = kapat. Eksik: sekmeler arası kaydırma, her hareket için ayar.
- [x] **100% Native**: SwiftUI + AppKit, boşta %0.00 CPU (Mac mini ölçümü).
- [~] **Menu Bar Calendar**: sıradaki etkinlik + toplantıya katıl. Eksik: açılır takvim görünümü.
- [~] **Developer API**: `lunula://` URL şeması + Kestirmeler (App Intents). Notchy'deki gibi yerel HTTP sunucusu yok.
- [~] **Agent Activity**: ajan kancaları URL ile etkinlik gösterebiliyor (`docs/automation.md`). Eksik: hazır Claude Code/Codex kanca kurulumu, tur maliyeti.
- [~] **Apple Shortcuts**: Lunula eylemleri Kestirmeler'de. Eksik: adadan kestirme çalıştırma.

## Yapılabilir (kurallara uygun)

- [ ] **Quick Notes**: adadan hızlı not.
- [ ] **Keep Awake**: IOPMAssertion; süreli / süresiz / saate kadar.
- [ ] **Drift-free Stopwatch**
- [ ] **Timer Mascots**
- [ ] **Audio Switcher**: CoreAudio çıkış aygıtı seçimi.
- [ ] **Mic Mute**: CoreAudio giriş aygıtını sustur.
- [ ] **Apple Reminders**: EventKit (ek izin).
- [ ] **Camera Mirror**: AVFoundation (kamera izni yalnızca kullanıcı açınca).
- [ ] **Command Palette**: KeyboardShortcuts ile genel kısayol.
- [ ] **Search & Translate**: Translation framework, hesap makinesi.
- [ ] **App Launcher**
- [ ] **Drive Eject**: NSWorkspace bağlama/çıkarma bildirimleri.
- [ ] **AirDrop from the Shelf**: NSSharingService.
- [ ] **Image Converter**: ImageIO, çevrimdışı.
- [ ] **OCR & Search**: Vision, cihaz üstünde.
- [ ] **Color Eyedropper**: NSColorSampler (ekran kaydı izni gerekmez).
- [ ] **Stocks Ticker**: ağ verisi.
- [ ] **Synced Lyrics**: LRCLIB (ağ).
- [ ] **System Stats**: CPU/bellek/ağ.
- [ ] **Desktop Widgets**: WidgetKit uzantısı.
- [ ] **Liquid Glass UI**: macOS 26 `glassEffect`. Not: tasarım kuralı "ada çekirdeği her zaman opak #000000"; cam yalnızca kartlarda ve çevrede olabilir.
- [ ] **Resizable panel**: genişlik/yükseklik ayarı.
- [ ] **Hide the Notch**: menü çubuğunu siyah gösteren duvar kağıdı katmanı.
- [ ] **Menu Bar Detach**: sekmeyi menü çubuğu popover'ına ayırma.
- [ ] **Zoom Teleprompter**
- [ ] **Device Battery**: IOKit/IOBluetooth genel API'leri; kapsam cihazda doğrulanmalı.
- [ ] **Agent Approvals**: Allow/Deny adası; cevabın kancaya geri dönmesi için çift yönlü kanal gerekir.

## Karar gerektirenler ⚠️

- ⚠️ **Clipboard History / Smart Actions / Text Snippets**: pano için değişiklik bildirimi yok, `changeCount` yoklaması gerekir ("No polling" kuralı). Snippet yapıştırma `CGEventPost` gerektirir (yasak).
- ⚠️ **AI Usage Tracker**: başka uygulamaların logları sandbox dışında; kullanıcının klasör seçmesi ya da API anahtarı (Keychain) gerekir.
- ⚠️ **Screenshot Shelf**: Masaüstü/ekran görüntüsü klasörüne erişim izni.
- ⚠️ **Screen Capture**: ScreenCaptureKit ekran kaydı izni ister; `screencapture` çalıştırmak yasak (Process).
- ⚠️ **Live Audio Spectrum**: Core Audio process tap, ses yakalama izni ister.
- ⚠️ **Automatic Updates**: Sparkle yeni bağımlılık (onay gerekir).
- ⚠️ **Custom Idle Animation**: Lottie yeni bağımlılık (onay gerekir).
- ⚠️ **Caps Lock HUD**: genel `flagsChanged` izleme izin gerektirebilir; doğrulanmalı.
- ⚠️ **Sound Mixer**: uygulama başına ses için process tap (macOS 14.4+); izin ve App Review riski.
- ⚠️ **Menu Bar Icon Hiding**: ayırıcı öğe hilesi; kırılgan.

## Kurallarla yasak 🚫

- 🚫 **Face Unlock**: kilit ekranı ve parola girişi özel API ya da Erişilebilirlik ister.
- 🚫 **Knock to Control**: ivmeölçer/trackpad ham verisi özel API (SMC, MultitouchSupport).
- 🚫 **System HUDs / Alt HUD Styles**: sistem HUD'unu gizlemek ve ses/parlaklık tuşlarını yakalamak özel API ve olay dinleyici ister.
- 🚫 **Keyboard Backlight**: CoreBrightness (yasak listesinde).
- 🚫 **External Display Control**: IOAVService DDC, özel API.
- 🚫 **Hidden from Screen Capture**: `NSWindow.sharingType` yasak listesinde.
- 🚫 **Window Snapping**: başka pencereleri taşımak Erişilebilirlik API'si.
- 🚫 **Message Island**: Erişilebilirlik ile Mesajlar'ı okumak.
- 🚫 **Notification Mirror**: Tam Disk Erişimi.
- 🚫 **Keystroke HUD / Keyboard Cleaning Lock**: genel tuş dinleme/engelleme (event tap).
- 🚫 **Lock Screen Widgets**: kilit ekranına çizim özel API.
- 🚫 **Notch Terminal**: PTY içinde kabuk = `Process` (yasak).
- 🚫 **Zip & Unzip (ditto ile)**: `/usr/bin/ditto` çalıştırmak yasak. (Apple Archive ile yapılırsa ⚠️'e taşınabilir.)
- 🚫 **Call Island**: gelen FaceTime/telefon araması için genel API yok.
- 🚫 **Focus Mode**: CLAUDE.md "Focus status is out of v1".
- 🚫 **AirPods Manager (kasa algılama)**: yakındaki kasa yayınları özel API.
- 🚫 **Shell Activity**: kullanıcının `.zshrc`'sine yazmak sandbox dışı. (Kullanıcının kendisinin kopyaladığı bir kanca satırı ile ⚠️ olur; URL şeması zaten var.)
