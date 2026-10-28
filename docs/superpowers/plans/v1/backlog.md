# Backlog — v1 sonrası (sırayla)

> Her madde başlamadan önce kendi spec'ini alır (`superpowers:brainstorming` → `writing-plans`). Sıra, araştırma raporundaki talep ve risk değerlendirmesine göredir; kullanıcı değiştirebilir.

| # | Özellik | Neden bu sırada | Bilinen risk / ön koşul |
|---|---|---|---|
| 1 | **Mac App Store hazırlığı** | Proje hedefi; mimari zaten sandbox'lı | Spotify geçici istisnası (App Review "nadiren" onaylar) → MAS yapılandırmasında `NIMBO_SPOTIFY` kapalı olabilir; inceleme notları, gizlilik etiketi, ekran görüntüleri; Developer Program şart |
| 2 | **Sparkle güncellemeleri** (yalnızca doğrudan dağıtım) | GitHub kullanıcıları için güncelleme | Sparkle 2.10+; sandbox için `SUEnableInstallerLauncherService`, `-spks`/`-spki` mach-lookup istisnası; MAS hedefinde bağlanmaz |
| 3 | **AI ajan etkinlikleri paketi** | URL şeması hazır; geliştirici kitlesi için en yüksek değer | Claude Code / Codex / Cursor için hazır kanca betikleri + "ajan çalışıyor/bitti/izin bekliyor" görünümleri |
| 4 | **Teleprompter** | Rakiplerde sık istenen, sandbox'ta sorunsuz | Metin kaynağı, kaydırma hızı, kısayollar |
| 5 | **Gerçek ses görselleştirici** (Core Audio process tap) | Şimdi Çalıyor'u canlandırır | `NSAudioCaptureUsageDescription` + "Sistem Sesi Kaydı" izni; izin reddi sessizce boş veri döner; CPU maliyeti ölçülmeli (yalnızca ada açıkken çalıştır) |
| 6 | **Odak (Focus) durumu** | v1'den çıkarıldı | `INFocusStatusCenter` Communication Notifications yetkisi + App Review riski → spike; alternatif: Kestirmeler otomasyonuyla `nimbo://` URL'si (kullanıcı kendi Odak otomasyonunu kurar) |
| 7 | **Tarayıcı medyası** (Safari Web Extension) | Evrensel Now Playing'in MAS'a uygun yolu | Uzantı + uygulama grubu iletişimi; Chrome için ayrı uzantı |
| 8 | **WeatherKit sağlayıcısı** | Apple verisi ve atfı | Yalnızca App Store dağıtımında (Developer ID'de yok); `com.apple.developer.weatherkit`; aylık 500 bin çağrı |
| 9 | **Özel ses paleti** | Marka hissi | Ses tasarımı; kapatılabilir |
| 10 | **Kişilik katmanı** (sabah özeti, gün sonu) | Farklılaşma | Aşırıya kaçmama ilkesi (spec §1.2) |
| 11 | **iPhone eşlikçisi** | Süreklilik | Ayrı ürün kararı |
| 12 | **Apple'ın kendi Dynamic Island'ı ile birlikte yaşama** | OLED MacBook Pro duyurusu sonrası | Apple'ın API'si açılırsa entegrasyon; açılmazsa çakışmama kuralları (ada kendini o cihazda gizler/uyumlar) |
| 13 | **Kamera göstergesi** (T7.5 spike'ı izin istemi gerektirdiyse) | Gizlilik sinyali | Spike sonucuna bağlı |
| 14 | **Oynatıcı ses kaydırıcısı** (Music/Spotify `sound volume`) | v1 kapsamını dar tutmak için çıkarıldı | Basit (`set sound volume to N`); sistem ses HUD'ı değiştirilmez |
