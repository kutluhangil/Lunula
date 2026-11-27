(() => {
  const MIN_INTERVAL_MS = 1500;
  let lastKey = "";
  let lastSentAt = 0;

  function pickArtwork(metadata) {
    if (!metadata || !Array.isArray(metadata.artwork) || metadata.artwork.length === 0) return "";
    const httpsItems = metadata.artwork.filter((a) => typeof a?.src === "string" && a.src.startsWith("https://"));
    if (httpsItems.length === 0) return "";
    return httpsItems[httpsItems.length - 1].src;
  }

  function findActiveMedia() {
    const els = Array.from(document.querySelectorAll("video, audio"));
    return els.find((el) => !el.paused && el.readyState >= 2) || els[0] || null;
  }

  function dispatchLunula(url) {
    const link = document.createElement("a");
    link.href = url;
    link.style.display = "none";
    document.body.appendChild(link);
    link.click();
    link.remove();
  }

  function sendUpdate(force = false) {
    const media = findActiveMedia();
    const meta = navigator.mediaSession?.metadata;
    const title = (meta?.title || document.title.replace(/ - YouTube( Music)?$/, "") || "").trim();
    if (!media || !title) return;

    const artist = (meta?.artist || location.hostname.replace(/^www\./, "")).trim();
    const album = (meta?.album || "").trim();
    const isPlaying = !media.paused && !media.ended;
    const duration = Number.isFinite(media.duration) && media.duration > 0 ? Math.floor(media.duration) : "";
    const position = Number.isFinite(media.currentTime) && media.currentTime >= 0 ? Math.floor(media.currentTime) : 0;
    const artwork = pickArtwork(meta);

    const key = `${title}|${artist}|${isPlaying ? 1 : 0}|${duration}`;
    const now = Date.now();
    if (!force && key === lastKey && now - lastSentAt < MIN_INTERVAL_MS) return;
    if (!force && now - lastSentAt < MIN_INTERVAL_MS && key.split("|")[0] === lastKey.split("|")[0]) return;

    lastKey = key;
    lastSentAt = now;

    const params = new URLSearchParams({
      title,
      artist,
      playing: isPlaying ? "1" : "0",
      position: String(position),
    });
    if (album) params.set("album", album);
    if (duration !== "") params.set("duration", String(duration));
    if (artwork) params.set("artwork", artwork);

    dispatchLunula(`lunula://media/update?${params.toString()}`);
  }

  function bindMedia(el) {
    if (el.dataset.lunulaBound === "1") return;
    el.dataset.lunulaBound = "1";
    for (const evt of ["play", "pause", "loadedmetadata", "seeked"]) {
      el.addEventListener(evt, () => sendUpdate(evt === "play" || evt === "pause"), { passive: true });
    }
    el.addEventListener("ended", () => sendUpdate(true), { passive: true });
  }

  const observer = new MutationObserver(() => {
    document.querySelectorAll("video, audio").forEach(bindMedia);
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
  document.querySelectorAll("video, audio").forEach(bindMedia);

  window.addEventListener("beforeunload", () => {
    if (lastKey) dispatchLunula("lunula://media/clear");
  });
})();
