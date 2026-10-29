# Lunula otomasyonu

Lunula'ya terminalden, betiklerden, Kestirmeler'den ve AI ajan kancalarından **ağ izni olmadan** etkinlik gösterebilirsin. İki yol var: `lunula://` URL'leri ve App Intents (Kestirmeler).

## Sınırlar

- Aynı anda en çok **3** özel etkinlik; dördüncüsü en eskisini çıkarır.
- Bir etkinlik en çok **8 saat** yaşar (`duration` daha kısaysa o kadar).
- **10 saniyede 10 istek**; fazlası sessizce düşürülür (Konsol'da `com.kutluhangul.lunula` / `url`).
- `id` ≤ 64 karakter (harf, rakam, `-`, `_`, `.`), `title` ≤ 80, `subtitle` ≤ 120 karakter.

## URL başvurusu

`open -g` uygulamayı öne getirmeden çalıştırır.

| Komut | Parametreler |
|---|---|
| `lunula://activity/show` | `id` (zorunlu), `title` (zorunlu), `subtitle`, `symbol` (SF Symbol adı; geçersizse `sparkle`), `accent` (hex, ör. `7C5CFF`), `progress` (0–1), `duration` (saniye) |
| `lunula://activity/end` | `id` |
| `lunula://timer/start` | `minutes` (1–600) |
| `lunula://island/toggle` | — |

Aynı `id` ile tekrar `show` göndermek etkinliği günceller (ör. ilerlemeyi artırır).

```bash
# Etkinlik göster, ilerlet, bitir
open -g "lunula://activity/show?id=build&title=Derleme&subtitle=Lunula%20%C2%B7%20Release&symbol=hammer&accent=7C5CFF&progress=0.3"
open -g "lunula://activity/show?id=build&title=Derleme&symbol=hammer&progress=0.8"
open -g "lunula://activity/end?id=build"

# 25 dakikalık zamanlayıcı
open -g "lunula://timer/start?minutes=25"

# Uzun bir komutun süresince adada göster
lunula_run() {
  open -g "lunula://activity/show?id=job&title=$(printf %s "$1" | jq -sRr @uri)&symbol=terminal"
  "$@"; local rc=$?
  open -g "lunula://activity/end?id=job"
  return $rc
}
```

## Claude Code kancası

`.claude/settings.json` (proje ya da kullanıcı düzeyinde):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "open -g 'lunula://activity/show?id=claude&title=Claude%20%C3%A7al%C4%B1%C5%9F%C4%B1yor&symbol=sparkles&accent=D97757'" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "open -g 'lunula://activity/end?id=claude'" } ] }
    ]
  }
}
```

Claude bir isteği işlerken adada turuncu bir kıvılcım görünür; yanıt bitince kaybolur. Aynı kalıp `PreToolUse` ile belirli araçlar için de kullanılabilir.

## Kestirmeler (App Intents)

Kestirmeler uygulamasında "Lunula" altında:

| Eylem | Alanlar |
|---|---|
| Etkinlik göster | Kimlik, Başlık, Alt başlık, SF Sembolü, Vurgu (hex), İlerleme (0–1), Süre (saniye) |
| Etkinliği güncelle | Aynı alanlar; kimlik yoksa hata |
| Etkinliği bitir | Kimlik |
| Zamanlayıcı başlat | Dakika (1–600) |
| Adayı aç/kapat | — |

Tüm eylemler arka planda çalışır; Lunula öne gelmez. Siri ifadeleri: "Show activity in Lunula", "Start a timer in Lunula", "Toggle Lunula" (Türkçe karşılıkları da tanımlı).
