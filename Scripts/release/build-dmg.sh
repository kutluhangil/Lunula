#!/usr/bin/env bash
# Builds Lunula (Release) and packages it into build/Lunula-<version>.dmg.
# Usage: Scripts/release/build-dmg.sh [--sign "Developer ID Application: Name (TEAMID)"]
# Without --sign the app is ad-hoc signed (local testing only; Gatekeeper will reject it).
set -euo pipefail
cd "$(dirname "$0")/../.."

identity="-"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign) identity="$2"; shift 2 ;;
        *) echo "usage: $0 [--sign IDENTITY]" >&2; exit 64 ;;
    esac
done

version=$(awk '/MARKETING_VERSION:/ {print $2; exit}' project.yml)
[[ -f Lunula.xcodeproj/project.pbxproj ]] || Scripts/bootstrap.sh

xcodebuild -project Lunula.xcodeproj -scheme Lunula -configuration Release -derivedDataPath build \
    CODE_SIGN_IDENTITY=- build -quiet
app=build/Build/Products/Release/Lunula.app

if [[ "$identity" != "-" ]]; then
    # Hardened runtime + secure timestamp; no --deep (nested code is signed by the build, outermost last).
    codesign --force --options runtime --timestamp --entitlements App/Lunula.entitlements --sign "$identity" "$app"
    codesign --verify --strict --verbose=2 "$app"
fi

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"
dmg="build/Lunula-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "Lunula" -srcfolder "$staging" -fs HFS+ -format UDZO "$dmg" -quiet
[[ "$identity" != "-" ]] && codesign --force --timestamp --sign "$identity" "$dmg"
echo "$dmg"
