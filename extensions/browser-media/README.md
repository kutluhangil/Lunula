# Lunula Browser Media Bridge

Show what's playing in **YouTube**, **YouTube Music**, **SoundCloud**, **Twitch**, and **Spotify Web** right inside the Lunula notch island — including album artwork, dominant accent halo, progress bar, and LRCLIB synced lyrics — with zero private APIs and zero background polling.

## Chrome / Brave / Arc / Edge

1. Open `chrome://extensions` (or `arc://extensions` / `brave://extensions`).
2. Enable **Developer mode**.
3. Click **Load unpacked** and select `extensions/browser-media/`.
4. Open a YouTube or YouTube Music tab and press Play; confirm the browser prompt once to allow opening `lunula://` links.

## Safari (macOS)

Convert the Manifest V3 folder into a Safari Web Extension project using Apple's built-in tool:

```bash
xcrun safari-web-extension-converter extensions/browser-media --macos-only --no-open
```

## Direct `lunula://` URL API

You can also drive browser media from any userscript, Shortcut, or shell script:

```bash
# Update browser Now Playing
open -g "lunula://media/update?title=Bohemian%20Rhapsody&artist=Queen&playing=1&duration=354&position=42&artwork=https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg"

# Clear browser Now Playing
open -g "lunula://media/clear"
```

Only `https://` artwork URLs are accepted; all other schemes are ignored.
