# Kutluhan için yapılacaklar (güncellendi: 2026-11-27)

Kod, Ada tasarım sistemi, 5 sekmeli Ayarlar + İlk Açılış, TR/EN yerelleştirme, uygulama ikonu, CI düzeltmesi, tüm otomatik testler ve Faz 1–7 (oynatıcı ses kaydırıcısı, Bluetooth ses bağlantı uyarıları, tam gün takvim ajandası, Apple Reminders `EventKit` senkronu, Claude Code / Codex kancaları, Homebrew Cask / DMG otomasyonu, Tarayıcı/YouTube Now Playing köprüsü) tamam. Aşağıdakiler yalnızca **çentikli MacBook donanımı, Apple Developer hesabı veya ürün kararı** gerektirdiği için sonraya not alındı:

## 0. Sonraya ertelenen kararlar (2026-11-27 notu)

1. **Sparkle 2 otomatik güncelleme entegrasyonu:** Üçüncü parti bağımlılık onayı (`AGENTS.md`) + EdDSA anahtar çifti + appcast barındırma kararı verildiğinde MAS dışı doğrudan dağıtım hedefine eklenecek.
2. **Canlı Release QA ve `v0.1.0-rc1` çıkışı:** Aşağıdaki 1–5. bölümlerdeki canlı MacBook görsel/donanım kontrolleri, Apple Developer imzalama sırları ve ilk etiket (`v0.1.0-rc1`) çıkışı daha sonra birlikte yapılacak.

## 1. Hazırlık ve canlı kontrol (5 dk)

1. `Config/Signing.xcconfig` dosyasına ücretli Apple Developer `DEVELOPMENT_TEAM` kimliğini yaz (şu an `.example` ile aynı, ad-hoc imzada izinler her derlemede yeniden sorulur).
2. Başka bir çentik uygulaması (Sapphire, Notchy vb.) açıksa kapat; adanın üstünü örtebilir.
3. Release derle ve çalıştır:
   `xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Release -derivedDataPath build build && open build/Build/Products/Release/Lunula.app`
4. Görsel doğrulama: yeni `AppIcon` simgesi, 680 × 540 Ayarlar penceresi (TR + EN, hilal amblem, Araçlar sürükle-sırala, Hava elle şehir seçici), 420 × 320 İlk Açılış ve genişlemiş ada sol kanat taşma (`ellipsis.circle`) kontrolü.

## 2. Donanım spike'ları (karar senin; sonuçları tablolara yaz)

| Spike | Belge | Neyi karara bağlıyor |
|---|---|---|
| Tam ekran | `docs/qa/spikes/fullscreen.md` | Menü çubuğu sezgiseli doğru mu (Safari, Keynote, Xcode, maksimize pencere) |
| Music betik erişimi | `docs/qa/spikes/music-scripting.md` | Erişim grubu adları, akış/radyo çıktısı |
| Kamera/mikrofon | `docs/qa/spikes/camera-microphone-indicator.md` | İzin penceresi çıkmadan çalışıyor mu (çıkarsa o aygıt v1'den çıkar) |

## 3. Cihaz matrisi QA (`T9.6`)

`docs/qa/checklist.md` (63/64 madde cihaz onayı bekliyor):

- Kapalı ada çentikle birebir mi; hâle üst kenarı aydınlatıyor ve yalnız dışarı mı parlıyor
- Non-activating key panel klavyeyi (Esc, ←/→) gerçekten alıyor mu
- İndirme uyarıları Ayarlar'dan açılınca çalışıyor mu (açılışta izin istemi çıkmadan)
- VoiceOver turu → `docs/qa/accessibility.md`
- Double-Length Pseudolanguage + RTL ekran görüntüleri → `docs/qa/shots/pseudo-*.png`
- Hava TR/EN ekran görüntüleri → `docs/qa/shots/weather-{tr,en}.png`
- Gerçek `ScreenDescriptor` değerleri (14"/16" MBP, Air, harici, kapak kapalı) ve rakip uygulama bundle ID'leri (`mdls -name kMDItemCFBundleIdentifier`)

## 4. Çentikli MacBook performans ölçümü (`T9.5`)

- Mac mini boşta bütçesi temiz (`0.00% CPU / 0 uyanma / 46 MB`, `docs/qa/perf-log.md`).
- Çentikli 120 Hz MacBook'ta: `Scripts/perf/measure-idle.sh --seconds 120 --assert-idle`, müzik çalarken ölçüm (`< %1`), Instruments Animation Hitches + Time Profiler (`syncWindows`, `phase`, `url`) ve 8 saatlik bellek gözlemi.

## 5. İmzalı sürüm ve marka (`T9.7`)

`docs/release.md` adımları:
1. Developer ID Application sertifikası + `.p12` + App Store Connect API anahtarı (`.p8`).
2. 6 GitHub Secret (`DEVELOPER_ID_CERT_P12`, `DEVELOPER_ID_CERT_PASSWORD`, `APPSTORE_CONNECT_KEY_ID`, `APPSTORE_CONNECT_ISSUER_ID`, `APPSTORE_CONNECT_KEY_P8`, `DEVELOPMENT_TEAM`).
3. TÜRKPATENT / USPTO / EUIPO (sınıf 9 ve 42) "Lunula" marka taraması → `docs/release.md`.
4. Yerel `notarytool` denemesi, ardından `git tag v0.1.0-rc1 && git push origin v0.1.0-rc1`.

## 6. Açık ürün kararları

- `docs/features/notchy-ozellik-listesi.md` Kategori C: canlı ses spektrumu (CoreAudio Process Tap izni), Masaüstü ekran görüntüsü klasör izleyicisi, Sparkle / Lottie üçüncü parti paketleri.
- Mac App Store yayın zamanlaması ve `LUNULA_SPOTIFY` MAS kararı (`docs/superpowers/plans/v1/backlog.md`).
