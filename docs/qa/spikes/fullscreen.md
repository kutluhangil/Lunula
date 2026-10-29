# Spike: tam ekran tespiti (T3.7)

**Durum: pending spike — not locked.** `FullscreenHeuristic` (Packages/IslandCore) fikstürlere göre yazıldı; bu tablo cihazda doldurulmadan kural kilitlenmez. Bulgular kuralı değiştiriyorsa önce kullanıcıya göster, sonra `FullscreenHeuristic.swift` ve T3.7 Interfaces notunu güncelle.

## Amaç

Ekran Kaydı izni olmadan "ön plandaki uygulama bu ekranda tam ekran mı" sorusunu yanıtlayan sezgisel: (a) ön plandaki uygulamanın katman-0 penceresi, ekranın üst `safeAreaTop` bandı hariç tüm alanı kaplıyor ve (b) o ekranın üst menü çubuğu bandıyla kesişen, ekranda görünen katman-24 penceresi yok. Soru: katman-24 penceresi tam ekranda gerçekten kayboluyor mu, pencere sınırları beklenen değerde mi, otomatik gizlenen menü çubuğunda ne oluyor?

## Çalıştırma

Her senaryo için hedef duruma geç, sonra kendi terminalinden (komut 5 sn bekler, tam ekran uygulamaya geçmeye zaman verir):

```bash
sleep 5; swift Scripts/spikes/window-list.swift
```

Çıktı satırı: `pid=… layer=… bounds=(x, y, w, h) onscreen=…`. Yalnızca PID, katman, sınırlar ve ekranda-mı alanı yazılır; pencere veya sahip adı okunmaz. Bounds Quartz koordinatındadır (sol üst orijin, birincil ekran). Ön plandaki uygulamanın PID'ini bulmak için aynı komuttan sonra `lsappinfo info -only pid "$(lsappinfo front)"` kullan.

## Sonuçlar

| Senaryo | Ekran (çentikli dahili / harici) | Ekran çerçevesi | Ön plandaki uygulama | Bu ekranda katman-24 penceresi var mı? | Ön plan katman-0 penceresinin sınırları | Beklenen sezgisel sonucu |
|---|---|---|---|---|---|---|
| Masaüstü (Finder, pencere yok) | | | | | | tam ekran değil |
| Maksimize Safari | | | | | | tam ekran değil |
| Tam ekran Safari | | | | | | tam ekran |
| Keynote sunumu | | | | | | tam ekran |
| Tam ekran Xcode | | | | | | tam ekran |
| Otomatik gizlenen menü çubuğu (maksimize pencere) | | | | | | tam ekran değil (menü çubuğu imleçle geri gelince) — doğrula |
| Harici ekranda tam ekran uygulama, dahili ekran birincil | harici | | | | | harici: tam ekran, dahili: değil |

## Notlar

(Cihazda doldurulacak. Yanlış pozitif/negatif görülen senaryoları ve önerilen kural değişikliğini buraya yaz.)

## Bilinen sınır

Sezgisel ön plandaki uygulamanın PID'ini kullanır. İkinci ekranda tam ekran olan bir uygulama, klavye odağı başka ekrandayken tam ekran sayılmaz (ada o ekranda görünür kalır). Spike sırasında bu durumu da kaydet.
