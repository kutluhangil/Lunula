# Performans günlüğü

Bütçe (spec §8): boşta < %0.1 CPU ve < 1 uyanma/sn · müzik çalarken < %1 CPU · bellek < 120 MB.
Ölçüm: `Scripts/perf/measure-idle.sh --seconds 60 --assert-idle` (Release derlemesi, açıldıktan 10 sn sonra).

| Tarih | Derleme | Cihaz | macOS | Sonuç | Not |
|---|---|---|---|---|---|
| 2026-10-29 | Release, Faz 3 (motor) | Mac mini (Mac18,5), çentiksiz 1280×720 → hap modu | 27.0.1 | `cpu_median=0.0 idlew_median=0 mem=40M` · exit 0 | Ada kapalı, etkinlik yok; Sapphire.app aynı anda açıktı |
| 2026-10-29 | Release, Faz 3 son inceleme düzeltmeleri | Mac mini (Mac18,5), hap modu | 27.0.1 | `cpu_median=0.00 idlew_median=0 mem=42M` · exit 0 | 2 panel (ada + sıcak bölge) |
| 2026-10-29 | Release, Faz 4 (zamanlayıcı çalışırken) | Mac mini (Mac18,5), hap modu | 27.0.1 | `cpu_median=0.30 idlew_median=0 mem=44M` (30 sn) | Bütçe: müzik/zamanlayıcıda < %1 · geri sayım `Text(timerInterval:)` |
| 2026-10-29 | Release, Faz 5 (Şimdi Çalıyor kayıtlı, Music kapalı) | Mac mini (Mac18,5), hap modu | 27.0.1 | `cpu_median=0.00 idlew_median=0 mem=42M` · exit 0 | Music başlatılmadı (betik gönderilmedi) |
| 2026-10-29 | Release, Faz 6 (takvim + hava kayıtlı) | Mac mini (Mac18,5), hap modu | 27.0.1 | `cpu_median=0.00 idlew_median=0 mem=43M` · exit 0 | Takvim/konum izni verilmedi (istem yok) |
| 2026-10-29 | Release, Faz 7 (raf, pil, indirme, kamera/mik. açık) | Mac mini (Mac18,5), hap modu | 27.0.1 | `cpu_median=0.00 idlew_median=0 mem=43M` (İndirmeler kapalı) | Pil yok (masaüstü); global sürükleme izleyicisi kurulu |

Instruments: `com.kutluhangul.lunula` › Points of Interest — `syncWindows` aralığı, `phase` ve `url` olayları (T9.5). Bütçe ölçümleri (müzik çalarken, peek/expanded geçişleri, 120 Hz) çentikli MacBook'ta yapılacak.
