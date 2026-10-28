# Nimbo — Pazar, Teknik Uygunluk ve Tasarım Araştırma Raporu

> **Tarih:** 28 Ekim 2026 · **Aşama:** Planlama öncesi araştırma (v1) · **Hedef platform:** macOS, Mac App Store
> **Kapsam:** macOS notch / "Dynamic Island" uygulamaları (açık kaynak + ticari + Mac App Store), özellik envanteri, kullanıcı şikâyetleri, Mac App Store uygunluğu, platform zamanlaması, premium tasarım ilkeleri ve Nimbo için öneriler.
> **Ham notlar ve kod kanıtları:** [`notes/2026-10-28-ham-arastirma-notlari.md`](notes/2026-10-28-ham-arastirma-notlari.md)

**Güven etiketleri** (her önemli iddianın başında):
- **[Certain]** Birincil kaynak veya bizzat incelediğim kod/sayfa ile doğrulandı.
- **[Likely]** Güçlü çıkarım veya birden fazla bağımsız ikincil kaynak.
- **[Guessing]** Boşluk doldurma; uygulamadan önce doğrulanmalı (spike/prototip).

---

## 0. Önce rahatsız edici gerçekler (yönetici özeti)

1. **[Certain] "Mac App Store'da yayınlanacak" ile "her şeyi yapan en iyi notch uygulaması" hedefleri bugün birbiriyle çelişiyor.** Rakiplerin en sevilen üç özelliği — (a) *her* uygulamadan ve tarayıcıdan "Now Playing", (b) sistem ses/parlaklık HUD'ını değiştirme, (c) kilit ekranı widget'ları — Apple'ın özel (private) API'lerine (MediaRemote, SkyLight, CGS, DisplayServices) ya da sandbox dışı yardımcı süreçlere dayanıyor. Bunu dört açık kaynak uygulamanın kodunu (Boring Notch, Atoll, DynamicNotch, cyclop) açıp doğruladım. Mac App Store (MAS) sürümünde bu üçü ya imkânsız ya da red sebebi.
2. **[Likely] Apple bugün kendi Dynamic Island'ını Mac'e getiriyor olabilir.** 28 Ekim 2026 "Pro and Tell" lansmanında OLED + dokunmatik MacBook Pro'nun **notch yerine delik kamera + yazılımsal Dynamic Island** ile gelmesi bekleniyor (Bloomberg/Gurman, MacRumors). Bu rapor yazılırken (08:57 UTC) duyuru henüz çıkmamıştı. Buna ek olarak macOS 26/27 zaten pano geçmişini (Spotlight), iPhone Live Activities'in menü çubuğunda gösterimini, Siri AI'ı, Visual Intelligence'ı ve notch arkasındaki menü simgeleri için yerleşik taşma (») düğmesini getirdi. **Özellik listesi yarışı, Apple'a karşı kaybedilecek bir yarış.**
3. **[Certain] "Nimbo" adı App Store'da dolu.** Mac App Store'da "NIMBO" (Polonya, 19 Ekim 2026'da yayınlanmış bir dekorasyon tasarım uygulaması — iPhone/iPad/Mac) var; iOS'ta en az 5 "Nimbo…" var; Türkiye'de **"Nimbo Yazılım ve Bilgisayar Teknolojileri Ltd. Şti."** adlı bir şirketin App Store uygulaması var. App Store Connect aynı adı ikinci kez kabul etmez; mağaza adı "Nimbo — …" gibi bir varyant olmak zorunda. Marka/logo yatırımından önce TÜRKPATENT + EUIPO + USPTO taraması şart.
4. **[Certain/Likely] Pazar kalabalık ama güven boşluğu var.** 40'tan fazla notch uygulaması saydım. Kategorinin eski 1 numaralı ücretli uygulaması **NotchNook, Temmuz–Eylül 2026'da şirket içi kontrol kavgası yüzünden çöktü** (ödeme sağlayıcı askıya aldı, Setapp listeden çıkardı, alan adı düştü, lisanslar "Not Registered" görünüyor, 3.000+ iade). **MacNotch yeni satışları geçici olarak durdurdu.** MAS'taki notch uygulamalarının neredeyse hiç puan sayısı yok. → *"Apple üzerinden alınan, bozulmayan, güvenilir ve gerçekten premium"* konumu boş.
5. **[Likely] Kazanmanın yolu özellik sayısı değil.** Rakipler 40–74 özellikle yarışıyor (Notchy "74 özellik", NotchOS "40+ widget", Sapphire aylık $15.99–$30.99 AI katmanları). Oysa kullanıcıların en çok şikâyet ettiği şeyler: **pil/CPU tüketimi, "sallanan" (wobbly) animasyonlar, uyku/uyanmadan sonra kaybolma, tam ekranda araya girme, izin yağmuru, her macOS güncellemesinde kırılma.** Nimbo'nun "sanat eseri" iddiası; *az ama kusursuz* özellik + hareket/ışık/malzeme/ses/dokunma zanaati + sıfıra yakın enerji + (isteğe bağlı) kişilik ile kurulabilir.
6. **[Certain] ChatGPT araştırmasında ciddi hatalar var:** NotchNook'u Boring Notch'un eski adı sanıyor (yanlış), iki ayrı projeyi (CodeIsland ve MioIsland) tek proje sayıyor, macOS sürüm adlarını karıştırıyor; en önemlisi MAS kısıtlarını, kategorinin en çok yıldızlı reposunu (coucou, 6.6k★) ve senin kullandığın Sapphire'ı hiç ele almıyor. Ayrıntı: §2.
7. **[Certain/Likely] Lisans tuzağı:** Boring Notch, Atoll, DynamicNotch, MewNotch ve Shima **GPL-3.0**; Sapphire çekirdeği (Notchy'ye göre) **AGPL-3.0**. Bunlardan kod kopyalamak kapalı kaynak/ücretli bir MAS uygulamasıyla bağdaşmaz. Yalnızca MIT lisanslı kaynaklardan (NotchDrop, DynamicNotchKit, cyclop, OmniMac) atıfla yararlanılabilir. Ayrıca senin reponda **MIT LICENSE** dosyası var; repo şu an **private** (kontrol ettim). İleride public yapılırsa herkes kodu yasal olarak alıp yeniden satabilir — DynamicLake'in sitesinde klonlara karşı uyarı vermesi boşuna değil.

**Kısa tavsiye [Likely]:** v1.0'ı **yalnızca Mac App Store için, sandbox içinde, özel API kullanmadan** ve *"az ama ustaca"* bir kapsamla kur. Mimariyi, ileride talep olursa Developer ID ile dağıtılacak bir "Unbound/Pro" sürümüne yalnızca veri kaynaklarını değiştirerek genişleyebilecek biçimde tasarla. Farkı **hareket, ışık/malzeme dili, performans ve güven** üzerinden yarat; Apple'ın zaten çözdüğü genel özelliklerle (pano, AI sohbet, menü simgesi yönetimi) yarışma.

---

## 1. Yöntem ve kapsam

- **Verdiğin 5 kaynak** (Sapphire, MacNotch, Notchy, DynamicNotch sitesi ve GitHub reposu) tek tek taranıp özellik/fiyat/dağıtım çıkarıldı.
- **GitHub konu sayfaları** yıldıza göre tarandı: `notch` (920 repo, 668'i Swift), `dynamic-island` (791), `macbook-notch` (60), `notch-app` (60).
- **7 açık kaynak repo klonlanıp kodu incelendi:** boring.notch, Atoll, NotchDrop, cyclop, DynamicNotchKit, mew-notch (+ DynamicNotch README/commit geçmişi). Entitlement dosyaları, özel API kullanımı (SkyLight, CGS, MediaRemote, DisplayServices, CoreBrightness, OSDUIHelper), pencere seviyeleri, notch geometrisi ve animasyon sabitleri çıkarıldı (Ek A).
- **Rakip karşılaştırma sayfaları** (Notchy ve MacNotch — ikisi de taraflı, çapraz kontrol edildi) ve bağımsız haber kaynakları (MacRumors, 9to5Mac, MacMagazine, MacStories, Bloomberg özetleri).
- **Mac App Store listeleri:** Perch, NotchOS, NotchDrop, NIMBO; iTunes Search API ile "Nimbo" ad taraması.
- **Kullanıcı şikâyetleri:** Boring Notch'un 930, Atoll'un 373 issue'su içinden en çok oy/yorum alanlar; MAS yorumları; rakiplerin yayımladığı CPU/pil ölçümleri.
- **Apple birincil kaynakları:** HIG "Live Activities" (13 Ekim 2026 güncellemesi), SwiftUI dokümanları, App Review Guidelines, Apple DTS forum yanıtı.

**Sınırlar:** Reddit'e doğrudan erişemedim (ikincil özetler kullanıldı); Apple geliştirici forumları bot doğrulaması yüzünden kısmen okunabildi; NotchNook'un sitesi (lo.cafe) DNS hatası verdi (kriz); kapalı kaynak uygulamaların (Notchy, Alcove, MacNotch, DynamicLake) iç yapısı incelenemedi — iddiaları kendi sitelerinden alındı. Yıldız ve fiyatlar hızla değişir; çelişen kaynaklar tablolarda belirtildi.

---

## 2. ChatGPT raporundaki düzeltmeler

| ChatGPT'nin iddiası | Gerçek durum (28 Eki 2026) | Güven |
|---|---|---|
| "NotchNook (renamed Boring)" | Yanlış. **NotchNook**, Brezilyalı lo.cafe'nin kapalı kaynak ücretli uygulaması; **Boring Notch** bağımsız GPL projesi. NotchNook şu an kriz içinde (§3.2). | [Certain] |
| "MioIsland (CodeIsland)" tek proje | İki ayrı proje: **wxtsky/CodeIsland** (~2.5k★, 30+ AI aracı, iPhone/Watch eşlikçisi) ve **MioMioOS/MioIsland** (~539★, Claude Code oturumları). | [Certain] |
| OrdinaryNotch: "macOS 14+ Ventura" | macOS 14 = **Sonoma**; Ventura = 13. | [Certain] |
| Ice: "macOS 10.15+ (Big Sur+)" | 10.15 = **Catalina**; Big Sur = 11. Ayrıca macOS 27'nin menü çubuğu yeniden yazımı Ice/Bartender/Hidden Bar'ı bozdu (raporlar). | [Certain] / [Likely] |
| Atoll ★1,737 | 2026 kaynakları 3.7k–5k arası veriyor (çelişkili). | [Likely] |
| Boring Notch "roadmap: Live Activities…" | README'de hâlâ yapılmamış: Bluetooth live activity, hava durumu, özelleştirilebilir düzen, **kilit ekranı widget'ları, eklenti sistemi, bildirimler**. Ayrıca "Apple Developer hesabımız yok" → notarize değil, `xattr` ile Gatekeeper atlatma gerekiyor. | [Certain] |
| Eksik: Mac App Store kısıtları | Hiç ele alınmamış. Projenin en kritik kısıtı (§6). | [Certain] |
| Eksik: kullandığın Sapphire, Notchy, MacNotch, Alcove, DynamicLake, NotchNook | Hiçbiri yok; oysa kategorinin ticari zirvesi bunlar. | [Certain] |
| Eksik: en çok yıldızlı notch reposu | **Louis-CFM/coucou (6.6k★)** — karakterli AI ajan eşlikçisi; kategorinin viral örneği. | [Certain] |
| Eksik: MAS'taki notch uygulamaları | NotchDrop, Perch (Türk geliştirici), NotchOS, NotchBox, Notchmeister. | [Certain] |
| Eksik: platform riski | macOS 15.4 MediaRemote kilidi, macOS 26/27 yenilikleri, Apple'ın kendi Dynamic Island'ı, MacBook Neo (notch'suz). | [Certain] / [Likely] |

---

## 3. Pazar haritası (Ekim 2026)

### 3.1 Açık kaynak projeler (öne çıkanlar)

> "MAS uyumu" sütunu, projenin **mevcut haliyle** Mac App Store kurallarına uyup uymadığını gösterir (kod incelemesi veya README'deki izinlere göre).

| Proje | ★ | Lisans | Son aktivite | Odak / öne çıkan | MAS uyumu | Güven |
|---|---|---|---|---|---|---|
| [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch) | 11.2k | GPL-3.0 | 18 Eki 2026 (v2.8 RC) | Müzik + (sahte) görselleştirici, takvim/hatırlatıcı, raf + AirDrop, HUD değiştirme, ayna, pil | ❌ Sandbox'sız XPC yardımcı, MediaRemote/perl, SkyLight, CGS | [Certain] |
| [Louis-CFM/coucou](https://github.com/Louis-CFM/coucou) | 6.6k | MIT (kod) + isim/karakter/sesler © | 23 Eki 2026 | **"Mochi" karakteri** + AI kodlama ajanı izleme/onay, dikte, toplantı notu, iPhone Live Activity eşlikçisi, Win/Linux/Android | ❓ (incelenmedi; hook/dikte yoğun) | [Certain] |
| [jacklandrin/OnlySwitch](https://github.com/jacklandrin/OnlySwitch) | 6k | — | 27 Eki 2026 | Menü çubuğu "her şey" uygulaması; notch özellikleri de var | — | [Certain] |
| [Ebullioscopic/Atoll](https://github.com/Ebullioscopic/Atoll) | ~3.7k–5k | GPL-3.0 | 28 Eki 2026 (v2.3.3) | Sistem istatistikleri (GPU dahil), kilit ekranı widget'ları, pano, renk seçici, **gerçek ses görselleştirici**, terminal, LLM kullanım takibi; yalnızca notch'lu MBP | ❌ Sandbox yok; SkyLight, CGS, DisplayServices, SMC/IOReport, OSDUIHelper'ı `launchctl` ile kapatma | [Certain] |
| [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland) | 2.5k | — | 23 Eki 2026 | 30+ AI kodlama aracının durumu/onayları; iPhone + Apple Watch eşlikçisi | ❓ | [Certain] |
| [shobhit99/SuperIsland](https://github.com/shobhit99/SuperIsland) | 679 | — | Eyl 2026 | **JavaScript eklenti sistemi** (sandbox'lı JavaScriptCore), enerji modları (Normal/Akıllı/Düşük Güç), animasyon yoğunluğu ayarı | ❌ Accessibility istiyor | [Certain] |
| [jpomykala/NotchPrompter](https://github.com/jpomykala/NotchPrompter) | 666 | — | 7 Eki 2026 | Notch altında teleprompter | — | [Certain] |
| [jackson-storm/DynamicNotch](https://github.com/jackson-storm/DynamicNotch) | 606 | GPL-3.0 | 28 Eki 2026 (v1.6.3) | iPhone Dynamic Island fiziğini "birebir" taklit iddiası (squash/stretch, jelimsi geçişler), bildirim yakalama, kilit ekranı sözleri, 38+ dil | ❌ mediaremote-adapter (perl), Accessibility, Screen Recording | [Certain] |
| [monuk7735/mew-notch](https://github.com/monuk7735/mew-notch) | 554 | GPL-3.0 | 19 Eki 2026 | HUD değiştirme odaklı, raf | ❌ Sandbox yok, özel API'ler | [Certain] |
| [MioMioOS/MioIsland](https://github.com/MioMioOS/MioIsland) | 539 | MIT(?) | 13 Eki 2026 | Claude Code oturumlarını izleme/onaylama | ❓ | [Likely] |
| [mrkai77/DynamicNotchKit](https://github.com/mrkai77/DynamicNotchKit) | 472 | **MIT** | Nis 2026 | Notch arayüzleri için Swift paketi (Boring Notch'un `NotchShape`'i buradan) | ✅ Kütüphane (kullanılabilir) | [Certain] |
| [cshariq/Sapphire](https://github.com/cshariq/Sapphire) | 387 | AGPL-3.0 (çekirdek, Notchy'ye göre) | aktif | Senin kullandığın uygulama — §4.3 | ❌ (.pkg kurulum, sistem düzeyi özellikler) | [Likely] |
| [akalikbergenov/cyclop](https://github.com/akalikbergenov/cyclop) | 377 | **MIT** | 6 Eki 2026 | Medya, raf, pano, snippet, çevrimdışı çeviri, teleprompter; "izin gerektirmez" iddiası | ❌ Sandbox yok; MediaRemote'u `/usr/bin/perl` içinde çalıştırıyor | [Certain] |
| [ericjypark/codex-island](https://github.com/ericjypark/codex-island) | 360 | — | 23 Eki 2026 | AI kullanım limitleri | ❓ | [Certain] |
| [Yudaotor/lyrimuse](https://github.com/Yudaotor/lyrimuse) | 296 | — | 28 Eki 2026 | Kelime kelime senkron şarkı sözü (notch dahil) | ❓ | [Certain] |
| [MuQY1818/OpenYoink](https://github.com/MuQY1818/OpenYoink) | 250 | MIT | 28 Eki 2026 | Raf + ada | ❓ | [Certain] |
| [aymandakirgh/ghnotch](https://github.com/aymandakirgh/ghnotch) | 141 | MIT | Eyl 2026 | AI komut çubuğu + medya/takvim/raf | ❓ | [Certain] |
| [Lakr233/NotchDrop](https://github.com/Lakr233/NotchDrop) | — | **MIT** | May 2026 | Raf + AirDrop; **Mac App Store'da** | ✅ Sandbox açık, yalnızca genel API | [Certain] |
| Notchmeister (The Iconfactory) | — | açık kaynak | 2026 doğrulama | Notch'a sanatsal efektler (Glow, Cylon, Plasma Leak…); **MAS'ta, ücretsiz, sandbox'lı** | ✅ | [Likely] |
| [BySergiMM/OmniMac](https://github.com/BySergiMM/OmniMac) | 18 | MIT | 12 Eki 2026 | 11 araç (ada, uygulama başına ses/EQ, OCR…), "%0.017–0.033 boşta CPU" iddiası | ❓ | [Certain] |
| Diğer küçük projeler | <30 | çeşitli | 2026 | ILoveNotch, AloeNotch ("1.6 MB, hover'a kadar görünmez"), FunNotch (uygulama/site engelleyen odak zamanlayıcı), isla-mac, heymate (bas-konuş AI), TokenCats (AI kullanımıyla piksel kedi toplama), NotchApples (tenis/F1 skorları), FileIsland (ffmpeg dönüştürücü), Shima, OrdinaryNotch-Free | — | [Certain] |

**Not [Certain]:** `notch` konusundaki 920 reponun önemli kısmı alakasız (Minecraft "Notch", Linux/Hyprland kabukları); `dynamic-island` konusunda Windows (WinIsland, BrimDeck, V-Notch), Linux (Tide-island, impasto) ve Android (SmartIsland, MaterialYou-Dynamic-Island) adaları da var — "ada" metaforunun platformlar arası bir akım olduğunu gösteriyor.

### 3.2 Ticari (kapalı kaynak) uygulamalar

| Uygulama | Fiyat (Eki 2026) | Min. macOS | Kanal | Öne çıkan | Durum / not | Güven |
|---|---|---|---|---|---|---|
| **Notchy** (Vishva Variya) | $24.99 tek sefer (Kara Cuma $14.99), 7 gün deneme, 1 Mac | 13 | DMG + Homebrew, Sparkle; Dodo Payments | "74 özellik": Face Unlock, AI kullanım takibi (35+ sağlayıcı), **gerçek FFT görselleştirici (Core Audio tap)**, sözler (LRCLIB), teleprompter, komut paleti, kilit ekranı, mesaj yanıtlama, yerel geliştirici API'si (127.0.0.1:9999), 134 dil, "Liquid Glass UI" | 2026 sonbaharında ücretliye geçti (MacNotch Ağustos'ta "ücretsiz" listeliyordu); 221 karşılaştırma sayfasıyla agresif SEO; iddia: 34k kurulum, 4.3★ (4.183 uygulama içi puan) | [Certain] (kendi iddiaları) / [Likely] (geçiş tarihi) |
| **MacNotch** | $22.99 tek sefer veya $3.99/ay, 14 gün deneme, 3 Mac; Setapp | 14 | DMG + Setapp | Modüler (19 modül): Day Progress, Screen Time, Health (mola halkaları, su, nefes, 20-20-20), bildirim yanıtı, pencere yerleştirme, PR kuyrukları (GitHub/GitLab/Bitbucket/Jira), AI Coding (beta), çeviri, Liquid Glass (beta), 11 dil | **Yeni indirme ve satışlar "geçici olarak durduruldu"** | [Certain] |
| **Alcove** | $13.99 tek sefer (Stripe), 48 saat deneme | 15 | DMG | "En güzel ada" itibarı: akışkan geçişler, anında bildirimler, live activities, kaydırma hareketleri, özelleştirilebilir HUD'lar, kilit ekranı widget'ları | Raf yok, üretkenlik zayıf; geliştirici özel API'lere dayandığını ve güncellemelerde kırılabileceğini belirtmiş; bir dönem ailevi nedenle ara | [Certain]/[Likely] |
| **NotchNook** (lo.cafe, Brezilya) | Kriz öncesi $25 tek sefer (5 Mac) veya $3/ay (kaynaklar $15 da diyor) | 14.6 | DMG + Setapp | Kategorinin öncüsü: raf/AirDrop, widget'lar, Shortcuts widget'ı, özel GIF | **Temmuz–Eylül 2026 ortaklık kavgası:** Stripe askıya aldı, Setapp kaldırdı (22 Eyl), Homebrew cask kapatıldı (19 Eyl), alan adı düştü, 3.000+ iade, lisanslar çalışmıyor; Ekim'de "geri döndü" iddiası belirsiz | [Certain] (MacMagazine) / [Likely] (Homebrew tarihi, ikincil kaynak) |
| **DynamicLake Pro** (Aviorrok) | $13.99 tek sefer, deneme yok, 30 gün iade | 14 | DMG | DynaClip (pano), DynaDrop (FFmpeg ile dönüştürme), bildirimler (iMessage/WhatsApp/Slack), çağrılar, Liquid Glass, miniLake, BetterDisplay | Reddit'te "en çok önerilen ücretli" (Notchy'ye göre); **klon/sahte site uyarısı** yayınlamış | [Likely] |
| **Sapphire** (Shariq Charolia) | Ücretsiz + Basic $15.99/ay, Pro $25.99/ay, Ultra $30.99/ay (+ cihaz başı $11–15.99/ay) | 14.6 | .pkg (GitHub) | "Face ID on Mac", Blip AI ajanı, Circle to Search, spor/finans canlı veri, Android Nearby Share, %60 XDR parlaklık artışı, uygulama başına ses/10 bant EQ, şarj limiti, pencere yerleştirme | **Senin kullandığın uygulama** (§4.3) | [Certain] |
| **Seam** | $19.90–$29 tek sefer (kaynaklar çelişiyor), 48 saat deneme, yalnızca Apple silicon | 14 | DMG | Yerel dikte ve konuşma çevirisi, cihazlar/AirPods, odak zamanlayıcı | | [Likely] |
| **MediaMate** (Wouter Hennen) | ~$7–9 | 13 | DMG/Gumroad | Yalnızca HUD değiştirme + Now Playing HUD, 4 tema | | [Likely] |
| **OneNotch** | Ücretsiz; Pro $9.99 ömür boyu | 15, Apple silicon | DMG | Pano panoları, AI ajan durumu, OCR; **kamuya açık performans kampanyası** (§10) | | [Certain] |
| **Crest** | Ücretsiz; Pro $24.99 / $2.99 ay / $14.99 yıl | 14 | DMG | SSH host listesi, istatistik, todo | | [Likely] |
| **Brow** | Ücretsiz; AI için $4.99/ay veya $49/yıl | 14 | DMG | Başlatıcı, pano, pencere, OCR, fan kontrolü, PDF düzenleyici… | | [Likely] |
| **Droppy** | ~$7–9.99 tek sefer | 14 | DMG | Raf + bulut paylaşım linki | | [Likely] |
| **NotchSpace** | Ücretsiz | 15 | — | Raf, başlatma çubuğu, menü çubuğu yöneticisi | | [Likely] |
| Teleprompter'lar | CueNotch $29.99, Moody $59 | — | — | Kamera yanında senaryo okuma | | [Likely] |
| AI ajan adaları | çeşitli | — | — | Vibe Island, Ping Island, Vibe Notch, Notchi, Claude God… | | [Likely] |

### 3.3 Mac App Store'daki notch uygulamaları

| Uygulama | Fiyat | Min. macOS | Ne yapıyor | Kullanıcı sinyali | Güven |
|---|---|---|---|---|---|
| **Perch — "Dynamic Notch Island"** (Serkan Adıgüzel — **Türk geliştirici**, Türkçe destekli) | Ücretsiz + $3.99/ay, $14.99/yıl, $24.99 ve $49.99 ömür boyu | 13 | Müzik (Spotify, Apple Music, YouTube), hava, kamera, takvim, zamanlayıcı, snippet (pano), dosya tepsisi (zip), notlar, AI sohbet, mini oynatıcı | Çok az puan. Yorumlar: "20 dk sonra çok yavaşladı", **"notch'un ortasında kapanmayan Pro reklamı — hemen sildim"**, "müziği durdurana kadar açılmıyor". macOS 26'da Apple Music bilgisi kırılıp düzeltilmiş. | [Certain] |
| **NotchOS — "Dynamic Notch Island"** (Adarsh Kumar) | Ücretsiz + Pro $3.99 / $29.99 | 15 | "40+ widget", üç görsel mod, VoiceOver + klavye, çoklu ekran, 17 dil (Türkçe dahil) | Puan yok; son güncelleme Mayıs 2026 | [Certain] |
| **NotchDrop** (Lakr233) | Ücretsiz | 13 | Raf + AirDrop | Az puan; "dosyayı kopyalamıyor, link tutuyor" kafa karışıklığı | [Certain] |
| **NotchBox** | Ücretsiz + $4.99 Pro | 13 | Müzik, raf + AirDrop, Pomodoro, ayna, su/alışkanlık takibi | — | [Likely] |
| **Notchmeister** (Iconfactory) | Ücretsiz | 11 | Sanatsal notch efektleri | — | [Likely] |

**Çıkarım [Likely]:** Kategori liderlerinin hepsi MAS dışında. MAS'taki notch uygulamaları ya çok dar (NotchDrop) ya da düşük kalite/agresif upsell şikâyetli (Perch). **MAS'ta kalite lideri yok** — bu hem fırsat (rakipsiz vitrin, Apple öne çıkarma ihtimali) hem uyarı (MAS'ta keşfedilebilirlik ve bu kategorinin ödeme isteği düşük olabilir).

### 3.4 Dikey nişler

- **AI kodlama ajanı adaları** (2026'nın en hızlı büyüyen alt kategorisi): coucou 6.6k★, CodeIsland 2.5k★, codex-island, agentnotch, agent-hud, MioIsland, claude-notch-tracker; Notchy ve MacNotch de ekledi. Claude Code / Codex hook'larıyla onay (Allow/Deny), oturum durumu, kullanım limitleri. **[Certain]**
- **Teleprompter** (kamera hemen altında senaryo): NotchPrompter (666★), CueNotch ($29.99), Moody ($59), Notchy "Cuely", cyclop, Guino (MacBook Neo için ses takibiyle). Boring Notch'ta en çok istenenlerden (#351). **[Certain]** → *MAS'a tamamen uygun ve yaratıcılar için yüksek değerli.*
- **HUD değiştiriciler:** MediaMate, mew-notch, volumeHUD, SlimHUD. **[Likely]**
- **Raf (shelf) uzmanları:** NotchDrop, Droppy, OpenYoink, Dropover/Yoink (notch dışı). **[Certain]**
- **Notch gizleyiciler:** TopNotch (MakeTheWeb; macOS 27'de bozuldu), znotch, MacNotchKiller. **[Likely]**
- **Şarkı sözü:** lyrimuse, LyricsX alternatifleri. **[Certain]**

### 3.5 2026 trendleri

1. **AI ajan izleme patlaması** — en çok yıldızlı notch reposu artık bir AI eşlikçisi (coucou). **[Certain]**
2. **Özellik sayısı silahlanması** — Notchy 74 özellik, NotchOS 40+ widget, Sapphire abonelikli AI. Bu, performans gerilemesini de getiriyor (OneNotch 2.0 boşta %7–10 CPU'ya çıktı). **[Certain]**
3. **Liquid Glass görünümü** — Notchy, MacNotch (beta), DynamicLake, DynamicNotch, Atoll. **[Certain]**
4. **Gerçek ses-tepkili görselleştirici** — Core Audio process tap ile (Notchy, Atoll, OneNotch); Boring Notch'unki sahte (rastgele çubuklar). **[Certain]**
5. **Kilit ekranı varlığı** — SkyLight özel API'siyle (Alcove, Atoll, DynamicNotch, Notchy, Sapphire). **[Certain]**
6. **Yüz tanıma ile kilit açma** — Notchy, Sapphire (güvenlik açısından tartışmalı). **[Certain]**
7. **Cihazlar arası süreklilik** — coucou, Mac kilitlenince iPhone kilit ekranına/Dynamic Island'a geçiyor (CloudKit + Live Activity). **[Certain]**
8. **Performans pazarlaması** — OneNotch ve Notchy ölçüm yayımlıyor; "pil yiyor" itibarı kategorinin ana sorunu. **[Certain]**
9. **Güven krizleri** — NotchNook çöküşü, MacNotch satış durdurma, DynamicLake klon uyarısı. **[Certain]**
10. **Notch'suz Mac'ler artıyor** — MacBook Neo (Mart 2026) notch'suz; masaüstü Mac'ler zaten öyle. "Hap" (pill) modunun kalitesi artık birincil özellik. **[Certain]**

---

## 4. Özellik envanteri — kim ne yapmış?

### 4.1 Karşılaştırma matrisi

Kısaltmalar: **BN** Boring Notch · **AT** Atoll · **DN** DynamicNotch · **NY** Notchy · **MN** MacNotch · **AL** Alcove · **SP** Sapphire · **PE** Perch (MAS) · **ND** NotchDrop (MAS) · **CC** coucou
İşaretler: ✅ var · ◐ kısmi/beta · ❌ yok · ? kaynakta yok/bilinmiyor
Kaynak: kod incelemesi (BN, AT, ND), README'ler (DN, CC), vendor siteleri (NY, MN, AL, SP, PE). **Genel güven: [Likely]** — kapalı kaynaklarda vendor iddiası esas alındı.

| # | Özellik | BN | AT | DN | NY | MN | AL | SP | PE | ND | CC |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Hover ile açılan ada (peek/expand) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2 | Notch'suz ekranda "hap" (pill) | ✅ | ❌ | ✅ | ✅ | ✅ | ? | ✅ | ✅ | ◐ | ✅ |
| 3 | Çoklu ekran | ✅ | ? | ✅ | ✅ | ✅ | ? | ? | ? | ❌ | ✅ |
| 4 | Now Playing — **her** uygulama/tarayıcı (MediaRemote) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| 5 | Now Playing — Apple Music/Spotify | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| 6 | Gerçek ses-tepkili görselleştirici | ❌ (sahte) | ✅ | ✅ | ✅ | ◐ | ? | ◐ | ? | ❌ | ❌ |
| 7 | Senkron şarkı sözleri | ◐ | ? | ✅ | ✅ | ? | ? | ✅ | ❌ | ❌ | ❌ |
| 8 | Ses/parlaklık HUD değiştirme | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| 9 | Kilit ekranı widget'ları | ◐ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| 10 | Dosya rafı (shelf) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ◐ |
| 11 | AirDrop | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ◐ (+Android) | ? | ✅ | ❌ |
| 12 | Takvim | ✅ | ✅ | ? | ✅ | ✅ | ? | ✅ | ✅ | ❌ | ❌ |
| 13 | Hatırlatıcılar / todo | ✅ | ? | ? | ✅ | ✅ | ? | ? | ❌ | ❌ | ❌ |
| 14 | Hava durumu | ❌ | ✅ | ? | ✅ | ✅ | ◐ | ✅ | ✅ | ❌ | ❌ |
| 15 | Zamanlayıcı / Pomodoro / kronometre | ❌ | ✅ | ✅ | ✅ | ✅ | ? | ? | ✅ | ❌ | ❌ |
| 16 | Pano geçmişi | ❌ | ✅ | ? | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| 17 | Kamera aynası | ✅ | ✅ | ? | ✅ | ✅ | ? | ✅ | ✅ | ❌ | ❌ |
| 18 | Pil / şarj etkinliği | ✅ | ✅ | ✅ | ✅ | ? | ✅ | ✅ | ? | ❌ | ❌ |
| 19 | Bluetooth / AirPods bağlantı + pil | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ? | ❌ | ❌ |
| 20 | Bildirim yansıtma / yanıtlama | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ◐ |
| 21 | Odak (Focus) göstergesi | ❌ | ✅ | ✅ | ✅ | ✅ | ? | ? | ? | ❌ | ❌ |
| 22 | Kamera/mikrofon/ekran kaydı göstergesi | ❌ | ✅ | ✅ | ✅ | ✅ | ? | ? | ? | ❌ | ❌ |
| 23 | Sistem istatistikleri | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ? | ❌ | ❌ | ❌ |
| 24 | Pencere yerleştirme (snap) | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| 25 | AI kodlama ajanı izleme | ❌ | ◐ | ❌ | ✅ | ◐ (beta) | ❌ | ❌ | ❌ | ❌ | ✅ |
| 26 | AI sohbet / ajan | ❌ | ? | ❌ | ◐ | ◐ (çeviri) | ❌ | ✅ (ücretli) | ✅ | ❌ | ✅ |
| 27 | Teleprompter | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 28 | Genişletilebilirlik (Shortcuts/API/eklenti) | ❌ | ❌ | ❌ | ✅ | ✅ | ? | ✅ | ❌ | ❌ | ✅ (hook) |
| 29 | Kişilik / karakter | ◐ | ❌ | ❌ | ◐ (maskot) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (Mochi) |
| 30 | Liquid Glass görünümü | ❌ | ✅ | ✅ | ✅ | ◐ | ? | ? | ? | ❌ | ◐ |
| 31 | Dil sayısı | Crowdin (çok) | ◐ | 38+ | 134 | 11 | ? | ? | 11 (TR) | 6 | 14 (TR) |
| 32 | Fiyat modeli | Ücretsiz | Ücretsiz | Bağış | $24.99 | $22.99 / $3.99 ay | $13.99 | Ücretsiz + $15.99–30.99/ay | Ücretsiz + abonelik/ömür | Ücretsiz | Ücretsiz |
| 33 | Dağıtım | DMG (notarize değil) + Homebrew | DMG | DMG/ZIP | DMG + Homebrew | DMG + Setapp | DMG | .pkg | **MAS** | **MAS** + GitHub | GitHub |

### 4.2 Özellik sınıflandırması

**A. Masa bahisleri (table stakes) — olmazsa "eksik" sayılır [Likely]**
- Notch'a tam oturan, hover/tıkla ile açılan ada; notch'suz ekranda hap modu; çoklu ekran ve ekran seçimi.
- Now Playing (kapak, başlık/sanatçı, oynat/duraklat/ileri/geri, ilerleme/scrub).
- Dosya rafı + AirDrop/paylaş.
- Takvim (sıradaki etkinlik), pil/şarj bildirimi.
- Tam ekranda gizlenme, ekran kaydında/paylaşımında gizlenme seçeneği, girişte başlatma, sade ayarlar.

**B. Yaygın ama ayırt edici değil (yarısı yapıyor) [Likely]**
- Zamanlayıcı/Pomodoro, hava durumu, kamera aynası, Bluetooth/AirPods, şarkı sözü, odak göstergesi, pano geçmişi, HUD değiştirme, kilit ekranı.

**C. Gerçek farklılaştırıcılar (az kişi yapıyor, iyi yapan daha da az) [Likely]**
- Gerçek ses-tepkili görselleştirici (Core Audio tap).
- AI kodlama ajanı izleme/onay (geliştirici kitlesi için güçlü çekim).
- Teleprompter (yaratıcılar için).
- Genişletilebilirlik: Shortcuts/App Intents, yerel API, eklentiler.
- **Kişilik/karakter** (coucou'nun Mochi'si → 6.6k★ ile en viral örnek).
- Cihazlar arası süreklilik (iPhone Live Activity eşlikçisi).
- Enerji modları ve kamuya açık performans taahhüdü.
- MacNotch'un "Day Progress / Health / Screen Time" gibi ritüel modülleri.

**D. Şişkinlik / risk (marka ve güveni sulandırır) [Likely]**
- Yüz tanıma ile Mac kilidi açma (güvenlik iddiası kanıtlanamaz; Apple'ın IR derinlik sensörü yok).
- Bilgisayarı kontrol eden AI ajanı (Blip), "Circle to Search" (Apple Visual Intelligence ile çakışıyor).
- Borsa/spor/kripto bantları, notch içinde terminal, PDF düzenleyici, fan kontrolü, uygulama temizleyici, klavye temizleme kilidi, %60 XDR parlaklık "boost".
- Android Nearby Share gibi ana metaforla ilgisiz entegrasyonlar.

### 4.3 Sapphire özel inceleme (şu an kullandığın uygulama)

**Ne sunuyor [Certain]:** Ücretsiz katmanda Face ID on Mac, XDR parlaklık artışı, ses HUD'ında Spotify, uygulama başına ses + 10 bant EQ, Snap Zones, dosya rafı + Android Nearby Share, kafein/kilit ekranı, müzik widget'ı (dalga formu, sözler, sıradaki şarkılar), sonsuz pano geçmişi, etkileşimli takvim ızgarası, ayna, hava, Bluetooth hızlı bağlantı, notch banner bildirimleri, Shortcuts, 20-20-20 göz molası, menü çubuğu özelleştirme. Ücretli: Blip Live ($15.99/ay), Blip Agent + Circle to Search + spor canlı etkinliği ($25.99/ay), finans + spor widget'ı ($30.99/ay); her ek Mac için aylık $11–15.99.

**Neden sevmemiş olabilirsin (çıkarım) [Likely]:**
1. Ücretli kısım tamamen AI ve canlı veri; bir notch uygulaması için yıllık $190–$370 — "abonelik yorgunluğu" ve değer/fiyat dengesizliği.
2. Ürün odağı dağınık: "The Notch, Reimagined" diyor ama sitesinin yarısı bir AI ajanını satıyor; notch metaforu kayboluyor.
3. Ekran görüntündeki tasarım sorunları (§8.6): ada değil "pano/slab", 4 eşit ağırlıklı modül, ikon çorbası, tutarsız veri, kesilen metinler.

---

## 5. Kullanıcı şikâyetleri ve başarısızlık modları → "Nimbo asla…" listesi

### 5.1 Kanıtlar (en çok oy/yorum alanlar)

| Şikâyet kümesi | Kanıt | Güven |
|---|---|---|
| **OS güncellemesinde kırılma (Now Playing)** | BN #417 "macOS 15.4 sonrası Now Playing çalışmıyor" (👍54, 58 yorum) + kopyaları #434, #554, #580; BN #779 macOS 26'da Apple Music kaynağı bozuldu; Perch macOS 26'da Apple Music'i düzeltmek zorunda kaldı | [Certain] |
| **"Sallanan/jöle" animasyonlar** | BN #364 "jiggly wobbly animasyonu kapatma" (👍26), #335 (👍21), #350 kapanma animasyonu (👍21), #303 (👍15), #316 "kapanırken titriyor ve gerçek notch'a oturmuyor" | [Certain] |
| **Pil / CPU** | BN #338: M4 MBP'de boşta saatte ~%5 pil, gün boyu pil 3–5 saate düştü; BN #1260 (Mayıs 2026); AT #641 "çok yüksek CPU"; OneNotch 1.1: müzik çalarken %26–40 CPU, Energy Impact 33.6; NotchNook'ta pil şikâyetleri ve sürüm geri alma | [Certain] |
| **Uyku/uyanma ve ekran değişimi** | BN #336 "uzun uykudan sonra çöküyor/kayboluyor/açılmıyor" (45 yorum), #352 "kapak açılınca notch yerinden kaymış", #339 | [Certain] |
| **Açılışta takılma** | BN #341 "açılırken kekeme" (👍12, 15 yorum) | [Certain] |
| **Tam ekran / harici ekran** | BN #119 "tam ekranda ve harici ekranda kapat" (👍14), #247, #239 "yayın izlerken gizle", #74 "ekran seç", #110 "uygulama hariç tut"; NotchNook'un harici ekranda sahte notch çizmesinden rahatsız olanlar | [Certain] |
| **İzin yağmuru / korkutucu izinler** | AT #280/#299/#480 her açılışta "Developer Tools erişimi" penceresi; Atoll "izin verdikten sonra çıkıp yeniden açın"; MacNotch karşılaştırması "çok geniş izin istiyor" | [Certain] |
| **HUD değiştirmenin yan etkisi** | AT #70: sistem HUD'ı açıkken Bluetooth kulaklıkta yalnızca **sol kulak** sesi değişiyor | [Certain] |
| **Yanlış/eksik veri** | AT #332/#216/#249 Focus modu yanlış etiket/ikon; AT #303 medya görünmüyor; AT #382 tarayıcı medyasında kontrol yok | [Certain] |
| **Agresif upsell** | Perch MAS yorumu: "notch'un ortasında kapanmayan Pro yükseltme — hemen sildim" | [Certain] |
| **Kafa karıştıran raf semantiği** | NotchDrop MAS yorumu: dosyayı kopyalamıyor, link tutuyor; silmek için Option+tık zorunlu | [Certain] |
| **Dağıtım/kurulum acısı** | BN notarize değil (`xattr -dr com.apple.quarantine`); BN #855 "güncelleme imza hatası", #395; Homebrew talepleri | [Certain] |
| **İki notch uygulaması aynı anda** | MacNotch SSS: aynı bölge ve hover olayları için yarıştıkları için titreme | [Likely] |
| **Lisans/şirket sürekliliği** | NotchNook krizi; Alcove'da geliştirici arası | [Certain]/[Likely] |

### 5.2 Nimbo asla… (ürün ilkeleri — tartışmaya açık)

1. **…sistem davranışını bozmaz.** İkinci bir HUD göstermez, ses kanallarını kurcalamaz, sistem servislerini kapatmaz (AT #70; Guideline 2.5.9).
2. **…sallanmaz.** Aşırı yaylanma yok; açılış/kapanış notch'a milimetrik oturur; "Hareketi Azalt" ayarına tam uyar (BN #364 ve ilgili 100+ oy).
3. **…boştayken enerji harcamaz.** Kapalı ve medya yokken ~%0 CPU, saniyede <1 uyanma; görünmeyen hiçbir şey animasyon yapmaz (§10).
4. **…notch'a reklam/upsell koymaz.** HIG açıkça "Live Activity'de reklam/promosyon gösterme" der; Perch örneği.
5. **…ilk açılışta izin yağdırmaz.** Her izin, ilgili özellik ilk kullanıldığında, tek cümlelik gerekçeyle istenir; "çıkıp yeniden açın" gerektiren akış yok.
6. **…uyku/uyanma, kapak, ekran ekleme/çıkarma sonrası kaybolmaz veya kaymaz.**
7. **…tam ekran video/sunum/oyunun üstüne çıkmaz.** Tam ekranda varsayılan olarak geri çekilir; uygulama bazlı istisna listesi.
8. **…tutarsız veya yanlış birimde veri göstermez.** Hava durumu tek kaynaktan; birimler sistem yerel ayarından (Türkiye'de km/sa, °C); saat/takvim sistem formatı.
9. **…metni anlamsızca kesmez.** Önce kısaltma kuralları, sonra yumuşak kayan yazı; "…" son çare.
10. **…ada olmaktan çıkıp pano olmaz.** Genişlemiş hali bile notch'a eş merkezli ve "kamera etrafına sıkı" (HIG); dört eşit ağırlıklı modülü yan yana dizmez.
11. **…temel özelliği aboneliğin arkasına saklamaz.**
12. **…bir lisans sunucusuna rehin kalmaz.** Satın alma App Store/StoreKit üzerinden; sunucu kapansa da uygulama çalışır.
13. **…kullanıcıyı Gatekeeper'ı atlatmaya zorlamaz.**
14. **…başka bir notch uygulamasıyla sessizce çakışmaz.** Tespit edip kullanıcıya nazikçe söyler.
15. **…belirsiz davranmaz.** Raf "kopyala mı, taşı mı, link mi?" sorusunu görsel olarak netleştirir.
16. **…mahremiyeti ihlal etmez.** Ekran paylaşımında/kayıtta gizlenme seçeneği; hassas içerik (bildirim metni, pano) varsayılan olarak maskelenebilir (HIG).
17. **…bir sonraki macOS sürümünde kırılacak özel API'ye dayanmaz** (MAS sürümü için kesin kural).

---

## 6. Mac App Store uygunluk analizi

### 6.1 Kurallar ve Apple'ın resmi duruşu

- **[Certain] Sandbox zorunlu ve uygulama kendi içinde bütün olmalı** (App Review Guideline 2.4.5): MAS'taki her yürütülebilir dosya sandbox'lı olmalı; harici yardımcı/kurulum, kod indirme yok. → Boring Notch'un sandbox'sız XPC yardımcısı, Atoll'un sandbox'sız yapısı, cyclop/DynamicNotch'un `/usr/bin/perl` hilesi MAS'ta kabul edilemez.
- **[Certain] Yalnızca genel (public) API** (Guideline 2.5.1). SkyLight, CGS*, MediaRemote, DisplayServices, CoreBrightness özeldir.
- **[Certain] Guideline 2.5.9:** "Ses aç/kıs, sessiz anahtarı gibi standart düğmelerin veya diğer yerel arayüz öğelerinin/davranışlarının işlevini değiştiren veya devre dışı bırakan uygulamalar reddedilir."
- **[Certain] Apple DTS (Quinn, forum 780626):** "Sandbox'lı bir uygulama **Input Monitoring** iznini (CGEventTap, yalnızca dinleme) kullanabilir… Sandbox'lı bir uygulamanın **Accessibility** iznini kullanması mümkün değildir [geçici istisna yetkileri olmadan]. DTS, sandbox'lı uygulamalarda genel erişilebilirlik API'lerinin kullanımını desteklemez." DTS, App Review adına konuşmadığını da vurguluyor.
- **[Certain] Somut emsal:** media-control-relay projesinin MAS 1.0 sürümü (Eylül 2026) ses HUD değiştirmeyi **çıkararak** gönderildi; "aktif event tap teknik olarak sandbox'ta çalışıyor ama bu App Review'un kabul edeceği anlamına gelmiyor"; Accessibility'yi erişilebilirlik dışı amaçla kullanan Mac uygulamaları 2.4.5'ten reddedilmiş (forum 820594: ⌘V gönderen pano yöneticisi iki kez red).
- **[Certain] Apple Events:** Sandbox, başka uygulamaya Apple Event göndermeyi engeller; ya hedef uygulamanın "scripting access group"u varsa `com.apple.security.scripting-targets` (tercih edilen) ya da `temporary-exception.apple-events` (dikkatle incelenir, sıklıkla reddedilir; Finder/System Events neredeyse her zaman red) gerekir.
- **[Likely] Ticari marka:** Guideline 2.3.7 (metaveriyi markalı terimlerle doldurma) ve 5.2.x (Apple ürünlerine kafa karıştırıcı benzerlik). Yine de MAS'ta "Dynamic Notch Island" adlı uygulamalar onaylanmış → risk düşük-orta, ama Nimbo'nun adında/alt başlığında "Dynamic Island" kullanmamasını öneririm (Atoll bile adını "DynamicIsland"dan değiştirip TRADEMARKS dosyası eklemiş).

### 6.2 Özellik bazında MAS uygunluk matrisi

| Özellik | Yöntem / API | Yetki & izin | MAS'ta mümkün mü? | İnceleme riski | Güven |
|---|---|---|---|---|---|
| Notch üstünde pencere | `NSPanel`/`NSWindow`, seviye `.statusBar + n`, `collectionBehavior` (canJoinAllSpaces, fullScreenAuxiliary, stationary) | yok | ✅ (NotchDrop, Perch MAS'ta) | Düşük | [Certain] |
| Notch geometrisi | `NSScreen.safeAreaInsets.top` + `auxiliaryTopLeftArea/RightArea` | yok | ✅ | — | [Certain] |
| Hover algılama | `NSEvent` global fare izleme / tracking area | yok | ✅ | Düşük | [Certain] |
| Global kısayol | `RegisterEventHotKey` (ör. sindresorhus/KeyboardShortcuts) | yok | ✅ | Düşük | [Likely] |
| Now Playing — Apple Music | AppleScript/ScriptingBridge + `com.apple.Music.playerInfo` dağıtık bildirimi | `scripting-targets` (com.apple.Music.playback) + Automation onayı | ✅ | Düşük-orta | [Likely] |
| Now Playing — Spotify | AppleScript + `com.spotify.client.PlaybackStateChanged` | `temporary-exception.apple-events` (com.spotify.client) | ◐ (Perch onaylanmış) | Orta — gerekçe yazılmalı | [Likely] |
| Now Playing — **her uygulama/tarayıcı** | MediaRemote (özel; macOS 15.4'ten beri yetki kilitli) | — | ❌ | Red | [Certain] |
| Tarayıcı medyası (alternatif) | Uygulamaya gömülü **Safari Web Extension** (+ Chromium için localhost köprüsü) | `network.server` | ◐ | Orta | [Guessing] |
| Gerçek ses görselleştirici | Core Audio process tap (`AudioHardwareCreateProcessTap`, macOS 14.2+) + vDSP FFT | `NSAudioCaptureUsageDescription` (Info.plist'e **elle**; build ayarı sessizce düşürüyor) + "Sistem Sesi Kaydı" izni | ◐ (spike gerekli) | Orta | [Likely]/[Guessing] |
| Ses/parlaklık HUD **değiştirme** | Tüketen event tap + Accessibility; parlaklık özel API | — | ❌ | Red (2.4.5, 2.5.9) | [Likely] (güçlü kanıt) |
| Kilit ekranı widget'ları | SkyLight özel API | — | ❌ | Red | [Certain] |
| Bildirim yansıtma/yanıt | Bildirim veritabanı (Full Disk Access) / Accessibility | — | ❌ | Red | [Certain] |
| Pencere yerleştirme (başka uygulamaların pencereleri) | Accessibility | — | ❌ (pratikte) | Yüksek | [Likely] |
| Dosya rafı + sürükle-bırak | `NSDraggingDestination`, security-scoped bookmark, kopya kapsayıcıda | user-selected files, bookmarks | ✅ | Düşük | [Certain] |
| AirDrop / paylaş | `NSSharingService(.sendViaAirDrop)`, paylaşım menüsü | yok | ✅ | Düşük | [Certain] |
| Takvim / Hatırlatıcılar | EventKit | calendars / reminders + TCC | ✅ | Düşük | [Certain] |
| Hava durumu | WeatherKit (+ CoreLocation) | WeatherKit yeteneği, location | ✅ (kota/maliyet §6.3) | Düşük | [Certain] |
| Zamanlayıcı / Pomodoro / kronometre | uygulama içi | yok | ✅ | — | [Certain] |
| Pano geçmişi | `NSPasteboard.changeCount` izleme | yok (gelecekte gizlilik istemi olabilir) | ✅ | Düşük | [Likely] |
| Panodan otomatik yapıştırma (⌘V gönderme) | `CGEvent.post` | PostEvent/Accessibility | ❌/riskli | İki kez red emsali | [Likely] |
| Kamera aynası | AVFoundation | device.camera | ✅ | Düşük | [Certain] |
| Pil / şarj | IOPowerSources | yok | ✅ | Düşük | [Likely] |
| AirPods / Bluetooth bağlanınca + pil | IOBluetooth (pil özellikleri başlıklarda belgeli değil) | device.bluetooth | ◐ | Orta | [Guessing] |
| Odak (Focus) açık/kapalı | `INFocusStatusCenter` (yalnızca `isFocused`, mod adı yok; KVO güvenilmez, yoklama gerekir) | Focus Status kullanım metni + Communication Notifications yeteneği | ◐ | Düşük | [Likely] |
| Kamera/mikrofon kullanımda göstergesi | CoreMediaIO / CoreAudio "running somewhere" özellikleri | yok (kamera için yetki gerekebilir) | ✅ (spike ile doğrula) | Düşük | [Likely] |
| İndirme tamamlandı | Downloads klasörü izleme | `files.downloads.read-only` | ✅ | Düşük | [Likely] |
| Sistem ekran kaydı göstergesi | genel API yok | — | ❌ | — | [Likely] |
| CPU/RAM istatistikleri | `host_statistics`, `sysctl` | yok | ✅ (sıcaklık/fan için SMC ❌) | Düşük | [Likely] |
| Teleprompter (+ sesle takip) | uygulama içi (+ Speech) | (mikrofon, sesle takip için) | ✅ | Düşük | [Likely] |
| Shortcuts / App Intents ("Nimbo'da göster") | App Intents | yok | ✅ | Düşük | [Certain] |
| URL şeması / yerel API (AI ajan hook'ları için) | URL scheme, localhost sunucu | `network.server` | ✅ | Düşük-orta | [Likely] |
| AI özellikleri (kendi anahtarınla) | URLSession | `network.client` | ✅ | Düşük | [Likely] |
| Girişte başlatma | `SMAppService.mainApp` | yok | ✅ | — | [Certain] |
| Ekran paylaşımında gizlenme | `NSWindow.sharingType = .none` (bazı uygulamalar yine yakalayabilir) | yok | ✅ | — | [Likely] |
| Dokunsal geri bildirim | `NSHapticFeedbackManager` | yok | ✅ | — | [Certain] |
| Notch gizleme (siyah menü çubuğu şeridi) | menü çubuğu arkasına siyah pencere | yok | ✅ | Düşük | [Likely] |
| Uyanık tut (caffeinate) | `IOPMAssertionCreateWithName` | yok | ✅ | Düşük | [Likely] |
| iPhone eşlikçisi (Mac'ten iPhone Dynamic Island'a) | iOS uygulaması + CloudKit + ActivityKit | iCloud | ✅ | Düşük | [Likely] |

**Özet [Likely]:** MAS'ta kaybedilen üç "büyük" özellik (evrensel Now Playing, HUD değiştirme, kilit ekranı) dışında, pazarın sevdiği özelliklerin **büyük çoğunluğu MAS'ta yapılabilir.** Kayıpların telafisi: (1) Apple Music + Spotify'ı kusursuz yapmak (dinleyicilerin büyük kısmı), (2) tarayıcı için Safari uzantısı denemesi, (3) HUD yerine Nimbo'nun kendi içinde güzel ses kontrolü, (4) kilit ekranı yerine iPhone eşlikçisi.

### 6.3 Veri kaynağı kısıtları

- **[Likely] Spotify Web API bir çıkış yolu değil.** Yeni uygulamalar "Development Mode"da en fazla 5 izinli kullanıcıyla sınırlı (Şubat 2026'dan beri sahibin Premium olması gerekiyor); "Extended Quota" 15 Mayıs 2025'ten beri yalnızca tescilli şirketlere ve ~250 bin aylık aktif kullanıcıya açık. → Spotify yalnızca AppleScript yoluyla.
- **[Certain] WeatherKit:** Geliştirici üyeliği başına ayda 500.000 çağrı dahil (geliştirme + üretim aynı havuz); üstü ücretli kademe; atıf (attribution) zorunlu. Kullanıcı başına saatte 1 çağrı ≈ yalnızca ~700 sürekli aktif kullanıcı → agresif önbellekleme (konum ızgarası, 30–60 dk, yalnızca görünürken) şart. [Likely] Open-Meteo'nun ücretsiz katmanı **ticari değil**; ücretli uygulamada ticari plan gerekir.
- **[Likely] Şarkı sözleri:** LRCLIB ücretsiz ve açık ama sözler telif konusu; ücretli bir MAS uygulamasında hukuki risk taşır (Notchy kullanıyor). v1 dışı veya hukuki görüşle.
- **[Certain] Apple Music:** Uygulamanın scripting access group'ları var (playback, library.read, library.read-write) → MAS dostu yol.

### 6.4 Dağıtım seçenekleri

| Seçenek | Artılar | Eksiler | Tavsiye |
|---|---|---|---|
| **A. Yalnızca Mac App Store** | Güven (Apple ödeme/makbuz; lisans sunucusu yok — NotchNook dersi), otomatik güncelleme, Aile Paylaşımı, Gatekeeper derdi yok, MAS'ta kalite lideri yok | 3 büyük özellik yok; inceleme gecikmeleri; %15 komisyon (Small Business Program); tek seferlik ücretli uygulamada doğrudan deneme yok (çözüm: ücretsiz indirme + "14 günlük deneme" adlı 0 TL tüketilemez IAP veya ücretsiz çekirdek + kilit açma) | **v1.0 için önerilen** [Likely] |
| **B. MAS + Developer ID "Unbound" sürümü** | Güçlü kullanıcılara evrensel Now Playing, HUD, kilit ekranı | İki derleme, iki ödeme sistemi (Paddle/Lemon Squeezy), iki kat destek/QA, özel API bakımı her macOS'ta; mesaj karmaşası | v1 sonrası, talep kanıtlanırsa. Mimariyi şimdiden buna hazır kur (veri kaynakları protokol arkasında). |
| **C. Yalnızca doğrudan satış** | En geniş özellik | Hedefinle (MAS) çelişir; güven/notarizasyon/ödeme altyapısı yükü | Önermiyorum |

---

## 7. Platform zamanlaması ve "sherlock" riski

### 7.1 Doğrulanmış gelişmeler

- **[Certain] macOS 27 "Golden Gate"** (WWDC: 8 Haziran 2026; yayın: Eylül 2026) — **yalnızca Apple silicon** (Intel desteği bitti; A serisi MacBook Neo dahil). Menü çubuğu tek pencere olarak yeniden yazıldı (Bartender/Ice/Hidden Bar bozuldu); notch arkasında kalan simgeler için yerleşik, ayarlanamayan » düğmesi geldi. **Liquid Glass şeffaflık kaydırıcısı** (çok şeffaftan tamamen renkli) ve "Kenarlıkları Göster" erişilebilirlik seçeneği eklendi. Widget'lar uygulama açıkken gerçek zamanlı güncelleniyor; Shortcuts'a ekran görüntüsü ve bildirim tetikleyicileri geldi; Siri AI + "Search or Ask" çubuğu ve Mac'te Visual Intelligence geldi.
- **[Certain] macOS 26 Tahoe**: Spotlight'ta pano geçmişi (26.1'de 30 dk / 8 saat / 7 gün saklama), iPhone Live Activities'in Mac menü çubuğunda gösterimi (HIG: tıklayınca iPhone Mirroring açılır).
- **[Certain] Donanım:** MacBook Neo (4 Mart 2026, A18 Pro, 13", **notch'suz**); M5 Pro/Max MacBook Pro (Mart 2026); M6 14" MacBook Pro (27 Ekim 2026; yalnızca çip güncellemesi, tasarım değişikliği yok → notch'lu olarak kalması [Likely]). **[Likely] Bugün (28 Ekim)**: OLED + dokunmatik MacBook Pro 14/16 — "Apple notch'u kaldırıp Dynamic Island ekleyecek" (Gurman: iPhone'dakinden küçük delik + yazılımsal ada), ~$2.899'dan başlaması bekleniyor; mevcut mini-LED modellerle birlikte satılacak.
- **[Likely] Mac'e özgü ActivityKit yok** (macOS 27 itibarıyla): Mac'teki Live Activities, iPhone'dan Continuity ile geliyor. Apple Mac'te üçüncü taraf uygulamalara Dynamic Island API'si açarsa oyun değişir — duyuruyu bugün izlemek gerekiyor.

### 7.2 Apple'ın kapattığı / kapatmak üzere olduğu alanlar

| Alan | Apple'ın çözümü | Nimbo için anlamı |
|---|---|---|
| Pano geçmişi | Spotlight pano geçmişi (macOS 26) | Basit pano artık sıradan; ya belirgin biçimde daha iyi (sabitleme, görsel içi metin arama, gizlilik) ya da v1'e alma |
| Live Activities | iPhone etkinlikleri Mac menü çubuğunda (macOS 26) | Apple "etkinlik" dilini sahipleniyor; Nimbo **Mac'e özgü** etkinliklere odaklanmalı |
| AI sohbet / asistan | Siri AI, Search or Ask, ChatGPT seçeneği (macOS 27) | Genel AI sohbet kutusu yapma |
| Ekrandan arama | Visual Intelligence ⇧⌘Space (macOS 27) | "Circle to Search" yapma |
| Notch arkasındaki menü simgeleri | Yerleşik » taşma düğmesi (macOS 27) | Menü çubuğu yöneticisi yapma |
| Dynamic Island | OLED MacBook Pro (bekleniyor) | Bu makinelerde Apple'ın adasıyla **çakışmamak** (algıla ve geri çekil / yanına yerleş) |
| Widget'lar | Gerçek zamanlı + XL masaüstü widget'ları (macOS 27) | WidgetKit eşlik widget'ları ucuz bir artı olabilir |

### 7.3 Sonuç [Likely]
Notch'lu MacBook kurulu tabanı (2021–2026 Pro, 2022+ Air) yıllarca büyük kalacak; masaüstü Mac'ler ve MacBook Neo notch'suz. Apple'ın adası şimdilik yalnızca en pahalı OLED modellerde. Yani pazar kaybolmuyor ama **"Mac'e Dynamic Island getiren uygulama" söylemi bugünden itibaren eskiyor.** Nimbo'nun hikâyesi "Apple'ın ada'sının taklidi" değil, kendine ait bir **ışık, ritim ve kişilik** dili olmalı.

---

## 8. Tasarım araştırması — "sanat eseri" için zemin

### 8.1 Apple'ın Dynamic Island kuralları (HIG "Live Activities", 13 Ekim 2026 sürümünden damıtılmış) [Certain]

- **Sunumlar:** *Compact* (tek etkinlik; kameranın iki yanında öncü + takip öğe), *Minimal* (birden çok etkinlik; biri adaya bitişik, diğerleri **ayrık daire/oval baloncuk**, en fazla 3), *Expanded* (dokun-basılı tut ya da önemli uyarı), Kilit ekranı, StandBy.
- **Renk:** "Dynamic Island'daki Live Activities **siyah opak arka plan** kullanır. Kişiliği yansıtmak için metin ve nesnelerde cesur renkler kullan." Arka plan rengi değiştirilemez; koyu modda adanın etrafındaki **"key line" (kenar çizgisi) içerikle uyumlu renklendirilir.**
- **Geometri:** "Tutarlı kenar boşlukları ve **eş merkezli (concentric) yerleşim** kullan… köşe yarıçapını sabit kodlamak yerine `ContainerRelativeShape` kullan." İçeriği kenara kadar çizme; blokları ayırmak için içe gömülü kap ya da kalın çizgi kullan. İpucu: hizalamayı görmek için içeriği bulanıklaştırıp çevreye bak.
- **Tipografi:** "Büyük, **orta ağırlık veya daha kalın** metin kullan. Küçük metni idareli kullan."
- **Compact:** İki taraf tek bilgi gibi okunmalı (aynı renk ve tipografi); **kameraya sıfır boşlukla yaslan**; iki taraf dengeli genişlikte (kısaltılmış birimler).
- **Expanded:** "İçeriği kameranın etrafına **sıkıca sar**" — kameranın varlığını azaltır; compact ile göreli yerleşimi koru (expanded = compact'ın büyümüşü). Yükseklik içeriğe göre dinamik.
- **Animasyon:** Sistem + özel animasyonlar **en fazla 2 saniye**; sayısal değişimlerde `numericText` içerik geçişi; düzen değişince öğeleri silip yeniden eklemek yerine **yeni konumlarına taşı**; çakışan öğelerden kaçın.
- **Etkileşim:** Mümkünse tek öğe (oynat/duraklat gibi); yanlışlıkla dokunmayı önle.
- **İçerik ilkeleri:** Reklam/promosyon yok; hassas bilgi gizlenebilir olmalı; yalnızca önemli güncellemelerde uyarı; iş bitince hemen bitir; çok olayı **tek etkinlikte döndür.**
- **Ölçüler (iOS, pt):** compact öğe 62.33×36.67 (430 genişlik), minimal 36.67–45×36.67, expanded 408×84–160, kısıtlı genişlik 28×28. "macOS için iOS ölçülerini kullan."

### 8.2 Hareket (motion) ilkeleri

- **[Likely] Apple'ın "Designing Fluid Interfaces" (WWDC18) ilkeleri** — Dynamic Island'ın tasarımcılarından Chan Karunamuni'nin de sunduğu oturum: anında tepki, **her animasyon kesilebilir ve yönü değiştirilebilir**, hareket 1:1 takip, momentum, mekânsal tutarlılık.
- **[Likely] "Animate with springs" (WWDC23):** Yaylar süre + sekme (`.spring(duration:bounce:)`) ile düşünülür; `.smooth` (sekmesiz), `.snappy` (az), `.bouncy` (çok). Yaylar kesildiğinde hızı korur → doğal kesilebilirlik.
- **[Certain] Kullanıcı kanıtı:** Boring Notch'ta "jöle/sallanma"yı kapatma istekleri 100+ oy topladı; bir gözlemci iOS 16'daki adanın "nefes aldığını", iOS 17/18'de ise yaylanmanın "abartıldığını" ağır çekimde gösterdi. **Premium = ölçülü fizik.**
- **[Certain] Boring Notch sabitleri (referans):** açılma `spring(response: 0.42, dampingFraction: 0.8)`, ana etkileşim `interactiveSpring(0.38, 0.8)`, buton sekmesi `spring(0.3, 0.3)` (çok sekmeli); açık boyut 640×190, köşe yarıçapları kapalı (üst 6 / alt 14), açık (üst 19 / alt 24).
- **[Certain] "Bölünme/birleşme" (metaball) tekniği:** şekilleri bulanıklaştır → alfa eşiğiyle tekrar katılaştır. SwiftUI'da yerel olarak var: `GraphicsContext.Filter.alphaThreshold(min:max:color:)` + `.blur(radius:)` (macOS 12+). Metal ile yapanlar bulanıklığı `sin(ilerleme·π)` eğrisiyle geçişin ortasında maksimuma çıkarıyor ve **boştayken render'ı tamamen duraklatıyor** (kare başına ~0.06 ms CPU, ~0.2 ms GPU).

**Nimbo için hareket taslağı [Guessing — prototiple ayarlanacak]:**

| Etkileşim | Öneri | Gerekçe |
|---|---|---|
| Hover niyeti (peek) | İmleç notch bölgesinde ~80–120 ms kalırsa ve yavaşsa aç; hızla geçerse açma | Yanlışlıkla açılmayı önler (Notchy 60 ms tetik kullanıyor) |
| Açılma | `spring(duration: ~0.45, bounce: 0.05–0.12)` | Canlı ama sallanmayan |
| Kapanma | `spring(duration: ~0.35, bounce: 0)` + 200–300 ms "çıkış toleransı" | "Kapanırken titreme" şikâyetleri |
| İçerik değişimi | `.smooth`, `blurReplace`, `numericText` | HIG: düzeni koru |
| İkinci etkinlik | Ayrık baloncuğun metaball ile "tomurcuklanması" | HIG minimal sunumu |
| Süre sınırı | ≤ 2 s | HIG |
| Hareketi Azalt | Yay yok; ölçek + saydamlık geçişi | Erişilebilirlik |

### 8.3 Geometri — notch'u "görünmez" yapmak

- **[Certain]** Notch ölçüsü çalışma anında hesaplanmalı: yükseklik = `safeAreaInsets.top`, genişlik = ekran genişliği − `auxiliaryTopLeftArea` − `auxiliaryTopRightArea` (NotchDrop yöntemi). Notch'suz ekranda bu değerler 0 → hap moduna geç.
- **[Likely]** Ölçülen değerler (varsayılan çözünürlükte): 14" ≈ 185×32 pt, 16" ≈ 220×38 pt. Air modelleri cihazda ölçülmeli.
- **[Likely]** Boring Notch/DynamicNotchKit köşelerde **kuadratik Bézier** kullanıyor → eğrilik süreksizliği büyük boyutta "kırık" görünür. Premium yaklaşım: alt köşelerde **sürekli eğrilik (squircle, `RoundedRectangle(style: .continuous)`)**, üstte donanım notch'unun dışa açılan "omuz" eğrisini taklit eden özel ters eğri; iç öğelerde eş merkezli yarıçap (iç = dış − dolgu).
- **[Likely] Kapalı durum = donanım notch'u ± 0 px.** En güçlü "sihir" anı: ada yokken var olmaması. (AloeNotch ve coucou "hover'a kadar görünmez" ilkesini pazarlıyor.)

### 8.4 Malzeme — siyah çekirdek mi, Liquid Glass mı?

- **[Certain]** HIG, adayı siyah opak tanımlıyor. **[Likely]** Fiziksel sebep: notch ekranda piksel olmayan bir **delik**; yarı saydam cam bir ada, notch bölgesinde siyah bir "ısırık" gösterir ve notch'u gizlemek yerine vurgular.
- **[Likely] Öneri:** Notch'a değen **çekirdek her zaman saf siyah (#000)**; Liquid Glass yalnızca kameradan uzaktaki ayrık baloncuklarda/genişlemiş panelin alt kısmında ya da siyah çekirdeğin çevresinde ince bir **cam kenar (rim)** olarak. macOS 27'nin cam kaydırıcısında (çok şeffaf ↔ tamamen renkli), "Şeffaflığı Azalt" ve "Kontrastı Artır" ayarlarında doğru görünmeli.
- **[Likely]** macOS 26'da menü çubuğunun şeffaflaşmasıyla siyah ada daha belirgin hale geldi → kapalı durum kusursuz olmalı, genişleme anı ise sahnenin yıldızı.

### 8.5 Tipografi, renk, ses, dokunma

- **Tipografi [Likely]:** SF Pro (Text/Display), sayılarda SF Pro Rounded; zamanlayıcılarda `monospacedDigit`; ana bilgi orta+ ağırlık (HIG); ikincil metin ≥ 11 pt; tek bir tip ölçeği (ör. 11/13/15/20/28).
- **Renk [Likely]:** Çekirdek siyah; birincil metin inci beyazı, ikincil gri; **renk = içerikten gelen anlam** (albüm kapağından türetilen canlı ama kontrastı kontrol edilmiş vurgu, etkinlik başına tek vurgu). Kırmızı yalnızca gerçek hata için.
- **Ses [Guessing]:** 5–8 sesten oluşan küçük, sıcak bir palet (aç, kapat, bırak, zamanlayıcı bitti, uyarı), varsayılan kısık/kapalı; coucou 28 el yapımı ses ve değiştirilebilir ses klasörüyle kişilik kazanıyor.
- **Dokunma [Certain]:** `NSHapticFeedbackManager` (Force Touch trackpad): `.alignment` (yerine oturma), `.levelChange` (adım). NotchDrop "haptik kapatma" seçeneği eklemek zorunda kaldı → ölçülü + kapatılabilir.

### 8.6 Gönderdiğin Sapphire ekran görüntüsünün eleştirisi [Certain — görüntüden]

| Gözlem | Neden sorun | Nimbo karşılığı |
|---|---|---|
| ~1030 pt genişliğinde, notch'a göre **ortalanmamış** siyah bir levha | "Ada" değil "pano"; kamerayı sarmıyor (HIG'e aykırı) | Genişleme bile notch'a eş merkezli |
| Müzik │ hava │ takvim │ pano — **dört eşit ağırlıklı modül** | Görsel hiyerarşi yok; göz nereye bakacağını bilmiyor | Bir anda tek "kahraman" etkinlik + en fazla 2 ikincil |
| Üstte ~10 ikonluk sekme şeridi | İkon çorbası, keşfedilmesi zor | Bağlama göre değişen 3–5 eylem |
| **Notch'taki hava 16°, menü çubuğundaki 17°C** | Tutarsız veri güveni öldürür | Tek kaynak, aynı yuvarlama |
| Türkiye'de rüzgâr **mph** | Yerel ayara uymuyor | Sistem birimleri |
| "Cumhuriyet Bayramı (Y…", "Dynamic Island/Notch Ma…" | Kesilen metin | Kısaltma kuralları + yumuşak kayan yazı |
| 9–10 pt ikincil metin, renkli hafta günü harfleri | Okunurluk düşük, görsel gürültü | ≥ 11 pt, tek vurgu rengi |
| **Korunmaya değer:** büyük albüm kapağı, iri sıcaklık rakamı | Bir bakışta okunur | Büyük, cesur rakamlar (HIG) |

### 8.7 "Kimsede görülmemiş" için üç sanat yönü (konsept)

> Bunlar tasarım aşamasında görsel panolarla seçilecek yönler; şu an karar değil.

**A. "Nimbus" — ışık hâlesi dili (önerilen temel) [Guessing]**
"Nimbus" Latince hem *yağmur bulutu* hem de *bir figürün etrafındaki ışık hâlesi* demek; İspanyolca/Portekizce/İtalyancada "nimbo" aynı anlamları taşır. Konsept: **siyah obsidyen çekirdek + durumu anlatan ışık.** HIG'in "key line"ını bir görsel dile dönüştürüyoruz:
- Müzik: hâle albüm kapağının rengini alır; görselleştirici açıksa sesin genliğiyle, kapalıysa 4–6 saniyelik yavaş "nefes"le.
- Zamanlayıcı/Pomodoro: ilerleme, adanın çevresinde dolaşan bir **ışık kuyrukluyıldızı**; bitişte tek yumuşak darbe.
- Toplantı: başlangıca yaklaştıkça hâle nötrden kehribara ısınır; T−2 dk'da "Katıl" belirir.
- Odak: hâle sakin çivit mavisine söner; ada daha az konuşur.
- Şarj: yeşil ışık alt kenar boyunca dolar.
- Hava: hâlenin renk sıcaklığı gökyüzünü izler (şafak pembe, öğle beyaz, gün batımı turuncu, gece mavi).
- Kural: hiçbir zaman yanıp sönen kırmızı yok; tek kehribar darbe.

**B. "Obsidyen & Cam" — malzeme odaklı [Guessing]**
Siyah cam çekirdeğin kenarında duvar kâğıdını hafifçe kıran bir cam kenar; imlecin konumuna göre kayan speküler parıltı (paralaks ışık); ikinci etkinlik çekirdekten **cam damlası** gibi ayrılır (metaball). Daha "endüstriyel tasarım", daha az "oyunbaz".

**C. "Nimbo" karakteri — isteğe bağlı kişilik katmanı [Guessing]**
Notch'ta yaşayan minimal bir bulut/hâle varlığı: yağmur yağarken çiseler, müzikte salınır, gece uyur, odakta mırıldanır. coucou'nun Mochi'si kişiliğin viral gücünü kanıtlıyor (6.6k★). Risk: "sevimli" premium algıyı zayıflatabilir ve Mochi'nin kopyası gibi görünebilir → **varsayılan kapalı, ölçülü, kendi karakter dili.**

**Tavsiye [Guessing]:** A temel sistem, B malzeme işçiliği, C isteğe bağlı katman. Nimbo'yu ayıran şey tek tek efektler değil, **tüm etkinliklerin aynı ışık grameriyle konuşması** olur.

### 8.8 İmza anları — fikir havuzu (prototiplenecek)

1. **Uyanış (ilk açılış):** Işık, notch'un hatlarını çizerek tanıştırma yapar; izin istemez. [Guessing]
2. **Nefes:** Yalnızca müzik çalarken yavaş hâle nefesi; başka zaman sıfır animasyon (= sıfır CPU). [Guessing]
3. **Yutkunma:** Dosya bırakılınca ada onu metaball ile "yutar" + tek haptik vuruş. [Guessing]
4. **Mıknatıs:** Dosya sürüklenip ekranın üstüne yaklaşınca ada imlece doğru hafifçe uzanır (beklenti). [Guessing]
5. **Tomurcuk:** İkinci etkinlik çekirdekten ayrık baloncuk olarak tomurcuklanır; biri bitince geri emilir. [Guessing]
6. **Kuyrukluyıldız:** Zamanlayıcı ilerlemesi çevrede dolaşan ışık. [Guessing]
7. **Kapak geçişi:** Şarkı değişince kapak bulanıklaşarak morph olur, hâle rengi yeni kapağa akar. [Guessing]
8. **Gökyüzü:** Hava, hâlenin renk sıcaklığıyla anlatılır; sayıya bakmadan "dışarısı nasıl" hissi. [Guessing]
9. **Sessizlik:** Odak açılınca tüm hareket yavaşlar, sesler kapanır. [Guessing]
10. **Perde:** Ekran paylaşımı başlayınca hassas içerik kendini maskeler. [Likely — `sharingType` + algılama]
11. **Toplantı geri sayımı:** "5 dk" → "Katıl" tek düğme. [Likely]
12. **Ses palet ve haptik dili:** Her etkileşimin küçük, tutarlı bir dokunsal karşılığı. [Guessing]

---

## 9. Nimbo için önerilen ürün kapsamı (taslak — plan değil)

> Bir sonraki aşamada (sorular → yaklaşımlar → tasarım → spec → plan) netleşecek. Buradaki amaç tartışmaya bir başlangıç vermek.

### 9.1 v1.0 — Mac App Store çekirdeği [Likely]

**Ada motoru**
- Notch'a piksel düzeyinde oturan kapalı durum; hover-peek, tıkla-genişlet, kaydırma hareketleri (iki parmakla aç/kapat).
- Notch'suz ekranlarda (MacBook Neo, iMac, harici ekran) birinci sınıf **hap modu**; ekran seçimi, çoklu ekran.
- Tam ekranda otomatik geri çekilme, uygulama istisnaları; uyku/uyanma ve ekran değişikliklerine dayanıklılık.
- OLED MacBook Pro'da (Apple'ın adası varsa) algılayıp çakışmayan yerleşim. [Guessing — duyuruya bağlı]

**Etkinlikler**
- **Şimdi Çalıyor:** Apple Music (scripting-targets) + Spotify (geçici istisna, gerekçeli); kapak, ilerleme/scrub, ses düzeyi (uygulama içi), hâle rengi.
- **Zaman:** zamanlayıcı, kronometre, Pomodoro (tamamen yerel).
- **Takvim:** sıradaki etkinlik geri sayımı + toplantı linkine tek tıkla katıl; Hatırlatıcılar (EventKit).
- **Hava:** bir bakışta, WeatherKit, yerel birimler, önbellekli.
- **Raf:** sürükle-bırak, AirDrop/paylaş; "kopya mı, link mi" net; kalıcı.
- **Sistem sinyalleri:** şarj/düşük pil, kamera/mikrofon kullanımda, indirme bitti, Odak açık/kapalı.
- **Genişletilebilirlik:** App Intents / Shortcuts eylemleri ("Nimbo'da göster", "ilerlemeyi güncelle", "bitir") + URL şeması — kullanıcıların macOS 27'nin bildirim/ekran görüntüsü tetikleyicileriyle kendi etkinliklerini yaratması.

**Temel**
- Kademeli izin akışı; Türkçe + İngilizce; VoiceOver etiketleri, Hareketi Azalt, Şeffaflığı Azalt, Kontrastı Artır.
- Performans bütçesi (§10) ve ekran paylaşımında gizlenme.

### 9.2 v1.x — farklılaştırıcılar [Likely/Guessing]
- **Teleprompter** (kamera altında, sesle takip) — yaratıcılar için yüksek değer, MAS dostu.
- **Gerçek ses görselleştirici** (Core Audio tap, isteğe bağlı) — önce sandbox + inceleme spike'ı.
- **AI ajan etkinlikleri** (Claude Code/Codex hook'ları → localhost API) — geliştirici kitlesi için.
- **Safari uzantısı** ile tarayıcı medyası.
- **iPhone eşlikçisi:** Mac'te başlayan zamanlayıcı/etkinlik iPhone kilit ekranına ve Dynamic Island'ına devam eder (CloudKit + ActivityKit).
- **Kişilik katmanı** (§8.7-C), temalar/hâle paletleri, pano (ancak Spotlight'tan belirgin biçimde iyiyse).

### 9.3 Bilinçli olarak yapılmayacaklar (MAS sürümü) [Likely]
Evrensel Now Playing (MediaRemote), sistem HUD değiştirme, kilit ekranı widget'ları, bildirim yansıtma, başka uygulamaların pencerelerini yerleştirme, yüz tanıma ile kilit açma, borsa/spor/kripto, notch içinde terminal, Mac'i kontrol eden AI ajanı, genel AI sohbet kutusu.

### 9.4 İsteğe bağlı gelecek: "Nimbo Unbound" (Developer ID) [Guessing]
Talep kanıtlanırsa aynı kod tabanından, özel API'lere dayanan ek veri kaynaklarıyla (evrensel Now Playing, HUD, kilit ekranı) ayrı bir derleme. Bunun için v1'den itibaren her veri kaynağı bir protokol arkasında tasarlanmalı.

---

## 10. Performans ve sağlamlık ilkeleri

**Kanıt [Certain]:** OneNotch 1.1 müzik çalarken %26–40 CPU harcıyordu ve en pahalı şey notch'taki dalga animasyonuydu; optimizasyon sonrası %1'in altına indi (gerçek görselleştirici açıkken %6–9). Özellik ekledikçe 2.0'da boşta %7–10'a geri çıktı. Notchy'nin bulduğu iki "sıcak döngü": ana iş parçacığında 2 sn'de bir Accessibility isabet taraması ve senkron window-server çağrıları. Notchy'nin ölçümüne göre yerel uygulamalar boşta ~%0, "Electron tabanlı" dediği SuperIsland %0.46 — ancak GitHub'daki SuperIsland aslında Swift + JavaScriptCore eklentili; bu çelişki rakip karşılaştırmalarının neden ihtiyatla okunması gerektiğini gösteriyor [Likely].

**Önerilen bütçe [Guessing — ölçülerek kesinleşecek]:**

| Durum | Hedef |
|---|---|
| Kapalı, medya yok | ~%0 CPU, saniyede < 1 uyanma, Energy Impact ≈ 0 |
| Kapalı, müzik çalıyor | < %1 CPU |
| Açık + animasyon | Kısa süreli patlama; animasyon bitince sıfıra döner |
| Gerçek görselleştirici (isteğe bağlı) | ≤ %5 CPU |
| Bellek | < 120 MB, 8 saatte düz çizgi |

**İlkeler [Likely]:** Olay güdümlü (yoklama yok veya ana iş parçacığı dışında, seyrek); yalnızca görünürken render (Canvas/Metal boştayken duraklatılır); `TimelineView` yalnızca görünürken; Düşük Güç Modu'nda dekoratif hareket park edilir; kapatılan özellik zamanlayıcılarını gerçekten söker; ölçüm her zaman `/Applications`'taki Release derlemesiyle ve `powermetrics` + Instruments ile (debug derlemeleri 5–10 kat yanıltır); her sürümde otomatik performans regresyon kontrolü.

**Sağlamlık testi matrisi [Likely]:** 14"/16" MBP, 13"/15" Air, MacBook Neo (notch'suz), harici ekran(lar), kapak kapalı (clamshell), uyku/uyanma, ekran çözünürlüğü değişimi, Spaces, Mission Control, Stage Manager, tam ekran uygulamalar, ekran paylaşımı/kayıt, ikinci bir notch uygulaması çalışırken, menü çubuğunu otomatik gizle.

---

## 11. İş modeli ve fiyatlandırma

| Uygulama | Model |
|---|---|
| Notchy | $24.99 tek sefer, 7 gün deneme ("abonelik yok" ana pazarlama mesajı) |
| MacNotch | $22.99 tek sefer veya $3.99/ay; Setapp |
| Alcove | $13.99 tek sefer |
| DynamicLake Pro | $13.99 tek sefer |
| NotchNook | $25 tek sefer veya $3/ay (kriz öncesi) |
| Perch (MAS) | $3.99/ay, $14.99/yıl, $24.99/$49.99 ömür boyu |
| NotchOS (MAS) | $3.99 / $29.99 |
| Sapphire | Ücretsiz + $15.99–$30.99/ay |
| Boring Notch, Atoll, DynamicNotch, coucou | Ücretsiz (bağış) |

**Gözlem [Likely]:** Ücretli pazarın tatlı noktası **$13.99–$24.99 tek sefer**; kullanıcılar notch uygulaması için aboneliği sevmiyor (sen de Sapphire'da bundan rahatsızsın). Güçlü ücretsiz alternatifler (Boring Notch, Atoll) "ücretsiz çekirdek" beklentisi yaratıyor.

**Tavsiye [Likely]:** Cömert ücretsiz çekirdek + tek seferlik **"Nimbo Plus"** kilidi (ABD'de ~$14.99–$19.99 bandı, Türkiye için bölgesel fiyat), Aile Paylaşımı açık, notch içinde asla upsell yok (yalnızca ayarlar ekranında). Abonelik yalnızca gerçek sunucu maliyeti doğuran bir özellik (ör. AI) eklenirse ve ayrı tutularak. Apple Small Business Program ile komisyon %15 [Certain].

---

## 12. Riskler ve azaltma

| Risk | Olasılık / Etki | Azaltma |
|---|---|---|
| Apple'ın kendi Dynamic Island'ı (OLED MBP) ve olası Mac Live Activities API'si | Orta / Yüksek | Taklit değil kendine özgü dil; Apple adası olan cihazlarda algıla-uyum sağla; Apple API açarsa ilk benimseyen ol |
| MAS inceleme reddi (Spotify istisnası, ses tap'i) | Orta / Orta | Özellik bayrakları ve zarif geri dönüş; App Review'a önceden danışma; ilk sürümü en güvenli kapsamla gönder |
| Ad/marka çakışması ("Nimbo") | Yüksek / Yüksek | Hemen TÜRKPATENT/EUIPO/USPTO taraması; mağaza adı varyantı; alan adı/sosyal hesap kontrolü |
| Özellik şişkinliği | Yüksek / Yüksek | "Az ama kusursuz" ilkesi, yazılı "yapmayacaklarımız" listesi, her özellik için performans bütçesi |
| Pil/CPU itibarı | Orta / Yüksek | §10 bütçesi + otomatik ölçüm; kamuya açık ölçüm sayfası |
| macOS güncellemelerinde AppleScript yollarının kırılması (BN #779, Perch) | Orta / Orta | Veri kaynakları soyutlaması, her Haziran beta testi, zarif hata durumu |
| GPL/AGPL kod bulaşması | Düşük (dikkatle) / Yüksek | Temiz oda geliştirme; yalnızca MIT kaynaklara atıfla bakmak |
| Repo public olursa klonlanma | Orta / Orta | Repo private kalsın veya lisans kararı (kapalı/kaynak-görünür) bilinçli verilsin |
| Şarkı sözü telif riski | Orta / Orta | v1 dışında tut; hukuki görüş |
| WeatherKit maliyeti ölçeklenince | Orta / Düşük-Orta | Önbellek, yalnızca görünürken güncelleme, kota izleme |
| Tek geliştirici bağımlılığı (NotchNook, Alcove dersleri) | Orta / Yüksek | Dokümantasyon, CI, otomatik sürüm, MAS'ın lisans altyapısı |

---

## 13. Karar noktaları (bir sonraki aşama için)

1. **Dağıtım:** v1 yalnızca MAS mı (önerim), yoksa en baştan MAS + Developer ID ikili dağıtım mı?
2. **Minimum macOS:** 26+ (Liquid Glass API'leri, daha az görsel QA; önerim) mi, 15+ (daha geniş kitle) mi?
3. **İş modeli:** Ücretsiz çekirdek + tek seferlik Plus (önerim) mi, peşin ücretli mi, abonelik mi?
4. **İsim:** Mağaza adı varyantı ve marka taraması; "Nimbo" markası korunacak mı?
5. **Sanat yönü:** A (Nimbus/hâle), B (Obsidyen & Cam), C (karakter) — hangisi/hangileri?
6. **Hedef kitle önceliği:** Genel kullanıcı mı, yaratıcılar (teleprompter) mı, geliştiriciler (AI ajan) mı? Kapsamı en çok bu belirler.
7. **v1 kapsam kesimi:** §9.1 listesinden ne çıkar, ne girer?
8. **iPhone eşlikçisi** v1.x'te mi, daha sonra mı?
9. **Repo görünürlüğü ve lisans:** private + kapalı kaynak mı, açık çekirdek mi?
10. **Dil desteği:** Lansmanda TR + EN yeterli mi?

---

## 14. Kaynaklar

**Kullanıcının verdiği kaynaklar**
- Sapphire — https://sapphire-app.tech/ ve fiyatlar https://sapphire-app.tech/subscribe
- MacNotch — https://macnotch.io/ ve karşılaştırma https://macnotch.io/compare/best-mac-notch-apps
- Notchy — https://notchy.dev/ , https://notchy.dev/best-mac-notch-apps/ , https://notchy.dev/notchy-cpu-battery-usage/
- DynamicNotch — https://dynamicnotch.evgeniy-petrukovich.workers.dev/ , https://github.com/jackson-storm/DynamicNotch

**Açık kaynak repolar (kod incelendi)**
- https://github.com/TheBoredTeam/boring.notch · https://github.com/Ebullioscopic/Atoll · https://github.com/Lakr233/NotchDrop · https://github.com/akalikbergenov/cyclop · https://github.com/mrkai77/DynamicNotchKit · https://github.com/monuk7735/mew-notch
- README düzeyinde: https://github.com/Louis-CFM/coucou · https://github.com/shobhit99/SuperIsland · https://github.com/wxtsky/CodeIsland · https://github.com/MioMioOS/MioIsland · https://github.com/BySergiMM/OmniMac · https://github.com/ungive/mediaremote-adapter
- GitHub konu sayfaları: https://github.com/topics/notch · https://github.com/topics/dynamic-island · https://github.com/topics/macbook-notch · https://github.com/topics/notch-app
- Şikâyetler: https://github.com/TheBoredTeam/boring.notch/issues · https://github.com/Ebullioscopic/Atoll/issues

**Ticari ve MAS**
- Alcove https://tryalcove.com/ · DynamicLake https://www.dynamiclake.com/
- Perch https://apps.apple.com/us/app/dynamic-notch-island-perch/id6742724228 · NotchOS https://apps.apple.com/us/app/dynamic-notch-island-notchos/id6760346112 · NotchDrop https://apps.apple.com/us/app/notchdrop/id6529528324 · NIMBO https://apps.apple.com/us/app/nimbo/id6818288098
- NotchNook krizi: https://macmagazine.com.br/post/2026/09/16/crise-na-lo-cafe-deixa-notchnook-fora-do-ar-e-usuarios-sem-reembolso/
- Performans: https://www.tryonenotch.com/blog/do-mac-notch-apps-drain-battery
- Alcove incelemesi: https://www.macstories.net/reviews/alcove-an-excellent-notch-utility-with-beautiful-animations/

**Apple ve platform**
- HIG Live Activities: https://developer.apple.com/design/human-interface-guidelines/live-activities
- SwiftUI GraphicsContext.Filter: https://developer.apple.com/documentation/swiftui/graphicscontext/filter
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- DTS (Accessibility vs Input Monitoring): https://developer.apple.com/forums/thread/780626
- MAS HUD emsali: https://github.com/cbusillo/media-control-relay/issues/122
- WeatherKit: https://developer.apple.com/weatherkit/get-started/
- Spotify API erişimi: https://developer.spotify.com/blog/2025-04-15-updating-the-criteria-for-web-api-extended-access
- macOS 27 özellikleri: https://www.macrumors.com/2026/09/17/new-features-changes-macos-27/
- 28 Ekim lansmanı: https://www.macrumors.com/2026/10/19/apple-october-28-product-launch/
- M6 MBP'de Dynamic Island haberi: https://9to5mac.com/2026/02/24/new-m6-macbook-pro-details-revealed-including-dynamic-island-touch-more/
- MacBook Neo: https://en.wikipedia.org/wiki/MacBook_Neo
- Metaball/Metal morph: https://ikyle.me/blog/2026/creating-cool-ui-shape-morphing-directly-with-metal

---

## Ek A — Kod inceleme kanıtları (özet)

| Repo (commit) | Sandbox | Özel API / sistem düzeyi | Dikkat çeken |
|---|---|---|---|
| boring.notch (23e7705, 18 Eki 2026; 123 Swift dosyası, ~19.6k satır) | Ana uygulama ✅ (+ Spotify/Music için `temporary-exception.apple-events`), **XPC yardımcısı ❌** (Accessibility, ekran/klavye parlaklığı) | CGSSpace (`@_silgen_name`), SkyLight `dlopen` (kilit ekranında görünme), MediaRemote fonksiyon işaretçileri + mediaremote-adapter | Görselleştirici **sahte** (4 çubuk, 0.3 sn'de bir `random(0.35…1.0)`); pencere `NSPanel` seviye `.mainMenu + 3`; `NotchShape` kuadratik Bézier |
| Atoll (166a876, 28 Eki 2026; 391 Swift dosyası, **~121k satır**, test/örnekler dahil) | ❌ (+ `disable-library-validation`) | SkyLight (14 dosya), CGS, DisplayServices, CoreBrightness, MediaRemote, IOReport + SMC, CGEventTap, OSDUIHelper'ı `launchctl bootout/bootstrap` ile yönetme | **Gerçek** görselleştirici: `CATapDescription` + `AudioHardwareCreateProcessTap` + özel aggregate cihaz + vDSP; uygulama başına ses de tap ile |
| NotchDrop (e70b3d7, May 2026) — **MAS'ta** | ✅ `ENABLE_APP_SANDBOX = YES`, hardened runtime | yok | Pencere seviyesi `.statusBar + 8`; notch ölçüsü `safeAreaInsets` + `auxiliaryTop*Area`; hover için global fare izleme |
| cyclop (6 Eki 2026) — "izin gerektirmez" | ❌ | MediaRemote yardımcısı `/usr/bin/perl` içinde; AppleScript yedek; medya tuşu gönderme | "İzin yok" iddiası pazarlama |
| DynamicNotch (README + commit, 24 Nis 2026) | ❌ | mediaremote-adapter (`/usr/bin/perl`), Accessibility (HUD), Screen Recording (görselleştirici) | GPL-3.0, 38+ dil |
| mew-notch | ❌ | CGS/SkyLight/MediaRemote, medya tuşu yöneticisi | GPL-3.0 |
| DynamicNotchKit | — (kütüphane) | — | **MIT**; notch şekli ve geçişleri için referans |

**Sonuç [Certain]:** "Her uygulamadan Now Playing" sunan dört açık kaynak uygulamanın dördü de macOS 15.4 sonrası MediaRemote kilidini `/usr/bin/perl` hilesiyle aşıyor; hiçbiri MAS'a uygun değil. MAS'ta onaylanmış notch uygulamaları (NotchDrop, Perch, NotchOS, NotchBox, Notchmeister) yalnızca genel API'lerle yetiniyor.

*Ham notlar, tüm ara bulgular ve ek kaynaklar: [`notes/2026-10-28-ham-arastirma-notlari.md`](notes/2026-10-28-ham-arastirma-notlari.md).*
