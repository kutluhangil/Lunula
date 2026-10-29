# Spike: kamera / mikrofon kullanım göstergesi (T7.5)

Durum: **bekliyor, kilitlenmedi.** Kod, izin istemeyen donanım özelliklerini okur:

- Mikrofon: her giriş aygıtında CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere` + aygıt listesi değişince yeniden tarama.
- Kamera: CoreMediaIO `kCMIODevicePropertyDeviceIsRunningSomewhere` (AVFoundation kullanılmadı; `AVCaptureDevice` keşfi sandbox'ta `device.camera` yetkisi olmadan boş dönebilir ve izin akışına yaklaşır).
- `com.apple.security.device.camera` / `device.audio-input` yetkileri **eklenmedi**.

Karar kuralı (plan): yetkisiz ve izin penceresiz çalışıyorsa olduğu gibi kalır; yetki gerekiyor ama pencere çıkmıyorsa Integrator yetkiyi ekler (spec §9); izin penceresi çıkıyorsa o aygıt v1'den çıkar (backlog). Şaşırtan izin istemi kabul edilmez.

## Cihazda doğrula

1. `tccutil reset Camera com.kutluhangul.lunula; tccutil reset Microphone com.kutluhangul.lunula`
2. Lunula'yı aç (Ayarlar'da "Kamera/mikrofon göstergesi" açık).
3. FaceTime'ı aç → ada compact'ta ise notch'un sağında yeşil nokta; bir ses kaydı başlat (Sesli Notlar) → turuncu nokta.
4. Bu sırada `log stream --style compact --predicate 'eventMessage CONTAINS "deny"'` çıktısını kaydet.

| Durum | Nokta görünüyor mu | İzin penceresi çıktı mı | `deny` günlüğü |
|---|---|---|---|
| FaceTime (kamera) | | | |
| Sesli Notlar (mikrofon) | | | |
| İkisi birden | | | |
| Harici kamera | | | |
