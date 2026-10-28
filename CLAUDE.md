# CLAUDE.md — Lunula

Lunula is a premium macOS notch "island" app (formerly the working name "Nimbo"; the research report still uses that name). It is native Swift (SwiftUI + AppKit), sandboxed from day one, uses no private APIs, and is free. It is developed on GitHub and goes to the Mac App Store later.

## Read these first

| What | Where |
|---|---|
| Implementation plan (source of truth for progress) | `docs/superpowers/plans/2026-10-28-v1-plan.md` + `docs/superpowers/plans/v1/phase-*.md` |
| Design spec | `docs/superpowers/specs/2026-10-28-v1-design.md` |
| Market / feasibility research | `docs/research/2026-10-28-nimbo-arastirma-raporu.md` |

All planning documents are in Turkish; code, identifiers, comments and commit messages are in English.

**Status gate:** the user approved the plan on 2026-10-28 and chose **subagent-driven** execution, with the product name **Lunula**. Implementation starts at T0.1 once the planning PR is merged into `main`. Progress is tracked **only** by the checkboxes in the master plan's task list.

## Talking to the user

- Reply in **Turkish**.
- The user's standing rules, applied in every reply:
  1. Never open with agreement. The first sentence challenges an assumption, names what is missing, or asks the question that exposes the gap.
  2. Tag claims **[Certain]** (hard evidence), **[Likely]** (strong inference) or **[Guessing]**. If most of a reply is guessing, say so first.
  3. Never use: "Great question", "You're absolutely right", "That makes a lot of sense", "Absolutely", "Definitely" (or their Turkish equivalents).
  4. To disagree, use this form: "I disagree because [reason]. Here's what I'd do instead [alternative]. The risk in your approach is [downside]."
  5. Put the uncomfortable truth in the first line.
  6. No warm-up paragraphs.
  7. Hold your position under pushback unless the user gives genuinely new information.
- At the end of each phase, give a short status report: what was done, what was measured, and the next decision.

## Build and test (macOS only, Xcode 26+)

```bash
Scripts/bootstrap.sh                                   # installs xcodegen if missing, generates Lunula.xcodeproj
swift test --package-path Packages/IslandCore          # core logic (also runs on Linux)
Scripts/test-all.sh                                    # all packages + app tests
xcodebuild -project Lunula.xcodeproj -scheme Lunula -destination 'platform=macOS' build test
Scripts/lint.sh && Scripts/check-architecture.sh       # format + architecture guard
Scripts/perf/measure-idle.sh --seconds 60 --assert-idle  # idle CPU/wakeups budget (Release build running)
```

- `Lunula.xcodeproj` is generated and git-ignored. Edit `project.yml`, never the project file.
- Signing: copy `Config/Signing.xcconfig.example` to `Config/Signing.xcconfig` (git-ignored) and set `DEVELOPMENT_TEAM` to the user's paid Apple Developer team ID (`CODE_SIGN_IDENTITY = Apple Development`). Never commit the team ID or any certificate. With ad-hoc signing, macOS asks for Automation and Calendar permission again after every build.
- If the scripts do not exist yet, the plan is before T0.1/T0.2. Start there.

## Architecture rules (enforced by CI)

- **Packages:**
  - `IslandCore`: pure logic, imports only `Foundation`/`Observation`, Linux-testable.
  - `IslandDesign`: tokens, shape, halo, motion.
  - `IslandServices`: system adapters, no SwiftUI.
  - `IslandFeatures`: SwiftUI views and the store, never imports `IslandServices`.
  - `App/`: AppKit lifecycle, windows, settings, intents, URL routing.
- Concrete services are created **only** in `App/Sources/CompositionRoot.swift`.
- **Shared files** may be edited only by the Integrator (the main session), following each task's *Entegrasyon notları*: `project.yml`, `Packages/*/Package.swift`, `CompositionRoot.swift`, `AppDelegate.swift`, `IslandWindowManager.swift`, `ActivityContentView.swift`, `HomeCardView.swift`. A task touches only the files in its **Files** list.
- **Forbidden:**
  - private APIs: MediaRemote, SkyLight/`SLS*`, `CGS*`, DisplayServices, CoreBrightness;
  - `dlopen`/`dlsym`, Accessibility APIs, `CGEventPost`, `Process`/`NSTask`, running `/usr/bin/*`;
  - `NSWindow.sharingType`, `DispatchQueue.main.sync`;
  - disabling App Sandbox or Hardened Runtime;
  - any new third-party dependency without user approval (only `KeyboardShortcuts` is allowed);
  - copying GPL code (Boring Notch, Atoll, DynamicNotch, MewNotch).
- **Off the main thread:** AppleScript, network, disk I/O, image processing.
- **No polling.** Use events plus a single scheduled timer through the injected `IslandTime`.
- **Swift 6 strict concurrency.** No default actor isolation; annotate `@MainActor` explicitly.
- **Design invariants:**
  - The island core is always opaque `#000000`.
  - The smallest text is 11 pt.
  - Spring bounce is ≤ 0.12 and transitions last ≤ 2 s.
  - Respect Reduce Motion, Reduce Transparency and Increase Contrast.
  - Nothing invisible animates.
- Every user-facing string goes in a String Catalog with **Turkish and English**, and contains no exclamation marks.
- **Performance budget:** idle < 0.1% CPU and < 1 wakeup/s; music playing < 1% CPU; memory < 120 MB.

## Workflow

- Skills: `superpowers:subagent-driven-development` (execution), `superpowers:test-driven-development` (every task), `superpowers:using-git-worktrees` (parallel tasks), `superpowers:dispatching-parallel-agents`, `superpowers:verification-before-completion` (before any "done"), `superpowers:systematic-debugging` (any failure), `superpowers:requesting-code-review`, `superpowers:finishing-a-development-branch`. Also `design:accessibility-review` for T9.4 and `design:design-critique` for visual reviews.
- **Branches (owner decision, 2026-10-28):**
  - Work directly on `main`. No feature branches, no PRs.
  - Before every commit, `Scripts/lint.sh && Scripts/check-architecture.sh && Scripts/test-all.sh` must be green.
  - CI runs on every push to `main`. A red run is fixed before the next task starts.
  - Never force-push.
- **Commits:** Conventional Commits in English (`feat:`, `fix:`, `test:`, `chore:`, `docs:`, `perf:`, `ci:`). Never put a model name in commits, PRs or code.
- **Evidence over claims:** every task report includes the actual output of its failing test and its passing test runs.
- **Spikes (T3.7 fullscreen, T5.2 Music scripting, T7.5 camera/mic):**
  - Record the findings in `docs/qa/spikes/`.
  - Show them to the user before you lock the decision.
  - A permission prompt that would surprise the user is never acceptable.

## Facts verified on 2026-10-28 (do not re-research unless something breaks)

- **Notch geometry:**
  - height = `NSScreen.safeAreaInsets.top`
  - width = `frame.width − auxiliaryTopLeftArea.width − auxiliaryTopRightArea.width`
  - `auxiliaryTop*Area` is nil without a notch, which means pill mode.
  - `NSScreen.cgDirectDisplayID` is new in macOS 26.
- **Screen changes:** `NSApplication.DidChangeScreenParametersMessage` exists only on macOS 27, so use the classic `NotificationCenter` notification.
- **Full-screen detection:** no public API reads another app's full-screen state. Use the `CGWindowList` bounds + menu-bar-layer heuristic, which needs no Screen Recording permission. False positives are possible.
- **Now Playing:**
  - No public API reads other apps' Now Playing. Support only Music and Spotify, through AppleScript.
  - Music has scripting access groups: `com.apple.Music.playback`, `com.apple.Music.playerInfo`.
  - Spotify needs a temporary exception. App Review rarely approves it, so it sits behind `LUNULA_SPOTIFY`.
  - Spotify `duration` is in milliseconds.
  - Never script an app that is not running.
  - `AEDeterminePermissionToAutomateTarget` codes: -1744 = consent needed, -1743 = denied, -600 = not running.
- **Focus status is out of v1:** it needs the Communication Notifications capability and carries App Review risk.
- **App Intents (macOS 26):** use `static let supportedModes: IntentModes = .background`. `openAppWhenRun` is deprecated.
- **WeatherKit** is not available for Developer ID distribution, so v1 uses Open-Meteo (attribution: CC BY 4.0).
- **Distribution:** the user has a paid Apple Developer Program membership, so GitHub releases are Developer ID–signed, notarized and stapled DMGs (T9.7). Secrets live only in GitHub Actions secrets.
- **Tooling:**
  - CI runner `macos-26` defaults to Xcode 26.6.
  - KeyboardShortcuts 3.1.0 is sandbox-safe.
  - XcodeGen 2.46.0.
  - `swift format` ships with the toolchain.
