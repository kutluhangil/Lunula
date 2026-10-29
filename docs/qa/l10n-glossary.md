# Yerelleştirme sözlüğü (TR ↔ EN)

| Türkçe | English | Not |
|---|---|---|
| ada | island | Ürünün kendisi; "Dynamic Island" deme |
| çentik | notch | |
| raf | shelf | |
| hâle | halo | Işık dili |
| geçici uyarı | alert | Adada kısa süreli bildirim |
| zamanlayıcı | timer | |
| Şimdi Çalıyor | Now Playing | Başlık biçiminde |
| Katıl | Join | Toplantı düğmesi |
| Girişte başlat | Launch at login | |
| İzin ver | Allow | |
| Sistem Ayarları'nı aç | Open System Settings | |

Ton kuralları:

- Kısa ve fiil öncelikli ("Zamanlayıcı başlat", "Start a timer").
- Ünlem yok (spec §6.8; `LocalizationTests.noStringContainsExclamationMark`).
- Hitap: Türkçede "sen" (samimi, saygılı); İngilizcede düz cümle.
- Her yeni anahtar TR + EN birlikte eklenir (`LocalizationTests.everyStringHasTurkishAndEnglish`).
- Uygulama kataloğu `App/Resources/*.xcstrings`; görünüm metinleri `Packages/IslandFeatures/Sources/IslandFeatures/Resources/Localizable.xcstrings`.
