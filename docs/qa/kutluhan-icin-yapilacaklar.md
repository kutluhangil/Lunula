# Kutluhan için yapılacaklar (v1 kod tamam, 2026-10-29)

Tüm fazların kodu yazıldı, testler ve CI yeşil. Aşağıdakiler **cihaz, senin onayın ya da Apple hesabın** gerektirdiği için bekliyor. Sıra önemli: önce 1, sonra 2…

## 1. Hazırlık (5 dk)

1. Çentikli MacBook'ta repo: `git pull && Scripts/bootstrap.sh`
2. `Config/Signing.xcconfig.example` → `Config/Signing.xcconfig`, `DEVELOPMENT_TEAM` = Team ID (izinler her derlemede sorulmasın diye).
3. **Sapphire'i kapat** (başka bir çentik uygulaması; Mac mini'de Lunula'nın hapını ekranda örttüğü görüldü). Lunula açılışta onu bir kez uyarı olarak söyler.
4. Release derle ve aç: `xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Release -derivedDataPath build build && open build/Build/Products/Release/Lunula.app`

## 2. Spike'lar (karar senin; sonuçları tabloya yaz)

| Spike | Belge | Neyi karara bağlıyor |
|---|---|---|
| Tam ekran | `docs/qa/spikes/fullscreen.md` | Menü çubuğu sezgiseli doğru mu (Safari, Keynote, Xcode, maksimize pencere) |
| Music betik erişimi | `docs/qa/spikes/music-scripting.md` | Erişim grubu adları, akış/radyo çıktısı |
| Kamera/mikrofon | `docs/qa/spikes/camera-microphone-indicator.md` | İzin penceresi çıkmadan çalışıyor mu (çıkarsa o aygıt v1'den çıkar) |

## 3. Kontrol listesi

`docs/qa/checklist.md` — Motor, Şimdi Çalıyor, Zamanlayıcı, Takvim, Hava, Raf, Sinyaller, Otomasyon, Erişilebilirlik, Performans bölümleri. Her başarısızlık için bir GitHub issue.

Öne çıkanlar:

- Kapalı ada notch'la birebir mi (yakın çekim fotoğraf)
- Hâle: üst kenar aydınlanıyor mu, parıltı yalnızca dışarıda mı (ekran dışı testte doğrulanamadı)
- Uyarı sesi tek mi (iki ekranda da)
- İndirme uyarıları **kapalı başlar**; Ayarlar › Etkinlikler › İndirme uyarıları açılınca çalışır (İndirmeler klasörü izni yalnızca o an)
- VoiceOver turu → `docs/qa/accessibility.md`
- Sözde dil (Double-Length) ve Sağdan-Sola şemalarıyla ekran görüntüleri → `docs/qa/shots/pseudo-*.png`
- Hava TR/EN ekran görüntüleri → `docs/qa/shots/weather-{tr,en}.png`

## 4. Performans (T9.5)

`Scripts/perf/measure-idle.sh --seconds 60 --assert-idle` (boşta) ve müzik çalarken aynı komut (`--assert-idle` olmadan; bütçe < %1). Instruments › Points of Interest: `syncWindows`, `phase`, `url`. Sonuçlar `docs/qa/perf-log.md`'ye.

## 5. Cihaz matrisi (T9.6)

Her cihazda `ScreenDescriptor` değerlerini kaydet; gerçek değerler test fikstürlerine eklenecek (14"/16" MBP, Air, çentiksiz + harici, kapak kapalı). Rakip uygulama paket kimlikleri `mdls -name kMDItemCFBundleIdentifier /Applications/<Uygulama>.app` ile doğrulanacak (yalnızca Sapphire doğrulandı).

## 6. Sürüm (T9.7)

`docs/release.md` adım adım: Developer ID sertifikası, .p12, App Store Connect API anahtarı, 6 GitHub Secret, yerel `notarytool` denemesi, sonra `git tag v0.1.0-rc1 && git push origin v0.1.0-rc1`.

## 7. Bilinen açık noktalar

- Ajan başlatmaları bu oturumda otomatik onay denetçisi tarafından çoğunlukla reddedildi; Faz 3'ün ortasından itibaren işler satır içi yapıldı ve görev incelemeleri kendi kendine yapıldı (ledger'larda "self-review"). Bir sonraki oturumda `claude --permission-mode default` ile bağımsız bir son inceleme önerilir.
- Kararların tamamı `.superpowers/sdd/phase-*/progress.md` içindeki `Ruling:` satırlarında.
