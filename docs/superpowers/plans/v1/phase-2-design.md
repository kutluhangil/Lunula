# Faz 2 — Tasarım sistemi (`IslandDesign`, Design Engineer)

> Ana plan: [../2026-10-28-v1-plan.md](../2026-10-28-v1-plan.md) · Spec §4.3, §6
> T1.1 bittikten sonra Faz 1 ile paralel yürür. Komut kalıbı: `swift test --package-path Packages/IslandDesign --filter <Suite>`
> Değerler spec §6'dan birebir; burada bir değeri değiştirmek spec değişikliğidir.

---

### T2.1 Tasarım token'ları

**Files:**
- Create: `Packages/IslandDesign/Sources/IslandDesign/Tokens/{Palette,Typography,Spacing,Radii,Motion,HaloLevel}.swift`
- Test: `Packages/IslandDesign/Tests/IslandDesignTests/Tokens/DesignTokenTests.swift`

**Interfaces:**
- Consumes: T1.1 `RGBAColor`, `SignalTint`.
- Produces:
  - `enum Palette { static let obsidian, inkRaised, inkPressed, hairline, textPrimary, textSecondary, textTertiary, signalGreen, signalOrange, signalRed: Color; static let obsidianRGBA: RGBAColor; static func tint(_: SignalTint) -> Color; static func color(_: RGBAColor) -> Color }` — değerler spec §6.1 (`#000000`, `#111113`, `#1C1C1F`, beyaz %10, `#F5F5F7`, beyaz %62, beyaz %38, `NSColor.systemGreen/Orange/Red`); `tint(.neutral)` = `textPrimary`.
  - `enum TypeToken: CaseIterable { numeralLarge, numeralCompact, title, body, caption; var size: CGFloat; var weight: Font.Weight; var isRounded: Bool; var monospacedDigits: Bool; var font: Font }` — 28/13/15/13/11 (spec §6.2).
  - `enum Spacing { static let scale: [CGFloat] = [2, 4, 6, 8, 12, 16, 20, 24]; static let compactPadding: CGFloat = 6; static let expandedPadding: CGFloat = 14 }`
  - `enum Radii { static let closedShoulder: CGFloat = 6; closedCorner = 10; expandedShoulder = 12; expandedCorner = 26; artworkSmall = 6; artworkLarge = 12; static func inner(outer: CGFloat, padding: CGFloat) -> CGFloat; static var card: CGFloat /* inner(26, 14) = 12 */ }`
  - `struct MotionSpec: Equatable { duration: Double; bounce: Double; var animation: Animation }`; `enum MotionToken: CaseIterable { open, close, peek, morph, content, bud, pulse, breath; var spec: MotionSpec; static var transitions: [MotionToken] /* breath hariç */; static func animation(_: MotionToken, reduceMotion: Bool) -> Animation; static let reducedTransition: AnyTransition /* .opacity + scale 0.98 */ }`
  - `enum HaloLevel: CaseIterable { off, ambient, active, alert; var intensity: Double }` — 0 / 0.16 / 0.32 / 0.55.

Hareket değerleri (spec §6.5): open 0.45/0.10 · close 0.35/0 · peek 0.30/0.08 · morph 0.40/0.05 · content 0.25/0 (`.smooth`) · bud 0.55/0 · pulse 0.9/0 · breath 5.0/0 (döngü). "Hareketi Azalt" → her token için `.easeInOut(duration: 0.2)`. **Not:** 2 sn kuralı geçişler içindir; `breath` bir ortam döngüsüdür ve Core Animation'da çalışır (spec §6.5 metni bu şekilde güncellendi).

- [ ] **Step 1: Testler**

```swift
@Suite struct DesignTokenTests {
    @Test func obsidianIsPureOpaqueBlack() throws {
        #expect(Palette.obsidianRGBA == RGBAColor(red: 0, green: 0, blue: 0, alpha: 1))
        let c = try #require(NSColor(Palette.obsidian).usingColorSpace(.sRGB))
        #expect(c.redComponent == 0 && c.greenComponent == 0 && c.blueComponent == 0 && c.alphaComponent == 1)
    }
    @Test func smallestTypeIs11pt() { #expect(TypeToken.allCases.map(\.size).min() == 11) }
    @Test func transitionsRespectBounceAndDurationLimits() {
        for t in MotionToken.transitions { #expect(t.spec.bounce <= 0.12 && t.spec.duration <= 2.0, "\(t)") }
    }
    @Test func motionValuesMatchSpec() {
        #expect(MotionToken.open.spec == MotionSpec(duration: 0.45, bounce: 0.10))
        #expect(MotionToken.close.spec == MotionSpec(duration: 0.35, bounce: 0))
        #expect(MotionToken.peek.spec == MotionSpec(duration: 0.30, bounce: 0.08))
        #expect(MotionToken.morph.spec == MotionSpec(duration: 0.40, bounce: 0.05))
    }
    @Test func reducedMotionUsesShortEase() { #expect(MotionToken.animation(.open, reduceMotion: true) == .easeInOut(duration: 0.2)) }
    @Test func haloIntensitiesMatchSpec() { #expect(HaloLevel.allCases.map(\.intensity) == [0, 0.16, 0.32, 0.55]) }
    @Test func cardRadiusIsConcentric() { #expect(Radii.card == 12) }
}
```

- [ ] **Step 2–4:** `--filter DesignTokenTests` → FAIL → uygula → PASS (7 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(design): color, type, spacing, radius, motion and halo tokens"`

---

### T2.2 `IslandShape` (omuz + sürekli köşe)

**Files:**
- Create: `Packages/IslandDesign/Sources/IslandDesign/Shape/IslandShape.swift`
- Test: `Packages/IslandDesign/Tests/IslandDesignTests/Shape/IslandShapeTests.swift`

**Interfaces:**
- Consumes: T2.1 `Radii`.
- Produces: `struct IslandShape: Shape { var shoulderRadius: CGFloat; var cornerRadius: CGFloat; static let closed /* 6, 10 */; static let expanded /* 12, 26 */; var animatableData: AnimatablePair<CGFloat, CGFloat>; func path(in rect: CGRect) -> Path }`

Geometri (SwiftUI koordinatları, y aşağı): `s = min(shoulderRadius, rect.height, rect.width / 4)`. Gövde `body = rect.insetBy(dx: s, dy: 0)`; gövde yolu `UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: c, bottomTrailingRadius: c, topTrailingRadius: 0, style: .continuous).path(in: body)`, `c = min(cornerRadius, body.width / 2, body.height)`. Sol omuz bölgesi = `(0, 0, s, s)` karesi **eksi** `(0, s)` merkezli `s` yarıçaplı daire; sağ omuz aynanın simetriği (`(rect.width, s)` merkezli). Üç parça `CGPath.union(_:using:)` ile **tek bir dış hatta** birleştirilir (yan yana alt yollar kenar yumuşatmada ince bir dikiş bırakır). Kübik "squircle" sabitleri elle yazılmaz; sürekli köşe SwiftUI'nin `.continuous` stilinden gelir. `s == 0` ise yalnızca gövde.

- [ ] **Step 1: Testler**

```swift
@Suite struct IslandShapeTests {
    let rect = CGRect(x: 0, y: 0, width: 300, height: 60)
    var path: Path { IslandShape(shoulderRadius: 12, cornerRadius: 26).path(in: rect) }
    @Test func pathBoundsEqualRect() {
        let b = path.boundingRect
        #expect(abs(b.minX) < 0.5 && abs(b.minY) < 0.5 && abs(b.width - 300) < 0.5 && abs(b.height - 60) < 0.5)
    }
    @Test func centerIsInside() { #expect(path.contains(CGPoint(x: 150, y: 30))) }
    @Test func shoulderFlaresOutwardAtTop() {
        #expect(path.contains(CGPoint(x: 6, y: 0.5)))       // üst kenarda omuz içinde
        #expect(!path.contains(CGPoint(x: 1, y: 12)))       // omuz altı, gövdenin solu: dışarıda
    }
    @Test func bottomCornersAreRounded() {
        #expect(!path.contains(CGPoint(x: 13, y: 59)))
        #expect(path.contains(CGPoint(x: 20, y: 30)))
    }
    @Test func zeroShoulderDegeneratesToBodyOnly() {
        #expect(IslandShape(shoulderRadius: 0, cornerRadius: 10).path(in: rect).contains(CGPoint(x: 0.5, y: 0.5)))
    }
    @Test func tinyRectDoesNotOverflow() {
        let small = CGRect(x: 0, y: 0, width: 40, height: 20)
        let b = IslandShape.expanded.path(in: small).boundingRect
        #expect(b.width <= 40.5 && b.height <= 20.5)
    }
    @Test func radiiAnimateTogether() {
        var s = IslandShape.closed; s.animatableData = AnimatablePair(12, 26)
        #expect(s.shoulderRadius == 12 && s.cornerRadius == 26)
    }
}
```

- [ ] **Step 2–4:** `--filter IslandShapeTests` → FAIL → uygula → PASS (7 test).
- [ ] **Step 5: Görsel kontrol** — `#Preview` içinde `IslandShape.closed` ve `.expanded`'ı 4× büyütülmüş, beyaz zemin üzerinde siyah çiz; omuz eğrisinin üst kenara teğet girdiğini ve köşede kırılma olmadığını gözle doğrula. Ekran görüntüsünü `docs/qa/shots/island-shape.png` olarak kaydet.
- [ ] **Step 6: Commit** — `git add` (kaynak, test, ekran görüntüsü) → `git commit -m "feat(design): island shape with concave shoulders and continuous corners"`

---

### T2.3 Hâle (Core Animation tabanlı ışık)

**Files:**
- Create: `Packages/IslandDesign/Sources/IslandDesign/Halo/{HaloState,HaloStyle,HaloLayer,HaloView}.swift`
- Test: `Packages/IslandDesign/Tests/IslandDesignTests/Halo/{HaloStyleTests,HaloLayerTests}.swift`

**Interfaces:**
- Consumes: T1.1 `RGBAColor`; T2.1 `HaloLevel`.
- Produces:
  - `enum HaloMode: Equatable, Sendable { off, ambient(breathing: Bool), progress(fraction: Double, endsAt: Date?), warming(fraction: Double), fill(fraction: Double), pulse }`
  - `struct HaloState: Equatable, Sendable { var mode: HaloMode; var color: RGBAColor; var intensityScale: Double = 1; static let off }`
  - `struct HaloAccessibility: Equatable, Sendable { var reduceMotion = false; var reduceTransparency = false; var increaseContrast = false; var lowPowerMode = false; static let standard }`
  - `struct HaloStyleValues: Equatable { keyLineWidth: CGFloat; keyLineOpacity: Double; glowOpacity: Double; glowRadius: CGFloat; breathes: Bool; pulses: Bool }`
  - `enum HaloStyle { static func resolve(_ state: HaloState, accessibility: HaloAccessibility) -> HaloStyleValues }`
  - `final class HaloLayer: CALayer { func apply(_ values: HaloStyleValues, state: HaloState, outline: CGPath, now: Date); func suspend() }` — animasyon anahtarları: `"nimbo.breath"`, `"nimbo.progress"`, `"nimbo.pulse"`.
  - `struct HaloView: NSViewRepresentable { var state: HaloState; var outline: CGPath; var lowPowerMode: Bool }` — erişilebilirlik bayraklarını `@Environment(\.accessibilityReduceMotion)`, `\.accessibilityReduceTransparency`, `\.colorSchemeContrast` değerlerinden okur.

Kurallar (spec §6.4): `off` → her şey 0. `ambient` → parıltı 0.16 × ölçek, anahtar çizgi 1 pt %35, `breathes = breathing && !reduceMotion && !lowPowerMode`. `progress`/`warming`/`fill` → 0.32 × ölçek. `pulse` → tepe 0.55 × ölçek, `pulses = !reduceMotion` (azaltılmışsa sabit 0.32). `reduceTransparency` → `glowOpacity = 0`. `increaseContrast` → çizgi 1.5 pt %60. Parıltı yarıçapı 14.
Katman: parıltı = `shadowPath = outline`, `shadowRadius = 14`, `shadowOffset = .zero`, `shadowColor = accent`, `shadowOpacity = glow` (içerik yok; gölge yol üzerinden çizilir). Anahtar çizgi ve ilerleme = iki `CAShapeLayer` (dolgu yok, kontur). Nefes: `CABasicAnimation("shadowOpacity")` 0.6×glow → glow, 2.5 sn, `autoreverses`, sonsuz, ease-in-out. İlerleme: `strokeEnd = fraction`; `endsAt` varsa `strokeEnd` fraction → 1, süre `endsAt − now`, doğrusal (render sunucusunda çalışır, uygulama her saniye uyanmaz). Darbe: `CAKeyframeAnimation("shadowOpacity")` `[0, peak, 0]`, `keyTimes [0, 0.35, 1]`, 0.9 sn. Özellik atamaları `CATransaction.setDisableActions(true)` içinde. `suspend()` tüm animasyonları kaldırır (görünmeyen ada animasyon yapmaz).

- [ ] **Step 1: Testler**

```swift
@Suite struct HaloStyleTests {
    let red = RGBAColor(red: 1, green: 0, blue: 0)
    @Test func ambientIntensityIs016() { #expect(HaloStyle.resolve(.init(mode: .ambient(breathing: true), color: red), accessibility: .standard).glowOpacity == 0.16) }
    @Test func alertPeakIs055() { #expect(HaloStyle.resolve(.init(mode: .pulse, color: red), accessibility: .standard).glowOpacity == 0.55) }
    @Test func intensityScaleMultiplies() { #expect(HaloStyle.resolve(.init(mode: .ambient(breathing: false), color: red, intensityScale: 0.5), accessibility: .standard).glowOpacity == 0.08) }
    @Test func reduceMotionDisablesBreathAndPulse() {
        var a = HaloAccessibility.standard; a.reduceMotion = true
        #expect(!HaloStyle.resolve(.init(mode: .ambient(breathing: true), color: red), accessibility: a).breathes)
        #expect(!HaloStyle.resolve(.init(mode: .pulse, color: red), accessibility: a).pulses)
    }
    @Test func lowPowerDisablesBreath() {
        var a = HaloAccessibility.standard; a.lowPowerMode = true
        #expect(!HaloStyle.resolve(.init(mode: .ambient(breathing: true), color: red), accessibility: a).breathes)
    }
    @Test func reduceTransparencyRemovesGlow() {
        var a = HaloAccessibility.standard; a.reduceTransparency = true
        #expect(HaloStyle.resolve(.init(mode: .pulse, color: red), accessibility: a).glowOpacity == 0)
    }
    @Test func increaseContrastThickensKeyLine() {
        var a = HaloAccessibility.standard; a.increaseContrast = true
        let v = HaloStyle.resolve(.init(mode: .ambient(breathing: false), color: red), accessibility: a)
        #expect(v.keyLineWidth == 1.5 && v.keyLineOpacity == 0.6)
    }
    @Test func offIsFullyDark() {
        let v = HaloStyle.resolve(.off, accessibility: .standard)
        #expect(v.glowOpacity == 0 && v.keyLineOpacity == 0 && !v.breathes)
    }
}

@MainActor @Suite struct HaloLayerTests {
    let outline = CGPath(rect: CGRect(x: 0, y: 0, width: 200, height: 40), transform: nil)
    func applied(_ s: HaloState, _ a: HaloAccessibility = .standard) -> HaloLayer {
        let l = HaloLayer(); l.apply(HaloStyle.resolve(s, accessibility: a), state: s, outline: outline, now: Date()); return l
    }
    @Test func breathingAddsBreathAnimation() {
        #expect(applied(.init(mode: .ambient(breathing: true), color: .white)).animation(forKey: "nimbo.breath") != nil)
    }
    @Test func reduceMotionAddsNoAnimations() {
        var a = HaloAccessibility.standard; a.reduceMotion = true
        #expect((applied(.init(mode: .ambient(breathing: true), color: .white), a).animationKeys() ?? []).isEmpty)
    }
    @Test func progressWithEndDateAnimatesStrokeEnd() {
        let l = applied(.init(mode: .progress(fraction: 0.2, endsAt: Date().addingTimeInterval(60)), color: .white))
        #expect(l.sublayers?.contains { $0.animation(forKey: "nimbo.progress") != nil } == true)
    }
    @Test func suspendRemovesAllAnimations() {
        let l = applied(.init(mode: .ambient(breathing: true), color: .white)); l.suspend()
        #expect((l.animationKeys() ?? []).isEmpty && (l.sublayers ?? []).allSatisfy { ($0.animationKeys() ?? []).isEmpty })
    }
}
```

- [ ] **Step 2–4:** `--filter "HaloStyleTests|HaloLayerTests"` → FAIL → uygula → PASS (12 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(design): halo light language on Core Animation"`

---

### T2.4 Tomurcuk (metaball) geçişi

**Files:**
- Create: `Packages/IslandDesign/Sources/IslandDesign/Bud/{MetaballMath,MetaballBridge}.swift`
- Test: `Packages/IslandDesign/Tests/IslandDesignTests/Bud/MetaballTests.swift`

**Interfaces:**
- Produces:
  - `enum MetaballMath { static let maxBlur: CGFloat = 6; static func blurRadius(progress: Double) -> CGFloat /* maxBlur × sin(π·p) */; static func bubbleRect(progress: Double, from: CGRect, to: CGRect) -> CGRect /* doğrusal */ }`
  - `struct MetaballBridge: View, Animatable { var islandRect: CGRect; var bubbleStart: CGRect; var bubbleEnd: CGRect; var progress: Double; var islandCornerRadius: CGFloat }` — `Canvas` içinde `context.addFilter(.alphaThreshold(min: 0.5, color: .black))` + `context.addFilter(.blur(radius: blurRadius))`, sonra `drawLayer` içinde ada (yuvarlak dikdörtgen) ve baloncuk (daire) siyah doldurulur. **Yalnızca 0.55 sn'lik geçiş sırasında** kullanılır; kararlı durumda kök görünüm düz şekilleri çizer (Canvas yok). "Hareketi Azalt" → köprü yok, opaklık geçişi.

- [ ] **Step 1: Testler**

```swift
@Suite struct MetaballTests {
    @Test func blurIsZeroAtEndsAndPeaksAtMidpoint() {
        #expect(MetaballMath.blurRadius(progress: 0) == 0)
        #expect(MetaballMath.blurRadius(progress: 1) < 0.001)
        #expect(MetaballMath.blurRadius(progress: 0.5) == 6)
    }
    @Test func bubbleInterpolatesLinearly() {
        let r = MetaballMath.bubbleRect(progress: 0.5, from: CGRect(x: 0, y: 0, width: 10, height: 10), to: CGRect(x: 100, y: 0, width: 30, height: 30))
        #expect(r == CGRect(x: 50, y: 0, width: 20, height: 20))
    }
    @MainActor @Test func bridgeRendersOnlyBlackOrClearPixels() throws {
        let view = MetaballBridge(islandRect: CGRect(x: 10, y: 0, width: 120, height: 32), bubbleStart: CGRect(x: 100, y: 0, width: 32, height: 32),
                                  bubbleEnd: CGRect(x: 140, y: 0, width: 32, height: 32), progress: 0.5, islandCornerRadius: 10).frame(width: 200, height: 40)
        let image = try #require(ImageRenderer(content: view).cgImage)
        #expect(PixelProbe.allPixelsAreBlackOrTransparent(image, tolerance: 0.02))
    }
}
```
`PixelProbe` küçük bir test yardımcısıdır (aynı test hedefinde): `CGContext` ile RGBA8 tampona çizer, alfa > 0 olan her pikselde r, g, b ≤ tolerans mı diye bakar.

- [ ] **Step 2–4:** `--filter MetaballTests` → FAIL → uygula → PASS (3 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(design): metaball bud transition"`

---

### T2.5 Dokunsal ve sesli geri bildirim

**Files:**
- Create: `Packages/IslandCore/Sources/IslandCore/Ports/FeedbackPlaying.swift`
- Create: `Packages/IslandDesign/Sources/IslandDesign/Feedback/SystemFeedbackPlayer.swift`
- Test: `Packages/IslandDesign/Tests/IslandDesignTests/Feedback/SystemFeedbackPlayerTests.swift`

**Interfaces:**
- Consumes: T1.4 `HapticKind`, `SoundKind`.
- Produces:
  - `@MainActor public protocol FeedbackPlaying: AnyObject { func play(_ haptic: HapticKind); func play(_ sound: SoundKind) }` (IslandCore)
  - `@MainActor final class SystemFeedbackPlayer: FeedbackPlaying { init(performer: NSHapticFeedbackPerformer = NSHapticFeedbackManager.defaultPerformer, playSound: @escaping @MainActor (String) -> Void = { NSSound(named: $0)?.play() }, preferences: @escaping @MainActor () -> (haptics: Bool, sounds: Bool)) }` — eşleme: `.alignment`→`.alignment`, `.levelChange`→`.levelChange`, `.generic`→`.generic`, zaman `.now`; `timerFinished` → `"Glass"`.

- [ ] **Step 1: Testler** (sahte performer `NSObject` alt sınıfıdır ve `NSHapticFeedbackPerformer`'ı uygular; çağrıları kaydeder)

```swift
@MainActor @Suite struct SystemFeedbackPlayerTests {
    @Test func alignmentMapsToAlignmentPattern() {
        let fake = FakePerformer(); SystemFeedbackPlayer(performer: fake, preferences: { (true, true) }).play(.alignment)
        #expect(fake.patterns == [.alignment])
    }
    @Test func hapticsDisabledPlaysNothing() {
        let fake = FakePerformer(); SystemFeedbackPlayer(performer: fake, preferences: { (false, true) }).play(.levelChange)
        #expect(fake.patterns.isEmpty)
    }
    @Test func timerFinishedPlaysGlassWhenSoundsEnabled() {
        var played: [String] = []
        SystemFeedbackPlayer(performer: FakePerformer(), playSound: { played.append($0) }, preferences: { (true, true) }).play(.timerFinished)
        #expect(played == ["Glass"])
    }
    @Test func soundsDisabledPlaysNothing() {
        var played: [String] = []
        SystemFeedbackPlayer(performer: FakePerformer(), playSound: { played.append($0) }, preferences: { (true, false) }).play(.timerFinished)
        #expect(played.isEmpty)
    }
}
```

- [ ] **Step 2–4:** `--filter SystemFeedbackPlayerTests` → FAIL → uygula → PASS (4 test).
- [ ] **Step 5: Commit** — `git commit -m "feat(design): haptic and sound feedback player"`

**Faz 2 çıkış ölçütü:** `swift test --package-path Packages/IslandDesign` yeşil (33 test + 1 duman); `docs/qa/shots/island-shape.png` mevcut.
