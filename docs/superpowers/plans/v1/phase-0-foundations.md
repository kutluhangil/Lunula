# Faz 0 — Temeller (Integrator)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec: [../../specs/2026-10-28-v1-design.md](../../specs/2026-10-28-v1-design.md) §3
> Bu fazın sonunda: boş ama sandbox'lı, imzalanabilir bir ajan uygulaması derlenir; 4 paket test edilir; CI her PR'da mimari kuralları mekanik olarak denetler.

---

### T0.1 Depo iskeleti (XcodeGen + 4 paket + boş ajan uygulaması)

**Files:**
- Create: `.gitignore`, `project.yml`, `Config/Base.xcconfig`, `Config/Signing.xcconfig.example`
- Create: `App/Sources/main.swift`, `App/Sources/AppDelegate.swift`, `App/Sources/CompositionRoot.swift`
- Create: `App/Resources/Assets.xcassets/Contents.json`, `App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`, `App/Resources/Localizable.xcstrings`, `App/Resources/InfoPlist.xcstrings`
- Create: `App/Tests/AppBundleTests.swift`
- Create (her `P` ∈ `IslandCore, IslandDesign, IslandServices, IslandFeatures`): `Packages/P/Package.swift`, `Packages/P/Sources/P/PModule.swift`, `Packages/P/Tests/PTests/PackageSmokeTests.swift`
- Create: `Packages/IslandCore/Sources/IslandCoreTestSupport/TestSupport.swift`
- Create: `Scripts/bootstrap.sh`, `Scripts/test-all.sh`
- Generated + committed (XcodeGen çıktısı): `App/Info.plist`, `App/Lunula.entitlements`
- Generated + **ignored**: `Lunula.xcodeproj/`

**Interfaces:**
- Produces: `IslandCoreModule.version`, `IslandDesignModule.version`, `IslandServicesModule.version`, `IslandFeaturesModule.version` (`"0.1.0"`); kütüphane ürünleri `IslandCore`, `IslandCoreTestSupport`, `IslandDesign`, `IslandServices`, `IslandFeatures`; `@MainActor final class CompositionRoot { static let shared; func start() }`; Xcode şeması `Lunula` (uygulama) + `LunulaTests` (uygulama barındırmalı test paketi).

- [ ] **Step 1: Paket duman testlerini yaz** (her paket için aynı kalıp)

```swift
// Packages/IslandCore/Tests/IslandCoreTests/PackageSmokeTests.swift
import Testing
@testable import IslandCore

@Suite struct PackageSmokeTests {
    @Test func moduleVersionIsSet() {
        #expect(IslandCoreModule.version == "0.1.0")
    }
}
```

```swift
// App/Tests/AppBundleTests.swift
import Testing
import Foundation

@Suite struct AppBundleTests {
    @Test func appIsAgentWithoutDockIcon() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
    }
    @Test func urlSchemeIsRegistered() throws {
        let types = try #require(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes.contains("lunula"))
    }
    @Test func everyUsageDescriptionIsPresent() {
        for key in ["NSAppleEventsUsageDescription", "NSCalendarsFullAccessUsageDescription",
                    "NSLocationUsageDescription", "NSLocationWhenInUseUsageDescription"] {
            #expect((Bundle.main.object(forInfoDictionaryKey: key) as? String)?.isEmpty == false, "\(key)")
        }
    }
}
```

- [ ] **Step 2: Çalıştır, başarısız olduğunu gör**

Run: `swift test --package-path Packages/IslandCore`
Expected: FAIL — `Package.swift` yok ("Could not find Package.swift").

- [ ] **Step 3: Paketleri oluştur**

Her `Package.swift`: `// swift-tools-version: 6.2`, `platforms: [.macOS("26.0")]`, Swift 6 dil modu (araç sürümü 6.x varsayılanı). Bağımlılıklar spec §3.1'deki kurallara birebir uyar:

| Paket | Hedefler | Bağımlılık |
|---|---|---|
| IslandCore | `IslandCore`, `IslandCoreTestSupport` (→ IslandCore), test: `IslandCoreTests` (→ ikisi) | yok |
| IslandDesign | `IslandDesign`, test | `../IslandCore` |
| IslandServices | `IslandServices`, test | `../IslandCore` (testler `IslandCoreTestSupport` da kullanır) |
| IslandFeatures | `IslandFeatures`, test | `../IslandCore`, `../IslandDesign` (testler `IslandCoreTestSupport`) |

`PModule.swift`: `public enum <P>Module { public static let version = "0.1.0" }`. `TestSupport.swift` şimdilik boş bir `public enum IslandCoreTestSupport {}` (T1.1 doldurur).

- [ ] **Step 4: `project.yml` ve yapılandırmayı yaz** (aşağıdaki değerler spec'ten sabitlenmiştir; anahtar adları XcodeGen 2.46 sözdizimi)

```yaml
name: Lunula
options:
  bundleIdPrefix: com.kutluhangul
  deploymentTarget: { macOS: "26.0" }
  createIntermediateGroups: true
  developmentLanguage: en
configFiles: { Debug: Config/Base.xcconfig, Release: Config/Base.xcconfig }
settings:
  base:
    SWIFT_VERSION: "6.0"
    ENABLE_HARDENED_RUNTIME: YES
    MARKETING_VERSION: 0.1.0
    CURRENT_PROJECT_VERSION: 1
    LOCALIZATION_PREFERS_STRING_CATALOGS: YES
    SWIFT_EMIT_LOC_STRINGS: YES
    DEAD_CODE_STRIPPING: YES
packages:
  IslandCore: { path: Packages/IslandCore }
  IslandDesign: { path: Packages/IslandDesign }
  IslandServices: { path: Packages/IslandServices }
  IslandFeatures: { path: Packages/IslandFeatures }
  KeyboardShortcuts: { url: https://github.com/sindresorhus/KeyboardShortcuts, from: 3.1.0 }
targets:
  Lunula:
    type: application
    platform: macOS
    sources: [App/Sources, App/Resources]
    dependencies:
      - package: IslandCore
      - package: IslandDesign
      - package: IslandServices
      - package: IslandFeatures
      - package: KeyboardShortcuts
    settings:
      base:
        PRODUCT_NAME: Lunula
        PRODUCT_BUNDLE_IDENTIFIER: com.kutluhangul.lunula
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) LUNULA_SPOTIFY"
    info:
      path: App/Info.plist
      properties:
        LSUIElement: true
        LSApplicationCategoryType: public.app-category.productivity
        CFBundleDisplayName: Lunula
        NSHumanReadableCopyright: "© 2026 Kutluhan Gül"
        CFBundleURLTypes:
          - { CFBundleURLName: com.kutluhangul.lunula, CFBundleURLSchemes: [lunula] }
        NSAppleEventsUsageDescription: "Lunula shows what's playing in Music and Spotify and lets you control playback."
        NSCalendarsFullAccessUsageDescription: "Lunula shows your next event and a Join button for meetings."
        NSLocationUsageDescription: "Lunula uses your approximate location to show local weather."
        NSLocationWhenInUseUsageDescription: "Lunula uses your approximate location to show local weather."
    entitlements:
      path: App/Lunula.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.automation.apple-events: true
        com.apple.security.scripting-targets:
          com.apple.Music: [com.apple.Music.playback, com.apple.Music.playerInfo]
        com.apple.security.temporary-exception.apple-events: [com.spotify.client]
        com.apple.security.personal-information.calendars: true
        com.apple.security.personal-information.location: true
        com.apple.security.files.downloads.read-only: true
        com.apple.security.files.user-selected.read-write: true
        com.apple.security.files.bookmarks.app-scope: true
        com.apple.security.network.client: true
  LunulaTests:
    type: bundle.unit-test
    platform: macOS
    sources: [App/Tests]
    dependencies:
      - target: Lunula
      - package: IslandCore
        product: IslandCoreTestSupport
schemes:
  Lunula:
    build: { targets: { Lunula: all, LunulaTests: [test] } }
    test: { targets: [LunulaTests], gatherCoverageData: true }
```

- `Config/Base.xcconfig`: `CODE_SIGN_IDENTITY = -` ve `CODE_SIGN_STYLE = Manual` (varsayılan: yerel ad-hoc imza), son satırda `#include? "Signing.xcconfig"`.
- `Config/Signing.xcconfig.example`: yorum satırlarıyla `DEVELOPMENT_TEAM = `, `CODE_SIGN_STYLE = Automatic`, `CODE_SIGN_IDENTITY = Apple Development`. Açıklama: kullanıcının **ücretli Apple Developer** Team ID'si buraya yazılır (dosya git dışıdır, Team ID asla commit'lenmez); ad-hoc imzada her derlemede imza değiştiği için Otomasyon/Takvim izinleri her seferinde yeniden sorulur.
- `InfoPlist.xcstrings`: dört kullanım metninin Türkçe karşılıkları (`tr`, durum `translated`).
- `Localizable.xcstrings`: tek anahtar `app.name` (`en`: "Lunula", `tr`: "Lunula").
- `.gitignore`: `Lunula.xcodeproj/`, `build/`, `DerivedData/`, `.build/`, `.swiftpm/`, `*.xcuserstate`, `xcuserdata/`, `Config/Signing.xcconfig`, `.DS_Store`.
- `main.swift`: `NSApplication.shared` + `AppDelegate` + `run()`. `AppDelegate` `@MainActor`, `applicationDidFinishLaunching` → `CompositionRoot.shared.start()`; `start()` şimdilik yalnızca `Logger(subsystem: "com.kutluhangul.lunula", category: "app").info("start")`.
- `Scripts/bootstrap.sh` (`set -euo pipefail`): xcodegen yoksa `brew install xcodegen`; `Config/Signing.xcconfig` yoksa örnekten kopyala; `xcodegen generate`.
- `Scripts/test-all.sh` (`set -euo pipefail`): 4 paket için `swift test --package-path Packages/$p`, ardından `xcodebuild test -project Lunula.xcodeproj -scheme Lunula -destination 'platform=macOS' -quiet`.

- [ ] **Step 5: Çalıştır, geçtiğini gör**

Run: `Scripts/bootstrap.sh && Scripts/test-all.sh`
Expected: 4 paket `✔ Test run with 1 test passed`; `xcodebuild` `** TEST SUCCEEDED **` (3 test).

- [ ] **Step 6: Uygulamanın gerçekten açıldığını doğrula**

Run: `xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Debug -derivedDataPath build build && open build/Build/Products/Debug/Lunula.app && sleep 2 && pgrep -x Lunula`
Expected: bir PID yazdırılır; Dock'ta simge yok; Konsol'da `start` günlüğü. Sonra `pkill -x Lunula`.

- [ ] **Step 7: Commit**

```bash
git add .gitignore project.yml Config App Packages Scripts
git commit -m "chore: scaffold XcodeGen project, four local packages and sandboxed agent app"
```

---

### T0.2 CI, biçim ve mimari bekçileri

**Files:**
- Create: `.github/workflows/ci.yml`, `.swift-format`
- Create: `Scripts/lint.sh`, `Scripts/check-architecture.sh`, `Scripts/check-entitlements.sh`

**Interfaces:**
- Consumes: T0.1'in `Scripts/bootstrap.sh`, `Scripts/test-all.sh`, `Lunula` şeması.
- Produces: her PR'da çalışan iki iş: `core-linux` (IslandCore'un yalnızca Foundation kullandığını Linux'ta derleyerek kanıtlar) ve `macos` (lint + mimari + testler + Release ad-hoc derleme + yetki denetimi).

- [ ] **Step 1: Bekçiyi bilerek kıracak bir ihlal dosyası oluştur**

```bash
printf 'import AppKit\n' > Packages/IslandCore/Sources/IslandCore/_Violation.swift
printf 'let x = dlopen(nil, 0)\n' > Packages/IslandServices/Sources/IslandServices/_Violation.swift
```

- [ ] **Step 2: Bekçi henüz yokken çalıştır**

Run: `Scripts/check-architecture.sh; echo "exit=$?"`
Expected: `No such file or directory`, `exit=127`.

- [ ] **Step 3: `Scripts/check-architecture.sh` yaz**

Kurallar (her ihlal `dosya:satır: kural` olarak yazdırılır; herhangi biri varsa `exit 1`):
1. `Packages/IslandCore/Sources/**`: `import` satırları yalnızca `Foundation` ve `Observation` olabilir.
2. `Packages/IslandFeatures/Sources/**`: `import IslandServices` yasak.
3. `Packages/IslandServices/Sources/**`: `import SwiftUI` yasak.
4. `App/` ve `Packages/*/Sources/` altında yasak semboller (regex, `grep -nE`): `MediaRemote|SkyLight|\bSLS[A-Z]|\bCGS[A-Z][A-Za-z]*\(|DisplayServices|CoreBrightness|\bdlopen\b|\bdlsym\b|AXIsProcessTrusted|AXUIElement|CGEventPost|CGEvent\.post|\bNSTask\b|Process\(\)|/usr/bin/|sharingType`.
5. `Packages/*/Sources/**` ve `App/Sources/**`: `DispatchQueue.main.sync` yasak.

- [ ] **Step 4: Bekçinin ihlali yakaladığını gör, sonra ihlal dosyalarını sil**

Run: `Scripts/check-architecture.sh; echo "exit=$?"`
Expected: iki satır (`_Violation.swift:1: IslandCore may only import Foundation/Observation`, `_Violation.swift:1: forbidden symbol dlopen`), `exit=1`.
Run: `rm Packages/*/Sources/*/_Violation.swift && Scripts/check-architecture.sh; echo "exit=$?"`
Expected: `architecture OK`, `exit=0`.

- [ ] **Step 5: Lint, yetki denetimi ve CI'ı yaz**

- `.swift-format`: `{"version":1,"lineLength":120,"indentation":{"spaces":4},"respectsExistingLineBreaks":true}`.
- `Scripts/lint.sh`: `swift format lint --strict --recursive App Packages` (araç Xcode 26 araç zincirinde gelir; ek bağımlılık yok).
- `Scripts/check-entitlements.sh <App yolu>`: `codesign -d --entitlements - --xml "$1"` çıktısını `plutil -extract com.apple.security.app-sandbox raw -` ile okur → `true` değilse çık 1; `codesign -dv "$1" 2>&1 | grep -q 'flags=.*runtime'` değilse çık 1 (Hardened Runtime).
- `.github/workflows/ci.yml` (`on: [push, pull_request]`, `concurrency` ile eski çalıştırmaları iptal):
  - `core-linux`: `runs-on: ubuntu-latest`, `container: swift:6.2`, adım: `swift test --package-path Packages/IslandCore`.
  - `macos`: `runs-on: macos-26` (varsayılan Xcode 26.6), adımlar sırayla: checkout → `brew install xcodegen` → `Scripts/bootstrap.sh` → `git diff --exit-code App/Info.plist App/Lunula.entitlements` (üretilen dosyalar commit'lenmiş olmalı) → `Scripts/lint.sh` → `Scripts/check-architecture.sh` → `Scripts/test-all.sh` → `xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Release -derivedDataPath build CODE_SIGN_IDENTITY=- build` → `Scripts/check-entitlements.sh build/Build/Products/Release/Lunula.app`.

- [ ] **Step 6: Yerelde tüm bekçileri çalıştır**

Run: `Scripts/lint.sh && Scripts/check-architecture.sh && Scripts/test-all.sh && xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Release -derivedDataPath build CODE_SIGN_IDENTITY=- build -quiet && Scripts/check-entitlements.sh build/Build/Products/Release/Lunula.app`
Expected: hata yok; son satır `entitlements OK (sandbox, hardened runtime)`.

- [ ] **Step 7: Commit ve push; CI'ın yeşil olduğunu gör**

```bash
git add .github .swift-format Scripts
git commit -m "ci: add lint, architecture guards, entitlement check and Linux core job"
git push
```
Expected: GitHub Actions'ta `core-linux` ve `macos` işleri yeşil.
