# Elle QA kontrol listesi

Cihaz matrisi (spec §10): 14"/16" MacBook Pro, MacBook Air, çentiksiz ekran, harici ekran, kapak kapalı, uyku/uyanma, tam ekran, ekran paylaşımı, Hareketi Azalt / Şeffaflığı Azalt.
Başka bir çentik uygulaması (ör. Sapphire, Boring Notch) açıkken test etme; adayı örtebilir.

## Motor

- [ ] Kapalı ada notch'la birebir (yakın çekim fotoğraf; kenarda siyah çerçeve yok)
- [ ] Hover → peek
- [ ] Hızlı geçişte peek yok
- [ ] 250 ms çıkış toleransı (kısa çıkışta kapanmaz)
- [ ] Tık → expanded
- [ ] Esc / dışarı tık / yukarı kaydırma kapatır
- [ ] İki parmak aşağı kaydırma açar
- [ ] Sağ tık menüsü (Ayarlar…, 1 saat sustur, Lunula'dan çık)
- [ ] ⌃⌥Space adayı açar/kapatır (imlecin olduğu ekranda)
- [ ] Expanded'da ← → sekme değiştirir, Esc kapatır
- [ ] Ekran modları: yalnız çentikli / tümü / ana ekran
- [ ] Kapak kapalı + yalnız harici ekran (hap modu)
- [ ] Uyku/uyanma ×3 — ada yerinde ve doğru boyutta
- [ ] Harici ekran tak/çıkar ×3
- [ ] Tam ekran: Safari, Keynote, Xcode — ada gizlenir (ayar açıksa); `docs/qa/spikes/fullscreen.md` spike'ı önce yapılmalı
- [ ] Maksimize pencere yanlış pozitifi yok
- [ ] Spaces geçişi, Mission Control, Sahne Yöneticisi
- [ ] Hareketi Azalt (metaball yok, 0.2 sn opaklık) / Şeffaflığı Azalt (parıltı yok) / Kontrastı Artır (anahtar çizgi 1.5 pt)
- [ ] Hâle: üst kenar aydınlanıyor (y-çevirme), parıltı yalnızca dışarıda, anahtar çizgi içeride
- [ ] Ada açıkken panelin şeffaf bölgesine tıklama alttaki menü öğesine ulaşıyor mu (ulaşmıyorsa panel çerçevesini her faz değişiminde ada + hâle payına küçült ve `docs/qa/spikes/panel-hit-testing.md`'ye yaz)
- [ ] macOS 27'de menü çubuğu değişikliği sonrası konum
- [ ] Ayarlar: bağlam menüsünden açılır, öne gelir, ⌘W kapatır; girişte başlat Giriş Öğeleri'nde görünür; kısayol kaydedici hemen uygular

## Şimdi Çalıyor

- [ ] `docs/qa/spikes/music-scripting.md` spike'ı (erişim grupları, sorgu çıktısı, akış/radyo)
- [ ] Music çalarken compact'ta kapak + dalga; expanded'da başlık, sanatçı, konum çubuğu, önceki/oynat/sonraki
- [ ] Konum çubuğunu sürükleyince parça o konuma atlar; 10 sn sınırlarında hafif dokunsal
- [ ] Parça değişince 2 sn uyarı (bir kez)
- [ ] Duraklatınca 10 dk sonra kaybolur
- [ ] Music/Spotify kapalıyken hiçbir betik gönderilmez (Konsol: `com.kutluhangul.lunula`); uygulama kendiliğinden açılmaz
- [ ] İzin akışı: `tccutil reset AppleEvents com.kutluhangul.lunula` → Music çal → adada tek uyarı → Ev'de izin kartı → İzin ver → sistem penceresi → kabul → kapak/başlık görünür; reddet → uyarı bu oturumda tekrar gelmez
- [ ] Spotify (yalnızca `LUNULA_SPOTIFY` ile derlenince): süre doğru (ms), reklam gösterilmez
- [ ] Müzik çalarken `measure-idle.sh` medyanı < %1

## Zamanlayıcı

- [ ] ⌃⌥Space → Ev → "25 dk" → compact geri sayım + turuncu ilerleme ışığı
- [ ] Bitişte 6 sn uyarı ve tek ses (ada açıkken bitse bile bir kez)
- [ ] Uygulamayı kapatıp açınca zamanlayıcı sürer; kapalıyken biterse 10 dk içinde bir kez uyarır
- [ ] Mac'i 2 dk uyutup uyandırınca kalan süre doğru
- [ ] Pomodoro: odak → kısa mola kendiliğinden başlar; Atla bir sonraki aşamaya geçer
- [ ] İki ekranda uyarı sesi bir kez çalar

## Takvim

- [ ] Açılışta takvim izni istenmez; Ev'de "Takvimi bağla" karosuna tıklayınca istenir
- [ ] Toplantıdan 10 dk önce compact'ta takvim rengi nokta + geri sayım; 1 dk kala "Şimdi", sonra "Başladı"
- [ ] Bağlantılı toplantıda "Katıl" tarayıcıda/uygulamada açılır; bağlantısızda düğme yok
- [ ] Reddedilmiş, iptal edilmiş ve tüm gün etkinlikleri "sıradaki" olmaz
- [ ] Takvimde etkinlik ekleyince/silince ada güncellenir

## Hava

- [ ] Ev ilk açılınca konum izni istenir (yalnızca o an); hava karosu görünür
- [ ] 30 dk içinde Ev'i tekrar açmak ikinci ağ isteği yapmaz (Konsol / ağ günlüğü)
- [ ] Ağ kapalıyken son değer kalır
- [ ] Türkçe + Türkiye: °C, "Gök gürültülü fırtına" kesilmez (`docs/qa/shots/weather-tr.png`)
- [ ] İngilizce + ABD: °F (`docs/qa/shots/weather-en.png`)
- [ ] Ev'de başka ışık yokken gün ışığı tonu (şafak pembe, gün beyaz, gün batımı turuncu, gece mavi)
- [ ] Hakkında'da "Open-Meteo.com (CC BY 4.0)" atfı

## Raf

## Sinyaller

## Otomasyon

## Erişilebilirlik

## Performans

- [x] Boşta < %0.1 CPU, < 1 uyanma/sn (2026-10-29, Mac mini — `docs/qa/perf-log.md`)
- [ ] Aynı ölçüm çentikli MacBook'ta
