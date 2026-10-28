#!/usr/bin/env bash
# Fails unless the signed app has App Sandbox and Hardened Runtime. Usage: check-entitlements.sh <path/to/Lunula.app>
set -euo pipefail

app=${1:?usage: check-entitlements.sh <path/to/App.app>}

# plutil treats "." as a key-path separator, so the dots in the key are escaped.
sandbox=$(codesign -d --entitlements - --xml "$app" 2>/dev/null |
    plutil -extract 'com\.apple\.security\.app-sandbox' raw - 2>/dev/null || true)
if [[ $sandbox != true ]]; then
    echo "entitlements FAIL: App Sandbox is not enabled in $app" >&2
    exit 1
fi
# Captured first: piping into `grep -q` under pipefail fails when codesign gets SIGPIPE.
signature=$(codesign -dv "$app" 2>&1 || true)
if ! grep -q 'flags=.*runtime' <<<"$signature"; then
    echo "entitlements FAIL: Hardened Runtime is not enabled in $app" >&2
    exit 1
fi
echo "entitlements OK (sandbox, hardened runtime)"
