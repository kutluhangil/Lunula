# Erişilebilirlik

## Kodda yapılanlar (2026-10-29)

- Tüm denetim etiketleri tek yerde: `IslandFeatures/Accessibility/AccessibilityLabels.swift` (TR + EN; `AccessibilityTests.everyLabelResolvesInTurkishAndEnglish`).
- Ada kökü: `accessibilityElement(children: .contain)`, etiket "Lunula, <birincil etkinlik özeti>", `.isButton`.
- Oynat/Duraklat etiketi duruma göre değişir; önceki/sonraki, konum, zamanlayıcı, Katıl, raftan kaldır, Ayarlar etiketli.
- Genişlemiş adada ← → sekme değiştirir, Esc kapatır (panel non-activating key olur).
- Hareketi Azalt: metaball yok, geçişler 0.2 sn opaklık + %98 ölçek, dalga efekti ve kayan yazı durur, hâle nefesi yok.
- Şeffaflığı Azalt: parıltı yok, yalnızca anahtar çizgi. Kontrastı Artır: anahtar çizgi 1.5 pt, %60.
- Metin kontrastı siyah üzerinde: textPrimary ≈ 18:1, textSecondary (beyaz %62) ≥ 4.5:1 (`AccessibilityTests.textColorsMeetContrast`). Vurgu renkleri ≥ 3:1'e ayarlanır (T1.10).
- En küçük metin 11 pt (caption).

## Cihazda VoiceOver turu (bekliyor)

| Alan | Bulgu | Düzeltme |
|---|---|---|
| Motor (aç/kapat, sekmeler, Esc) | | |
| Şimdi Çalıyor | | |
| Zamanlayıcı | | |
| Takvim | | |
| Raf | | |
| Ayarlar | | |
