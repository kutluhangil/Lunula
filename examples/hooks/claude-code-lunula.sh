#!/usr/bin/env bash
# Forward Claude Code hook events to Lunula via the sandbox-safe `lunula://` URL scheme.
# Uses `open -g` so Lunula updates the island without stealing keyboard focus from your terminal.
set -euo pipefail

PAYLOAD="$(cat || true)"

URL="$(
    PAYLOAD="$PAYLOAD" python3 - <<'PY'
import json
import os
import re
import urllib.parse

raw = os.environ.get("PAYLOAD", "").strip()
try:
    data = json.loads(raw) if raw else {}
except Exception:
    data = {}

event = str(data.get("hook_event_name") or data.get("event") or "PreToolUse")
session = re.sub(r"[^A-Za-z0-9._-]", "", str(data.get("session_id") or "default"))[:24] or "default"
activity_id = f"claude-{session}"
tool = str(data.get("tool_name") or "").strip()
message = str(data.get("message") or "").strip()
cwd = os.path.basename(str(data.get("cwd") or "").rstrip("/"))

if event in ("Stop", "SessionEnd"):
    print(f"lunula://activity/end?id={urllib.parse.quote(activity_id)}")
elif event in ("Notification", "PermissionRequest"):
    summary = message or (f"Approve {tool}" if tool else "Needs input")
    params = urllib.parse.urlencode({
        "id": f"{activity_id}-approval",
        "agent": "Claude Code",
        "command": summary[:100],
    })
    print(f"lunula://agent/approval?{params}")
else:
    subtitle = tool or cwd or "Working"
    if event == "PostToolUse" and tool:
        subtitle = f"{tool} completed"
    params = urllib.parse.urlencode({
        "id": activity_id,
        "title": "Claude Code",
        "subtitle": subtitle[:100],
        "symbol": "sparkles",
        "accent": "D97757",
        "duration": "180",
    })
    print(f"lunula://activity/show?{params}")
PY
)"

if [[ -n "$URL" ]]; then
    open -g "$URL" >/dev/null 2>&1 || true
fi
