# Sürüm (Developer ID + noter onayı)

Lunula, GitHub'da Developer ID ile imzalanmış, Apple noter onaylı ve zımbalanmış (stapled) bir DMG olarak yayımlanır. Mac App Store sonra. Sparkle (otomatik güncelleme) bu sürümde yok (backlog).

## Bir kez yapılacaklar (Account Holder)

1. **Developer ID Application sertifikası** — developer.apple.com › Certificates › "+" › *Developer ID Application* (yalnızca Account Holder oluşturabilir). Bu Mac'te oluşturduğun CSR ile indir, çift tıklayıp Anahtar Zinciri'ne ekle.
2. **.p12 dışa aktar** — Anahtar Zinciri › Sertifikalarım › "Developer ID Application: …" › sağ tık › Dışa Aktar (.p12), güçlü bir parola ver.
3. **App Store Connect API anahtarı** — App Store Connect › Users and Access › Integrations › App Store Connect API › "+" (rol: *Developer*). `AuthKey_<KEYID>.p8` dosyasını indir (bir kez inebilir), Key ID ve Issuer ID'yi not et.
4. **GitHub Secrets** (repo › Settings › Secrets and variables › Actions):

| Secret | Değer |
|---|---|
| `DEVELOPER_ID_CERT_P12` | `base64 -i cert.p12 \| pbcopy` çıktısı |
| `DEVELOPER_ID_CERT_PASSWORD` | .p12 parolası |
| `APPSTORE_CONNECT_KEY_ID` | Key ID |
| `APPSTORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APPSTORE_CONNECT_KEY_P8` | `.p8` dosyasının metni |
| `DEVELOPMENT_TEAM` | 10 haneli Team ID |

Biri eksikse `release.yml` **başarısız olur**; imzasız sürüm yayımlanmaz.

## Yerelde deneme

```bash
xcrun notarytool store-credentials lunula-notary --key AuthKey_<KEYID>.p8 --key-id <KEYID> --issuer <ISSUER>
Scripts/release/build-dmg.sh --sign "Developer ID Application: <Ad> (<TEAMID>)"
NOTARY_PROFILE=lunula-notary Scripts/release/notarize.sh build/Lunula-0.1.0.dmg
```

`spctl` çıktısı `source=Notarized Developer ID` demeli.

## Sürüm çıkarma

1. `project.yml` içinde `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`'ı artır, `CHANGELOG.md`'yi güncelle, commit + push.
2. `git tag v0.1.0-rc1 && git push origin v0.1.0-rc1` → `Release` iş akışı DMG'yi imzalar, noter onayına gönderir, zımbalar ve GitHub Release'e yükler.
3. İndirilen DMG'yi temiz bir Mac'te aç; Gatekeeper uyarısı çıkmamalı.

## Bu belgenin durumu

- 2026-10-29: betikler, iş akışı ve belge hazır; yerel imzasız DMG üretimi denendi (aşağıda). İmzalı/noter onaylı deneme ve `v0.1.0-rc1` etiketi kullanıcıda (sertifika ve sırlar gerekli).

### Yerel imzasız deneme (2026-10-29, Mac mini, macOS 27.0.1)

```
$ Scripts/release/build-dmg.sh
build/Lunula-0.1.0.dmg            (3.8 MB, hdiutil verify: OK)
$ spctl -a -vv -t open --context context:primary-signature build/Lunula-0.1.0.dmg
build/Lunula-0.1.0.dmg: rejected
source=no usable signature        (beklenen: imzasız; imzalı akış --sign ile)
```
