# Backlog — v1 sonrası (sırayla)

> Her madde başlamadan önce kendi spec'ini alır (`superpowers:brainstorming` → `writing-plans`). Sıra, araştırma raporundaki talep ve risk değerlendirmesine göredir; kullanıcı değiştirebilir.

| # | Özellik | Neden bu sırada | Bilinen risk / ön koşul |
|---|---|---|---|
| 1 | **Mac App Store hazırlığı** | Proje hedefi; mimari zaten sandbox'lı | Spotify geçici istisnası (App Review "nadiren" onaylar) → MAS yapılandırmasında `LUNULA_SPOTIFY` kapalı olabilir; inceleme notları, gizlilik etiketi, ekran görüntüleri; Developer Program şart |
| 2 | **Sparkle güncellemeleri** (yalnızca doğrudan dağıtım) | GitHub kullanıcıları için güncelleme | Sparkle 2.10+; sandbox için `SUEnableInstallerLauncherService`, `-spks`/`-spki` mach-lookup istisnası; MAS hedefinde bağlanmaz |
| 3 | **AI ajan etkinlikleri paketi** (`[x]` tamamlandı) | URL şeması hazır; geliştirici kitlesi için en yüksek değer | `examples/hooks/claude-code-lunula.sh`, `codex-lunula.sh` + Ayarlar › Etkinlikler kopyala/test et eklendi |
| 4 | **Teleprompter** (`[x]` tamamlandı) | Rakiplerde sık istenen, sandbox'ta sorunsuz | `TeleprompterPopover` eklendi |
| 5 | **Gerçek ses görselleştirici** (Core Audio process tap) | Şimdi Çalıyor'u canlandırır | `NSAudioCaptureUsageDescription` + "Sistem Sesi Kaydı" izni; izin reddi sessizce boş veri döner; CPU maliyeti ölçülmeli (yalnızca ada açıkken çalıştır) |
| 6 | **Odak (Focus) durumu** | v1'den çıkarıldı | `INFocusStatusCenter` Communication Notifications yetkisi + App Review riski → spike; alternatif: Kestirmeler otomasyonuyla `lunula://` URL'si (kullanıcı kendi Odak otomasyonunu kurar) |
| 7 | **Tarayıcı medyası** (`[x]` köprü + Manifest V3 eklentisi tamamlandı) | Evrensel Now Playing'in MAS'a uygun yolu | `lunula://media/update` + `MediaSourceID.browser` + `extensions/browser-media/` (Chrome/Brave/Arc + Safari converter) |
| 8 | **WeatherKit sağlayıcısı** | Apple verisi ve atfı | Yalnızca App Store dağıtımında (Developer ID'de yok); `com.apple.developer.weatherkit`; aylık 500 bin çağrı |
| 9 | **Özel ses paleti** | Marka hissi | Ses tasarımı; kapatılabilir |
| 10 | **Kişilik katmanı** (sabah özeti, gün sonu) | Farklılaşma | Aşırıya kaçmama ilkesi (spec §1.2) |
| 11 | **iPhone eşlikçisi** | Süreklilik | Ayrı ürün kararı |
| 12 | **Apple'ın kendi Dynamic Island'ı ile birlikte yaşama** | OLED MacBook Pro duyurusu sonrası | Apple'ın API'si açılırsa entegrasyon; açılmazsa çakışmama kuralları (ada kendini o cihazda gizler/uyumlar) |
| 13 | **Kamera göstergesi** (T7.5 spike'ı izin istemi gerektirdiyse) | Gizlilik sinyali | Spike sonucuna bağlı |
| 14 | **Oynatıcı ses kaydırıcısı** (`[x]` tamamlandı) | v1 kapsamını dar tutmak için çıkarıldı | `NowPlayingVolumeSlider` + Apple Music/Spotify `sound volume` okuma/yazma eklendi |
