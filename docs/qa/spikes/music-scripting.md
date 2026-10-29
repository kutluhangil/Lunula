# Spike: Apple Music betik erişimi (T5.2)

Durum: **bekliyor, kilitlenmedi.** Kod plandaki betik ve ayrıştırma kurallarıyla yazıldı (`MusicScripts`, `MusicScriptParser`). Aşağıdaki üç adımı cihazda çalıştır, çıktıları tablolara yaz; bir şey beklenenden farklıysa kural güncellenir.

Not: 2. adım Terminal için bir kez "Otomasyon" izni sorar (Terminal → Music). Bu, Lunula'nın izni değildir.

## 1. Erişim grupları hâlâ aynı mı

```bash
sdef /System/Applications/Music.app | grep -o 'access-group identifier="[^"]*"' | sort -u
```

Beklenen: `com.apple.Music.playback` ve `com.apple.Music.playerInfo` (Lunula.entitlements'taki `com.apple.security.scripting-targets` bu adları kullanıyor).

| macOS | Çıktı | Aynı mı |
|---|---|---|
| | | |

## 2. Sorgu betiği

Music'te bir parça çalarken:

```bash
osascript -e 'with timeout of 1 second
  tell application id "com.apple.Music"
    if player state is stopped then return {"stopped"}
    set t to current track
    return {player state as text, name of t, artist of t, album of t, duration of t, player position, persistent ID of t}
  end tell
end timeout'
```

| Durum | Çıktı | 7 öğe mi | Ad boş mu |
|---|---|---|---|
| Kitaplıktaki parça | | | |
| Apple Music akış parçası | | | |
| Radyo | | | |
| Duraklatılmış | | | |

## 3. `com.apple.Music.playerInfo` bildirimi

Kod `userInfo`'ya güvenmez; bildirim yalnızca "yeniden sorgula" tetikleyicisidir. Belge için anahtarları görmek istersen:

```bash
swift -e 'import Foundation
DistributedNotificationCenter.default().addObserver(forName: .init("com.apple.Music.playerInfo"), object: nil, queue: .main) { print($0.userInfo?.keys.map { "\($0)" }.sorted() ?? []) }
RunLoop.main.run(until: Date().addingTimeInterval(30))'
```

| Olay | userInfo anahtarları |
|---|---|
| Parça değişti | |
| Duraklat / oynat | |
