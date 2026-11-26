# Changelog

## 0.1.0 (unreleased)

First public build.

- Notch island: closed / compact / peek / expanded, pill mode without a notch, per-display windows, fullscreen hiding, sleep/wake and display changes, full-width black menu-bar strip to hide the notch, customizable expanded width (`520–600 pt`), customizable pill vertical offset, configurable hover-to-peek and swipe gestures.
- Ada design system ("Obsidyen ve Işık"): opaque `#000000` island core, inset cards with optional Liquid Glass highlight, animated Core Animation halo, metaball detached bubbles, custom Lunula app icon.
- Now Playing (Apple Music; Spotify behind `LUNULA_SPOTIFY`), artwork accent halo, controls, inline player volume slider (without touching system HUD), seeking, shuffle/repeat/favorite, two-line synced lyrics (LRCLIB).
- Timer, configurable Pomodoro durations with 7-day focus streak chart (recording actual focus minutes, excluding breaks), drift-free stopwatch, optional animated timer mascots, relaunch and sleep persistence.
- Calendar: next event, full-day schedule agenda popover & upcoming preview, 10-minute countdown and Join button (Zoom, Meet, Teams, FaceTime, Webex).
- Weather (Open-Meteo) with automatic location or manual city search and daylight halo.
- Shelf: drag-and-drop, AirDrop, sharing, drag magnet, offline image converter (PNG/JPEG/HEIC/TIFF/PDF), native ZIP/AppleArchive compress & extract, Vision OCR text copy, clipboard screenshot staging.
- Quick tools: Keep Awake (Caffeine), microphone mute & audio output switcher, color eyedropper, quick notes (with pinning), zero-polling clipboard history & text snippets, search/math/command palette, teleprompter, system stats & wireless battery levels, external drive eject, app launcher (with add/remove) & Shortcuts runner, opt-in two-way Apple Reminders (`EventKit`) sync with local checklist fallback, stocks watchlist, detached menu bar popover, keyboard cleaning lock & keystroke HUD.
- Signals: battery (configurable 80–100% full-charge threshold), event-driven Bluetooth & external audio connect alerts with matched wireless battery level, download alerts (opt-in), camera/microphone privacy dots, Call Island, Caps Lock HUD, double-tap Option (⌥) island toggle.
- Automation: `lunula://` URLs (activities, timer, toggle, AI usage, agent approvals), App Intents, Shortcuts, and ready-to-use Claude Code & Codex hook scripts (`examples/hooks/`).
- Settings & onboarding: 680 × 540 five-tab Settings window with live preview stage, customizable & reorderable expanded toolbar, permission center, manual weather city picker; 420 × 320 one-screen onboarding with zero startup permission prompts.
- Full Turkish and English localization across app and packages; VoiceOver labels; Reduce Motion / Transparency / Increase Contrast.
