#!/usr/bin/env bash
# Notarizes and staples a signed DMG, then checks it with Gatekeeper.
# Usage: Scripts/release/notarize.sh build/Lunula-<version>.dmg
# Credentials, one of:
#   NOTARY_PROFILE=lunula-notary                      (created with `xcrun notarytool store-credentials`)
#   APPSTORE_CONNECT_KEY_ID, APPSTORE_CONNECT_ISSUER_ID, APPSTORE_CONNECT_KEY_PATH (.p8 file)
set -euo pipefail
dmg="${1:?usage: $0 path/to/Lunula.dmg}"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    auth=(--keychain-profile "$NOTARY_PROFILE")
else
    : "${APPSTORE_CONNECT_KEY_ID:?missing}" "${APPSTORE_CONNECT_ISSUER_ID:?missing}" "${APPSTORE_CONNECT_KEY_PATH:?missing}"
    auth=(--key "$APPSTORE_CONNECT_KEY_PATH" --key-id "$APPSTORE_CONNECT_KEY_ID" --issuer "$APPSTORE_CONNECT_ISSUER_ID")
fi

xcrun notarytool submit "$dmg" "${auth[@]}" --wait
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl -a -vv -t open --context context:primary-signature "$dmg"
