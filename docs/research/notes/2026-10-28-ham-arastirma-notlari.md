# Nimbo — ham araştırma notları (raw research log, 2026-10-28)

> Rapor: ../2026-10-28-nimbo-arastirma-raporu.md · Bu dosya, raporun dayandığı ham bulguları (çoğu İngilizce) ve kod kanıtlarını içerir.

## Repo state
- kutluhangil/nimbo: only LICENSE (MIT, (c) 2026 Kutluhan Gül) + .gitattributes. Branch claude/vigilant-franklin-82wbqt.
- NOTE: repo is PRIVATE (checked via API) but carries an MIT LICENSE; if made public, anyone could legally rebuild/sell. GPL code (boring.notch, Atoll, DynamicNotch, MewNotch, Shima) cannot be copied into a closed/paid MAS app.

## Sapphire (sapphire-app.tech) — user's current app
- Dev: Shariq Charolia (cshariq/Sapphire on GitHub, 387 stars, "183.6k downloads"). Download is .pkg from GitHub releases (not MAS).
- Tagline "The Notch, Reimagined." "An all-in one utility app for mac os".
- Tiers: Free / Basic / Pro / Ultra (subscription; Notchy says $15.99–$30.99/month for AI/live-data tiers).
- PAID: Blip agent (computer-use AI agent, Pro&Ultra), Blip Live (screen-aware voice convo, Basic/Pro/Ultra), Circle to Search (Pro/Ultra), Sports Live Activity (Pro/Ultra), Sports Widget (Ultra), Finance widget & live activity (Ultra).
- FREE: Face ID on Mac (camera face recognition w/ anti-spoof model, keychain), 60% extra brightness boost (XDR 1600 nit) + Spotify in volume HUD, multi audio (per-app volume, per-app EQ 10-band, device EQ, multi-device routing), battery management (charge limit 80%), Snap Zones (window mgmt), File Shelf, Android Nearby Share (!), Music widget (waveforms, lyrics, next songs, recommended tracks, scrubbing), Caffeinate, Lock screen widgets (music, sports, weather), Quick notes, infinite clipboard history, interactive calendar grid, mirror camera, persistent weather, Bluetooth fast connect, notch banner notifications, Shortcuts & automation, 20-20-20 eye break, menubar customization.
- Has google-adsense account meta on site. Very feature-bloated, AI upsell heavy.
- User screenshot (Oct 28) = wide black panel: top icon row (settings, inbox/shelf, notes?, clipboard, AI sparkle, moon) + right icons (mirror?, caffeinate, pin); content: album art + track + transport | weather 16° Tuzla light rain shower + wind/humidity/precip | calendar Oct week strip + events (GitHub Universe 2026, Cumhuriyet Bayramı) | clipboard list (200 items). Dense, dashboard-like, many font weights, colored weekday letters; feels like a widget board, not an island.

## MacNotch (macnotch.io)
- Paid: $22.99 lifetime or $3.99/mo; 14-day trial; 3 Macs/license. Stripe/Link MoR. ALSO on Setapp (mentions "Setapp rating").
- STATUS Oct 2026: "New downloads and brand-new purchases are briefly paused" (temporarily unavailable!).
- macOS 14+, Apple Silicon & Intel, physical notch optional, multiple displays.
- Modules: Dashboard (profiles w/ Focus & time-based switching, 4 widget slots), Media (Spotify, Apple Music, Plex, NetEase, VOX, VLC, browsers, system audio; bars or spectrum viz), Calendar (events+reminders, search, meeting awareness), Todo (synced with Reminders), Notes, Pomodoro, Day Progress (timeline of today), Screen Time (own tracking of frontmost app), Health (break rings, water, mindful, breathing, stretch, 20-20-20), Weather (Open-Meteo, photographic sky backgrounds), Keyboard shortcuts, Notifications (reply), 11 languages, AI Coding beta (Claude Code + Cursor sessions allow/deny), Code hosting (GitHub/GitLab/Bitbucket PRs, Jira), Translation (OpenAI/Ollama), Live Activities strip (rotates media, timers, calendar, BT, app updates), Volume/Brightness HUD, Drop Actions (shelf, AirDrop, cloud, zip, convert, move, open with, trash, eject), Shelf, Window snap zones (drag window to top), Bluetooth battery, System monitor.
- "Hide from screenshots & recordings" toggle (NSWindow.sharingType = .none).
- Known bug listed: notch sits slightly below menu bar -> manual nudge setting.

## Notchy (notchy.dev) — Vishva Variya, closed source
- $24.99 one-time (Black Friday $14.99), 7-day trial, 1 Mac per license, Dodo Payments MoR, Sparkle updates, Homebrew tap. macOS 13+. Claims 34,004 installs, 4.3★ from 4183 in-app ratings, 134 languages, ~0% idle CPU (0.9% one core under load measured).
- 74 features incl: Face Unlock (Vision + liveness, keychain), Now Playing (Spotify/Apple Music, scrubbing, shuffle/repeat, per-app volume, browser video speed), AI usage tracker (Claude Code, Codex, Cursor, Copilot; 35+ providers), Sound mixer per-app (14.4+, 3-band EQ), search & translate & calculator, Command palette ⌃⌥K, Knock to control (tap trackpad/knock chassis -> accelerometer?!), menu bar detach of tabs, clipboard history w/ smart actions + OCR search, Cuely teleprompter, System HUDs (hide stock HUD incl. Tahoe), AirPods manager (nearby case detection, per-bud battery), Pomodoro (streaks, 7-day chart), calendar, camera mirror, hide the notch (black menubar), Liquid Glass UI + resizable panel, quick notes, file shelf (persists), keep awake, weather, focus mode island, battery HUD, synced lyrics via LRCLIB, Reminders, image converter, audio switcher, device battery, download alerts, Shortcuts runner, zip/unzip (ditto), screenshot shelf, drive eject, app launcher, window snapping, text snippets, screen capture, color eyedropper, mic mute (CoreAudio), keystroke HUD, keyboard cleaning lock, menu bar icon hiding, system stats, call island (FaceTime/phone + Teams/Zoom/WhatsApp duration), stocks ticker, notch terminal (PTY), WidgetKit desktop widgets, Agent approvals (Claude Code/Codex hooks), privacy indicator (camera/mic in use via CoreMediaIO/CoreAudio), caps lock HUD, full charge island, alt HUD styles, LIVE AUDIO SPECTRUM via Core Audio process tap FFT (real, not fake), custom Lottie idle animation, multiple live activities side-by-side (pill widens, ranks by cost-to-miss), lock screen widgets (clicks pass through), message island (reply via Accessibility), notification mirror (Full Disk Access), agent activity, shell activity (zsh preexec hook), developer API (localhost:9999 token-signed JSON -> custom live activities), external display DDC brightness (IOAVService), keyboard backlight (CoreBrightness private), AirDrop from shelf, peek on hover (60ms trigger), drift-free stopwatch, gestures, hidden from screen capture, pill on any Mac, timer mascots, automatic updates.
- Comparison claims: Alcove $14.99 one-time macOS 15+; NotchNook $15 (or $2/mo) macOS 14+; Seam $29 Apple silicon only; Sapphire free core + $15.99–$30.99/month tiers; DynamicLake paid; MediaMate paid; SuperIsland = Electron (0.46% idle CPU).
- Notchy alternatives hub lists notch apps: NotchNook, Boring Notch, Atoll, Alcove, DynamicLake, MediaMate, SuperIsland, Peninsula, MewNotch, Sapphire, MacNotch, NotchFlow, Notchly, Notchify, Canopy, Droppy, Seam, Perch, DropNotch, NotchBox, Crest, NotchNest, FavTray, TopNotch, Notchmeister, Pulse Island, Islet, OmniNotch, Dynamic Notch (dynamicnotch.tech), Brow, OneNotch, NotchSpace, NotchBay, DynamicNotch, Cyclop, NotchBar. Teleprompters: CueNotch ($29.99), NotchPrompter, QPrompt, Moody, Avocado, Notchie, Textream. AI notch: Vibe Island, CodeIsland, Ping Island, Vibe Notch, Notchi, Claude God, Coucou. HUD: volumeHUD, SlimHUD. Shelf: NotchDrop, Dropover, Yoink.
- Notchy blog: "macOS Tahoe has clipboard history in Spotlight" (sherlock signal!).
- Marketing: SEO machine with 221 comparison pages. Feature-count arms race (74 features).

## DynamicNotch (jackson-storm/DynamicNotch; site on workers.dev, dynamicnotch.com) — Evgeniy Petrukovich
- Free, open source, donations (Boosty, crypto). macOS 14.6+. v1.6.3 Oct 2026. 25+ languages, 20+ features. "Low battery impact", "no telemetry".
- Features: universal notification interception, Messages & Mail alerts, external drive HUDs, live media controls, lockscreen lyrics, lock screen widgets, Liquid Glass effects. Keywords mention "Canopy Mac" (maybe renamed from/to Canopy?).

## Sapphire pricing (sapphire-app.tech/subscribe)
- Free $0 (1 Mac): Face ID on Mac, XDR brightness boost, Spotify in volume HUD, audio mixer + 10-band EQ, snap zones, file shelf & Nearby Share, caffeinate & lock screen.
- Basic $15.99/mo (+$11/device): Blip Live voice, device agent automation, beta channels.
- Pro $25.99/mo (+$13.99/device): Blip Agent, Circle to Search, Sports live activity, more AI quota.
- Ultra $30.99/mo (+$15.99/device): finance widget & live markets, sports widget, priority support.
- Notchy says Sapphire core is AGPL-3.0, needs macOS 14.6.
- => Paywall is AI/live-data subscriptions at absurd prices for a notch app ($186–$372/yr).

## Competitor roundups (both vendor-biased!)
### notchy.dev/best-mac-notch-apps (updated 17 Oct 2026)
| Notchy $24.99 13+ | Alcove $14.99 15+ | NotchNook $15 14+ | Boring Notch free 14+ | Atoll free 14+ (3.7k stars, notched MBP only, English only) | Sapphire free + $15.99–30.99/mo 14.6+ | Seam $29 (Apple silicon, 48h trial, local dictation/translation) | DynamicLake paid 14+ ("most-recommended paid notch app on Reddit 2026", stable) | MediaMate paid 14+ | NotchBox free + $4.99 Pro IAP, macOS 13+ (ON MAC APP STORE! water/habit tracking) | Crest free / Pro $24.99 or $2.99/mo (SSH host list) | Brow free / Pro $49/yr (launcher, clipboard, window mgmt, OCR, fan control, PDF editor) | Droppy $9.99 (shelf, clipboard, snap, cloud sharing) | OneNotch free / Pro $9.99, macOS 15 + Apple silicon (clipboard boards, visualizer, AI agent status, OCR, dictionary) | NotchSpace free macOS 15 (shelf, launch bar, menu bar manager, HEX color cards, image compression)
### macnotch.io/compare (Aug 9 2026)
- NotchNook (lo.cafe) $25 once (5 devices) or $3/mo (2 devices), Setapp, macOS 14.6, v1.6.2, Shortcuts widget, custom GIFs, draws artificial notch on externals (some dislike).
- Alcove $14.99 once (tryalcove.com): "owns most beautiful notch" — fluid transitions, live activities, swipe gestures, custom HUDs, lock screen widgets; NO file shelf, few productivity modules.
- Boring Notch ~10k stars: "rougher edges, occasional bugs, manual install".
- Atoll (getatoll.app): system stats incl GPU, clipboard, color picker, lock screen widgets; needs notched MBP; asks for wide permissions.
- DynamicLake Pro $13.99 (dynamiclake.com): DynaClip clipboard, DynaDrop, notifications (iMessage/WhatsApp/Slack), Liquid Glass look, miniLake mode, BetterDisplay integration, no trial/30-day refund.
- Seam $19.90 (getseam.app) — prices conflict w/ Notchy ($29).
- MediaMate ~$7–9 (wouter01.github.io/MediaMate) HUD replacement, macOS 13+, 4 themes.
- Droppy ~$7 (getdroppy.app). Moody $59 teleprompter (moody.mjarosz.com).
- MacNotch has Liquid Glass (Beta) on Tahoe with tunable glass vs Solid.
- KEY INSIGHT from MacNotch FAQ: "cost comes from audio visualizers, system stats polled constantly, anything requiring screen recording." "Two notch apps at once => flicker."
- Prices conflict between sources (NotchNook $15 vs $25; Notchy free vs $24.99 -> Notchy went paid ~Oct 2026). Must verify at vendor.

## Alcove (tryalcove.com) — closed source, Stripe purchase $13.99 now (was $14.99), macOS 15+
- Site sections: Fluid transitions, Instant notifications, Live Activities, Swipe gestures, "Packed with surprises", Customizable HUDs, Lock Screen widgets, Blazing fast native app. Interactive web demo (lock screen "Press to unlock", now playing).
- Reputation: "owns most beautiful notch / pure Dynamic Island vibe". No shelf, few productivity modules.

## DynamicLake (dynamiclake.com) by Aviorrok — Framer site; DynamicLake 2; DynaMusix (music), DynaClip, DynaDrop (uses FFmpeg LGPL for conversion), notifications, calls, AirDrop, timer, Liquid Glass, BetterDisplay support; warns of clones "AppleLake / Dynamiclake.net" (clone/scam problem in category!).

## DynamicNotch (jackson-storm) GitHub — GPL-3.0, 606 stars, 44 forks, 851 commits, active (Oct 25 2026), macOS 14.6+, v1.6.3, Sparkle appcast, 38+ languages
- Claims own engine, "completely copies logic, animations and behavior of real Dynamic Island" — physics springs, jelly morphing, squash/stretch, synchronized content interpolation.
- Live activities: Now Playing (+visualizer, progress tint), downloads, AirDrop, timer, screen recording indicator, Focus, Personal Hotspot, lock screen media.
- Temporary alerts: charging, low/full battery, Bluetooth, Wi-Fi, VPN, Focus off.
- Gestures: drag, trackpad swipes, swipe-to-dismiss/restore w/ adaptive radius & blur, horizontal scroll-to-dismiss.
- Floating capsule (DynamicIslandShape) when topInset == 0 (no notch).
- NowPlaying via mediaremote-adapter through /usr/bin/perl (commit Apr 24 2026) + NowPlayingAudioLevelMonitor; Screen Recording perm for audio-reactive viz; Accessibility for HUD interception; LRCLIB + lyrics.ovh lyrics; Lottie.

## GitHub topic sweep (Oct 28 2026)
- topic notch: 920 repos (668 Swift); dynamic-island: 791 (370 Swift); macbook-notch: 60; notch-app: 60.
- Top by stars (notch topic): Louis-CFM/coucou 6.6k (AI agent buddy in notch + iPhone lock screen approvals; cross-platform), jacklandrin/OnlySwitch 6k (menu bar all-in-one, has notch), wxtsky/CodeIsland 2.5k (AI coding agent status, 30+ tools, iPhone+Watch companions), QuickBirdEng/FlippingNotch 836 (2018 iOS anim), shobhit99/SuperIsland 679 (DI w/ Extensions — Notchy says Electron?? repo says Swift), jpomykala/NotchPrompter 666 (teleprompter), jackson-storm/DynamicNotch 606, tornikegomareli/Talkify 585 (dictation), monuk7735/mew-notch 554 (HUD), MioMioOS/MioIsland 539, mrkai77/DynamicNotchKit 472 (Swift package, Apr 2026), akalikbergenov/cyclop 377 ("no permissions", zero deps: media, shelf, clipboard, snippets, calendar, offline translation, teleprompter), ericjypark/codex-island 360, xiaopu-ai/TO-DO-Panel 246 (Electron), AppGram/agentnotch 220, jazzenchen/agent-hud-native-open 196.
- dynamic-island topic extra: basionwang-bot/HermesPet 599 (AI in notch), Yudaotor/lyrimuse 296 (word-by-word lyrics incl notch), MuQY1818/OpenYoink 250 (shelf + DI, MIT), plus Windows/Linux/Android islands (WinIsland 388, Tide-island 768 Hyprland, SmartIsland Android).
- macbook-notch: zkondor/znotch 112 (hide notch), niyamvora/ILoveNotch 26, blackhole-notch (Electron), TokenCats (pixel cats collected via AI usage), xnucade/AloeNotch 11 (1.6MB, motion you can tune), ctimothe/isla-mac 9, FunNotch 7 (focus timer blocks apps), heymate 7 (push-to-talk AI sees screen), another.notch, MacNotchKiller (virtual display to kill notch safe area), gojo, tally, ledge, NotchApples (tennis & F1 scores), FileIsland (ffmpeg converter), Notchly (CN music-first).
- notch-app: aymandakirgh/ghnotch 141 (AI command bar, MIT), stevemcqueenz/claude-notch-tracker 36, Yumi 20 (AI asks before acting), OmniMac 18 (0.017–0.033% idle CPU claim), NotchLand 14, AloeNotch, bborakurt/notch-launch-animation (HTML), ababol/bnot, JUXCHXX/guino-teleprompter (mentions "MacBook Neo"!), JustNotch, aishwaryaashok14/notch-kit (agent skill for building notch apps).
- sayweer/dynamicIsland (MIT, clipboard + pomodoro).
- TREND 2026: explosion of AI-coding-agent notch apps (coucou 6.6k is now the most-starred notch repo; CodeIsland 2.5k). AI-agent status is the hottest new notch use case.
- "MacBook Neo" appears => new Apple laptop name in 2026? CHECK (does it have a notch?).

## Mac App Store notch apps found
- "Dynamic Notch Island - NotchOS" id6760346112 (free + Pro subscription, 40+ widgets: media, file staging, timers, system stats)
- "Dynamic Notch Island - Perch" id6742724228 (shelf from notch, media, calendar, timer, clipboard, file tray)
- "NotchBox - Easier Drag & Drop" id6737410946 (free + $4.99 Pro IAP, macOS 13+)
- => MAS apps DO use "Dynamic Island"-ish naming ("Dynamic Notch Island"). Need to check how they get now playing in sandbox.
- Apple Community: NotchNook, DynamicLake Pro, MediaMate, Alcove, NotchDrop, Boring Notch all outside MAS.

## CODE EVIDENCE: boring.notch (HEAD 23e7705, Oct 18 2026; 123 Swift files, ~19.6k LOC)
- Main app entitlements: app-sandbox TRUE, automation.apple-events, camera, calendars, bookmarks, user-selected rw, network client+server, temporary-exception.apple-events [com.spotify.client, com.apple.Music], temporary-exception.mach-lookup (Sparkle spks/spki).
- BUT ships BoringNotchXPCHelper with app-sandbox FALSE -> does Accessibility auth, keyboard backlight (CoreBrightness), screen brightness (DisplayServices). => MAS-incompatible (MAS requires every executable sandboxed).
- Private APIs in main app: CGSSpace (CGSSpaceCreate/SetAbsoluteLevel/AddWindowsToSpaces via @_silgen_name) for a dedicated high-level space; SkyLight dlopen SLSRemoveWindowsFromSpaces + SkyLightWindow package to show window on LOCK SCREEN; MediaRemote MRMediaRemoteSendCommand/SetElapsedTime/Shuffle/Repeat via function pointers; MediaRemoteAdapter.framework (ungive) for 15.4+.
- Media controllers: NowPlaying (MediaRemote), AppleMusic (AppleScript), Spotify (DistributedNotification "com.spotify.client.PlaybackStateChanged" + AppleScript), YouTube Music (auth+networking — likely the YTMDesktop companion API).
- MusicVisualizer = FAKE: 4 bars, Timer every 0.3s, CGFloat.random(0.35...1.0). Not audio-reactive.
- NotchShape (from DynamicNotchKit by Kai Azim): quadratic Bézier corners (top 6, bottom 14) — NOT continuous-curvature; animatable radii.
- Window: NSPanel, level .mainMenu + 3, collection [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle], canBecomeKey false, no shadow, clear bg.
- Modules: Battery live activity, Download view, InlineHUD, OpenNotchHUD, Calendar, Shelf (Models/Services/ViewModels/Views), Webcam mirror, Tabs, Onboarding (permissions), Tips, Lottie, Sparkle updater, crowdin localization.

## CODE EVIDENCE: Atoll (HEAD 166a876, Oct 28 2026; v2.3.3; 391 Swift files, ~121k LOC!!)
- Renamed from "DynamicIsland" -> "Atoll"; ships a TRADEMARKS file disclaiming Apple's "Dynamic Island" (naming risk signal).
- Entitlements: NO app-sandbox; cs.disable-library-validation; mach-services xpc; apple-events + temporary exceptions Spotify/Music/Notes; camera; calendars.
- Private/system-level: SkyLight (14 files, lock screen widgets via Lakr233/SkyLightWindow), CGS (7), DisplayServices (3), CoreBrightness (4), MediaRemote (4) + mediaremote-adapter, IOReport (2) + AppleSMC (Stats-derived CPU temp/freq), CGEventTap (2), AXIsProcessTrusted (6), OSDUIHelper suppression by launchctl bootout/bootstrap/restart of com.apple.OSDUIHelper (system HUD killer), IOBluetooth.
- REAL visualizer: Core Audio process tap (CATapDescription stereoMixdownOfProcesses + AudioHardwareCreateProcessTap + private aggregate device + vDSP); per-app volume via taps (AppVolumeTap.swift). rtaudio C++ adapted.
- Also: SwiftTerm terminal tab, LLM usage tracking (OpenUsage, OpenRouter pricing), Open-Meteo weather for lock screen, timers (Wick-inspired iOS timer), clipboard, color picker, calendar previews, gestures (two-finger swipe, horizontal media scrub w/ haptics), parallax hover, minimalistic mode inspired by Alcove.
- Requirements: macOS 14+, notched MBP only; permissions Accessibility, Camera, Calendar, Screen Recording, Music; "after granting Accessibility or Screen Recording, quit and relaunch" (UX papercut).
- Built on Boring Notch codebase (acknowledged) — GPL lineage.

## CODE EVIDENCE: NotchDrop (Lakr233) — ON MAC APP STORE (apps.apple.com/app/notchdrop/id6529528324), MIT
- HEAD e70b3d7 May 19 2026. ENABLE_APP_SANDBOX = YES, ENABLE_HARDENED_RUNTIME = YES, user-selected files rw; deployment 13.0 (+ 14.5 target). Entitlements file has new hardened-process keys (macOS 26 Enhanced Security).
- Public-API-only notch window: NSWindow level .statusBar + 8, collection [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle], clear bg, no shadow.
- Notch geometry: NSScreen.safeAreaInsets.top (height) + width = frame.width - auxiliaryTopLeftArea.width - auxiliaryTopRightArea.width; built-in display via CGDisplayIsBuiltin. Fallback 150x28 on notchless.
- Hover detection: NSEvent.addGlobalMonitorForEvents (mouse moved) + NSEvent.mouseLocation — no Accessibility needed.
- Features: drop zone shelf, AirDrop, auto-expire files (1 day), open on click. Also NotchNotification library (Lakr233) and SkyLightWindow (Lakr233) — same author provides lock-screen window lib (private).
=> PROOF: a sandboxed MAS notch app with hover + shelf + AirDrop is approved.

## MAS notch app listings (Oct 2026)
- Perch "Dynamic Notch Island - Perch" (Serkan Adıgüzel — TURKISH dev, Turkish localized), macOS 13+, 12.7MB. Free + IAP: $3.99/mo, $14.99/yr, $24.99 & $49.99 lifetime. Home (music, weather, camera, calendar), Timer, Snippets (clipboard), File Tray (zip), Quick notes, AI chat, mini player, clocks, YouTube media control (Oct 2026), full-screen support. Works w/ Spotify + Apple Music in sandbox (so AppleScript/temporary exception path is APPROVED). v1.3.8 "Fixed critical macOS 26 Tahoe issue: Apple Music now fetches song" (fragile). Reviews: "laggy after 20 min, several seconds to display", "pro upsell in the center of notch that doesn't go away — deleted immediately", "not very responsive; doesn't pop up until I paused music". Too few ratings to show average.
- NotchOS "Dynamic Notch Island - NotchOS" (Adarsh Kumar, "NotchShelf"), macOS 15+, 53.9MB, 40+ widgets, Pro $3.99 / $29.99, three visual modes, VoiceOver + keyboard nav, multi display, 17 languages incl Turkish. No ratings yet. Versions Apr–May 2026, nothing since (stale?).
- NotchDrop (MAS) — Free now, 3.4MB, macOS 13+, last update Nov 2024; reviews: confusion — stores LINKS not copies (UX expectation mismatch!); want hover-X delete instead of Option-click.
- OBSERVATION: MAS notch apps have almost no ratings => category leaders are all outside MAS; MAS segment is underserved/low quality. Opportunity + warning (MAS discovery may be weak; MAS users pay less?).
- Apple apparently tolerates "Dynamic Notch Island" names (approved), but trademark risk remains (Guideline 2.3.7/5.2.5).

## PLATFORM TIMING (verified Oct 28 2026)
- macOS 27 "Golden Gate": WWDC June 8 2026, released ~Sep 14-17 2026. APPLE SILICON ONLY (Intel dropped; incl. A-series MacBook Neo). Last release w/ general Rosetta.
  - Menu bar rewritten as single window -> broke Bartender/Ice/Hidden Bar; built-in non-configurable » overflow for icons hidden by notch; "menu bar icons can finally cross the notch" (TidBITS).
  - Adjustable Liquid Glass slider (ultra-clear -> fully tinted) in Appearance; improved contrast; "Show Borders" accessibility option.
  - Widgets update in real time when app open; extra-large desktop widgets.
  - Shortcuts: screenshot + notification triggers; natural-language shortcut builder.
  - Siri AI + "Search or Ask" Spotlight bar (Cmd-Space), switchable to ChatGPT; Visual Intelligence on Mac (Shift-Cmd-Space) => sherlocks "AI chat in notch" / "circle to search".
  - macOS 26 Tahoe already added Spotlight clipboard history (26.1 retention 30min/8h/7d) => sherlocks basic clipboard. Pasteboard privacy prompt announced (15.4 preview) but NOT enforced by default as of mid-2026 (opt-in defaults) — still a looming risk for clipboard features.
  - Touch-optimized UI in macOS 27 for touchscreen Macs.
  - TopNotch (notch-hiding) broke on 27 (screenshot call removed). No report of Boring Notch/Alcove breaking on 27 found.
- Hardware:
  - MacBook Neo (Mar 4 2026, A18 Pro, 13", NOTCHLESS, $599-ish/99,800 yen; +$100 Jun 25 2026 memory shortage). First notchless MacBook since 2022. MacBook Neo 2 H1 2027.
  - M5 Pro/Max MacBook Pro (Mar 2026), M6 14" MBP (announced Oct 27 2026, ships Nov 6; notch retained, base model only).
  - TODAY Oct 28 2026 "Pro and Tell": OLED TOUCHSCREEN MacBook Pro 14/16 (M5 Pro/Max) EXPECTED — "Apple is getting rid of the notch and will add a Dynamic Island" (Gurman/Bloomberg Feb 24 2026: hole-punch smaller than iPhone pill + software Dynamic Island UI). Rumored $2,899+. Sold alongside mini-LED models. Announcement not yet confirmed at time of research (press releases ~9am ET / 10am PT).
  => SHERLOCK RISK: Apple ships its own Dynamic Island on high-end Macs from now on. Unknown: whether macOS 27.x exposes a public Live Activities/Dynamic Island API for Mac apps.
- NotchNook (lo.cafe, Brazil) CRISIS: ownership dispute; founder Igor Marcossi removed Jul 17 2026 (his claim); Stripe payments suspended; Setapp delisted (discontinuation Sep 22); lo.cafe domain down; Homebrew cask disabled Sep 19; 3,000+ refunds issued; licenses show "Not Registered"; lo.cafe told users NOT to buy/renew; relaunch claimed Oct 7/Oct 22 ("NotchNook está de volta") but license/ownership unclear.
  => Category's former #1 paid app lost user trust. Lesson for Nimbo: licensing/infra continuity, bus factor, MAS purchase = Apple-held license (trust advantage!).
- Alcove dev warns it relies on private APIs -> could break with updates.

## MAS FEASIBILITY — primary evidence
- Apple DTS (Quinn, Apr 2025, forums thread 780626): "It IS possible for a sandboxed app to use the Input Monitoring privilege ... CGEventTap." "It's not possible for a sandboxed app to use the Accessibility privilege [without temporary exception entitlements]. DTS doesn't support folks using general accessibility APIs in sandboxed apps." DTS cannot speak for App Review.
- App Review rejected Mac apps under 2.4.5 for using Accessibility for non-accessibility purposes (thread 820594: clipboard manager posting Cmd-V via CGEvent.post rejected twice).
- media-control-relay (cbusillo) issue #122 (Sep–Oct 2026): their MAS 1.0 build ships WITHOUT volume HUD replacement; replacement needs Accessibility + active .defaultTap consuming volume keys; "a signed sandbox probe showed the active tap works technically ... does not make it acceptable to App Review"; Developer ID build keeps the feature. Closed "not planned" Oct 25 2026.
- Guideline 2.5.9: apps that alter or disable standard switches (volume, ring/silent) or native UI behaviors -> rejected. Guideline 2.4.5: MAS apps must be sandboxed, self-contained, no external helper.
- Apple Events: sandbox blocks unless scripting-targets (preferred, for apps with access groups) or temporary-exception.apple-events (carefully reviewed, often rejected; Finder/System Events almost always rejected). Perch (MAS) controls Spotify + Apple Music + YouTube => some form approved.
- Core Audio process taps (AudioHardwareCreateProcessTap, macOS 14.2+): needs NSAudioCaptureUsageDescription in Info.plist (INFOPLIST_KEY build setting silently drops it!); without it TCC silently yields silence (noErr). Sandbox: no special tap entitlement documented; AudioCap sample adds device.audio-input. => Real audio-reactive visualizer likely feasible in sandbox w/o Screen Recording (NEEDS SPIKE + review risk check).
- ScreenCaptureKit alternative for audio requires Screen Recording permission (scary prompt) — avoid.
- Lock screen widgets: require SkyLight private (SLSRemoveWindowsFromSpaces / SkyLightWindow) => IMPOSSIBLE on MAS.
- System HUD suppression: Atoll kills OSDUIHelper via launchctl => IMPOSSIBLE on MAS.
- MediaRemote (system-wide now playing for ANY app incl. browsers): private + entitlement-locked since macOS 15.4; workaround = /usr/bin/perl adapter => IMPOSSIBLE on MAS.
- NotchDrop/Perch/NotchOS/NotchBox prove: hover window + shelf + AirDrop + calendar + weather + timers + clipboard + Spotify/Music now playing CAN ship on MAS.
- Live Activities: no Mac-native ActivityKit in macOS 27; iPhone Live Activities show in Mac menu bar via Continuity (since macOS 26). WWDC26 session 223 "Live Activities essentials".

## Data source constraints
- Spotify Web API: new apps in Development Mode = max 5 allowlisted users (owner needs Premium since Feb 2026); Extended Quota since May 15 2025 only for registered businesses w/ launched service + 250k MAU => NOT viable for indie Nimbo. Spotify must be via AppleScript (temporary exception, review risk) or skipped.
- Apple Music: scripting access groups exist (com.apple.Music.playback, library.read, library.read-write) => use com.apple.security.scripting-targets (preferred, MAS-friendly). Known -10004 privilege quirks.
- WeatherKit: 500k calls/month included per developer membership (dev+prod share), paid tiers from ~$49.99/1M; attribution required. ~1 call/user/hour => only ~700 always-on users. Need aggressive caching/batching or Open-Meteo commercial plan (free tier is NON-commercial only).

## COMPLAINTS — Boring Notch GitHub (930 issues total), top by 👍 / comments (Oct 2026)
- #417 Now Playing broken after macOS 15.4 (54👍, 58 comments) + #434 dup, #554, #580 "media not detected" => MediaRemote fragility is #1 pain.
- #779 Apple Music source broke after macOS 26 (13 comments) => OS-update fragility for AppleScript paths too.
- WOBBLY ANIMATION backlash: #364 "ability to disable jiggly wobbly open/close animation" (26👍), #335 (21👍), #303 (15👍, 14 comments), #350 closing animation (21👍), #316 "closing animation jiggling and not fitted to real notch" (14 comments), #325. => Overshoot springs read as cheap; users want restraint + exact notch fit.
- #341 stuttering when opening (12👍, 15 comments) => perf of open transition.
- #336 notch crashes/disappears/doesn't reopen after long sleep (45 comments!), #352 notch out of place after lid close/reopen (11), #339 notch not going back => sleep/wake/display-reconfig robustness.
- Fullscreen/external display control: #119 disable in fullscreen & external displays (14👍), #247 disable on external, #239 hide in fullscreen for streaming, #74 choose display, #110 exclude apps.
- #592 Notifications (13👍), #351 Teleprompter (8👍), #768 NearDrop/Android share (7👍), #713 new music source (7), #797 permanently visible sneak peek (7), #690 volume slider, #1310 caffeine toggle, #206 AirPods connect indicator, #922 Liquid Glass, #943 BetterDisplay external brightness (17 comments).
- #1260 battery drain (May 2026); #720 battery status hover closes whole notch; #251 mirror fails after first use; #94 focus issues.
- Distribution pain: #855 update "improper signature", #395 update failing (Sparkle signing), #37/#281 Homebrew requests; Gatekeeper/quarantine (not notarized historically).

## COMPLAINTS — Atoll (373 issues)
- #641 Very High CPU usage (Aug 2026, 12 comments).
- #280/#299/#480 "Developer Tools access" permission popup on EVERY start/after reboot (scary, trust-eroding).
- #70 enabling HUD only changes LEFT-ear volume on Bluetooth headphones (HUD replacement breaking audio!).
- #303 live media not visible; #382 no playback controls for browser media; #309 auto-hide media when nothing playing.
- Focus mode: wrong label for Sleep (#332), custom focus generic icon/color (#216), DND logo always shown (#249) => Focus info via private hacks is unreliable.
- #304 Liquid Glass freezing (fixed via KVO windowServerAware); #491 wallpaper blank for a second after unlock (fullscreen album art lock screen hack).
- #749 shelf: files drag in but not out/open; #636 scrolling long note collapses island (gesture conflicts).
- Brew requests (#306), BetterDisplay compatibility (#147).
## COMPLAINTS — category-wide
- Battery/CPU is the #1 category complaint (Crest, OneNotch, Seam blogs). Boring Notch #338: ~5%/hour idle drain on M4 MBP; battery from full day to 3–5h (fixed Jul 2025). NotchNook: drain since launch, crashes/freezes after sleep/wake, users rolled back to 1.4.6.
- Running 2 notch apps => flicker/conflicts.
- NotchNook draws artificial notch on external displays (some dislike).

## PERFORMANCE LESSONS (OneNotch blog Jul/Sep 2026; Notchy perf page)
- OneNotch 1.1.0: 26–40% CPU while music playing (animated waveform was the single most expensive thing), Energy Impact 33.6 (idle Chrome tab 1.5), leak 14,600 objects/2h, memory spikes ~500MB w/ big clipboard. After campaign: <1% CPU playing (default waveform), live audio visualizer 6–9% CPU (opt-in), idle ~0%, 95–130MB flat 8h, 24 leaked objects/5h, ~8 idle wakeups/s. BUT 2.0 (Sep 30 2026, more features) idles 7–10% CPU / ~200MB => feature bloat regresses perf.
- Method: multi-day logger (CPU, mem, energy, wakeups every 60s), powermetrics, leak detection after 5h sessions, measure Release builds in /Applications (debug lies 5–10x), beware screen-sharing tools forcing continuous render.
- Notchy: causes = (1) polling on main thread (AX hit-test grid every 2s + sync window-server calls) -> move off-main + longer cadence; (2) animating when nobody looks (per-frame gradients, springs that never settle) -> stop decorative motion when closed or in Low Power Mode; (3) web views/Electron (SuperIsland 0.46% idle vs ~0% native); (4) disabled features must TEAR DOWN timers (not just hide UI). Low Power Mode: park decorative animation, drop TimelineView cadence, sample only when visible.
- Notchy measured idle ~0% for Notchy, Alcove, NotchNook (M2, macOS 26.5, May 2026).
=> Nimbo perf budget proposal: idle (closed, no media) ≈0% CPU & <1 wakeup/s; music playing collapsed <1%; open+animating short bursts only; real visualizer opt-in ≤5%; memory <120MB flat; Energy Impact single digits; CI perf regression gate.

## DESIGN — Apple HIG Live Activities (page updated Oct 13 2026), verbatim-derived rules
- Presentations: Compact (leading+trailing around camera, single activity), Minimal (up to 3 activities: one attached + detached circle/oval bubbles), Expanded (touch&hold / alert), Lock Screen, StandBy.
- "Live Activities in the Dynamic Island use a black opaque background. Consider using bold colors for text and objects to convey personality." Background color NOT customizable in island; key line around island in dark mode tinted to match content.
- "Use consistent margins and concentric placement ... use ContainerRelativeShape to match the corner radius instead of hard-coding." Don't draw content to the edge; separate blocks with inset container shape or thick line. Tip: blur content in drawing tool to align to rounded perimeter.
- Text: "Use large, heavier-weight text — a medium weight or higher. Use small text sparingly."
- Compact: unified info across leading/trailing, consistent color & typography, snug against camera, NO padding between content and camera, balanced widths (shortened units).
- Expanded: "Wrap content tightly around the TrueDepth camera" to diminish the camera's presence; maintain relative placement between presentations (expanded = enlarged compact).
- Dynamic height: shrink/grow to content.
- Animations: system + custom max 2 seconds; numeric content transitions for score/time; animate existing elements to new positions rather than remove/re-add; avoid overlapping elements (fade others).
- Interactivity: single essential element preferred (music playback etc.).
- Don't use for ads/promotions. Avoid sensitive info (redact; configurable).
- Alert only for essential updates; end immediately when task ends; single activity that rotates through events preferred over many.
- Dimensions (iOS, pt): compact leading/trailing 62.33x36.67 (430w) / 52.33x36.67 (393w); minimal 36.67–45 x 36.67; expanded 408x84–160 / 371x84–160; limited width 28x28. Lock screen margin 14pt. "macOS dimensions: use the provided iOS dimensions."
- macOS: iPhone Live Activities appear in Mac menu bar (compact/minimal/expanded); click opens iPhone Mirroring.
## DESIGN — motion references
- Metaball/gooey split: blur + alpha threshold (Compose AGSL; SVG feGaussianBlur+feColorMatrix). SwiftUI equivalent: Canvas + GraphicsContext filters .alphaThreshold + .blur (native!).
- Springs: recreation used stiffness 450 / damping 28; Compose bubble damping 0.35. Observer (xezrunner, slow-mo): iOS 16 island "breathes"; iOS 17/18 springiness "very exaggerated", blobs inconsistent => even Apple regressed; restraint reads premium.
- Apple uses continuous-curvature squircles (3rd-party claim). Boring Notch uses quadratic Bézier (curvature discontinuity).
- Liquid Glass SwiftUI (macOS 26+): glassEffect(_:in:), GlassEffectContainer (group + morph), glassEffectID(_:in:) with namespace, .glass/.glassProminent button styles. macOS 27 adds user Liquid Glass transparency slider => app must look right from ultra-clear to fully tinted.

## NAME CHECK "Nimbo" (iTunes Search API, Oct 28 2026)
- Mac App Store: "NIMBO" by NIMBO SP. Z O.O. (Poland) — Graphics & Design, universal iPhone/iPad/Mac (macOS 13+), balloon/event decoration designer w/ AI, v1.0.1 released Oct 19 2026 (9 days ago!), PRO subscription. => exact App Store name "Nimbo" is TAKEN (App Store Connect app names must be unique).
- iOS: "NIMBO" (Igor Shalamov, Food & Drink), "Nimbo World: Kids Learning" (Muammer Mahir Uslu — Turkish dev), "Nimbo: Your Child's Diary", "Nimbo: Habit Tracker", "NimboChat" (medical), "Nimboo", "Nimbio".
- TURKEY: company "NIMBO YAZILIM VE BILGISAYAR TEKNOLOJILERI LIMITED SIRKETI" has an App Store app "Nimbo Yazılım" (Business) => potential TÜRKPATENT trademark conflict in software class 9/42. MUST run TÜRKPATENT + EUIPO + USPTO + WIPO search before branding spend.
- Workaround: store name like "Nimbo — Notch Companion"/"Nimbo Island" (unique), keep "Nimbo" as brand if trademark clear.
- Etymology: Latin nimbus = rain cloud AND luminous halo around a deity; Spanish/Portuguese/Italian "nimbo" = nimbus cloud/halo. Brand story candidate: "the halo around your notch".

## Coucou (Louis-CFM, 6.6k★ — MOST-STARRED notch repo, MIT code; name/Mochi/sounds © author)
- Character "Mochi": soft squircle w/ big eyes pops out of notch, waves, eyes follow cursor (eyes on a sphere), annoyed when poked, dizzy if insisted, idle breathing + blinks, emotes, 28 handcrafted sounds (user-replaceable), wardrobe + seasonal outfits, dances when music plays, happy jump when agent finishes, can be dragged onto desktop (120pt companion), "invisible when idle".
- Function: AI coding agent sessions live (Claude Code, Cursor, Codex, Gemini CLI, ...), Allow/Deny/Always + AskUserQuestion in notch, jump to terminal, chat with many LLMs (BYO key/local), integrations (GitHub, Vercel, Stripe, n8n, Notion, Cal.com, Resend) each w/ colored Mochi, crypto portfolio pill, Claude/Codex plan usage pills, Apple Music & Spotify pills, "OK Coucou" voice assistant, dictation (Parakeet offline), call notetaker, weekly recap shareable 1080x1920 image, 14 languages incl Turkish.
- Cross-device: when Mac locks, Mochi moves to iPhone Lock Screen + Dynamic Island (Live Activity) via CloudKit private DB; approve with Face ID; Android companion; Windows/Linux versions.
- Positioning line: "Some studios showed off gorgeous notch companions… and never let anyone use them. Coucou is the open version."
=> LESSON: personality/character + emotional design drives virality more than feature count. Cross-device continuity (iPhone Live Activity) is a moat.
## SuperIsland (shobhit99, 679★)
- Extensions = JavaScript packages in sandboxed JavaScriptCore (bundled: pomodoro, whatsapp-web); Energy modes Normal/Smart/Low Power (Smart reduces refresh when collapsed; Low Power pauses inactive extension timers); animation intensity + reduced motion settings; Now Playing incl opt-in Chromium browser media detection; perms: Accessibility, Calendar, Location; XcodeGen; notarized DMG + Homebrew.
## Extensibility patterns seen: SuperIsland JS extensions; Notchy local HTTP API (127.0.0.1:9999 token-signed JSON -> custom live activities/notifications); Coucou hook payload tag; MacNotch/Notchy Claude Code hooks.
=> MAS-compatible Nimbo extensibility: App Intents (Shortcuts actions "Show activity in Nimbo", "Update progress", "End"), URL scheme, local network server entitlement (network.server, as Boring Notch has), CLI via URL scheme. macOS 27 Shortcuts triggers (notification/screenshot) make this powerful.
- CONFIRMED (Apple docs): GraphicsContext.Filter.alphaThreshold(min:max:color:) + .blur(radius:) exist since macOS 12 => native SwiftUI Canvas metaballs (gooey split/merge) possible without Metal; also .layerShader/.colorShader/.distortionShader for custom Metal [[stitchable]] effects.
- Kyle Howells (Aug 2026) metaball morph: mix -> separable Gaussian blur (H then V) -> smoothstep threshold; blur amount = sin(easedProgress*pi) (max blob mid-transition); MTKView PAUSED when idle, unpaused only during animation (0.06ms CPU, 0.2ms GPU/frame). => Pattern for Nimbo's split/merge: render-on-demand only.
- Alcove reception: MacStories "excellent notch utility with beautiful animations"; SlashGear "cannot recommend enough" but pricey $13.99; HUD "more natural than native"; criticism: fun visuals but weaker for productivity (vs NotchNook); dev had a pause due to family issues (bus factor). 48h trial.

## CODE EVIDENCE: cyclop (377★, "no permissions" claim)
- Not sandboxed (entitlements only apple-events + calendars, no app-sandbox). Now Playing via MediaRemote helper hosted in /usr/bin/perl (Sources/CyclopMediaHelper/helper.m) + AppleScript fallback for Spotify/Music + DistributedNotificationCenter (com.spotify.client.PlaybackStateChanged, com.apple.Music.playerInfo) + postMediaKey. => "No permissions" is marketing; Automation prompts still appear.
=> EVERY notable open-source "now playing for any app" notch app relies on the perl/MediaRemote workaround (Boring Notch, Atoll, DynamicNotch, cyclop) — none MAS-compatible.

## USER'S SAPPHIRE SCREENSHOT — design critique (Oct 28 11:30, Tuzla)
- Wide black slab (~1030pt) not centered on the notch (extends far left), 4 equal-weight modules side by side (music | weather | calendar | clipboard) => no hierarchy, "widget board" not an island.
- ~10 tab icons in a top row (settings, inbox, window, clipboard, AI sparkle, moon, + mirror/caffeine/pin) => icon soup, low discoverability.
- Data inconsistency: notch weather says 16° while menu bar weather says 17°C; wind shown in mph for a Turkish-locale user (should be km/h) => trust-eroding.
- Truncation everywhere: "Cumhuriyet Bayramı (Y…", "Dynamic Island/Notch Ma…", "find ~ -type f -mtime -2 \…".
- Tiny secondary text (~9–10pt), multi-color weekday letters (S red, S purple, M blue big, T, WED) => visual noise; date "28" and "26" styles collide.
- Positives worth keeping: big album art, large temperature numeral (good glanceability), event "All-Day" alignment.

## More MAS feasibility facts
- Notchmeister (Iconfactory): FREE, SANDBOXED, on MAS, open source; notch effects Glow, Cylon, Plasma Leak, Festive, Nano Radar triggered by cursor under notch; "Notch Simulation Mode" on notchless => Apple approves pure notch art.
- TopNotch = MakeTheWeb (pl.maketheweb.TopNotch) black menu bar to hide notch; broke on macOS 27.
- AirPods battery: IOBluetoothDevice exposes battery props; Apple DR: IOKit public API OK for MAS but only header-defined properties are API => risk; MAS precedent "Battery Stats for AirPods". Case level often missing on macOS.
- Focus: INFocusStatusCenter (macOS 12+) gives only isFocused (no mode name), needs Focus Status usage string + Communication Notifications capability; KVO unreliable -> poll. Atoll's private focus name hacks produce wrong labels.
