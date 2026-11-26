#!/usr/bin/env bash
# Forward OpenAI Codex notify events to Lunula via the `lunula://` URL scheme (`open -g`, no focus steal).
# Usage in ~/.codex/config.toml:
#   notify = ["/path/to/Lunula/examples/hooks/codex-lunula.sh"]
set -euo pipefail

if [[ "${1:-}" == "--end" ]]; then
    open -g "lunula://activity/end?id=codex-task" >/dev/null 2>&1 || true
    exit 0
fi

PAYLOAD="${1:-}"
if [[ -z "$PAYLOAD" && ! -t 0 ]]; then
    PAYLOAD="$(cat || true)"
fi

URL="$(
    PAYLOAD="$PAYLOAD" python3 - <<'PY'
import json
import os
import urllib.parse

raw = os.environ.get("PAYLOAD", "").strip()
try:
    data = json.loads(raw) if raw else {}
except Exception:
    data = {}

event_type = str(data.get("type") or "agent-turn-complete")
last_message = str(data.get("last-assistant-message") or data.get("message") or "").strip().splitlines()
summary = last_message[0].strip() if last_message else event_type

params = urllib.parse.urlencode({
    "id": "codex-task",
    "title": "Codex",
    "subtitle": summary[:100],
    "symbol": "terminal.fill",
    "accent": "32D74B",
    "duration": "25",
})
print(f"lunula://activity/show?{params}")
PY
)"

if [[ -n "$URL" ]]; then
    open -g "$URL" >/dev/null 2>&1 || true
fi
