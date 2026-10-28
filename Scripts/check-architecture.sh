#!/usr/bin/env bash
# Mechanical guard for the architecture rules in CLAUDE.md. Prints "file:line: rule" per violation.
set -euo pipefail
cd "$(dirname "$0")/.."

violations=0
report() { echo "$1"; violations=$((violations + 1)); }

# Prints "file:line:text" for every match of an extended regex in the given paths (Swift files only).
scan() {
    local pattern=$1; shift
    grep -rnE --include='*.swift' "$pattern" "$@" 2>/dev/null || true
}

# 1. IslandCore imports only Foundation and Observation; its test-support target may also import IslandCore.
while IFS=: read -r file line text; do
    module=$(sed -E 's/^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+((struct|class|enum|protocol|func|var|let|typealias)[[:space:]]+)?([A-Za-z_]+).*/\4/' <<<"$text")
    [[ $module == Foundation || $module == Observation ]] && continue
    [[ $module == IslandCore && $file == Packages/IslandCore/Sources/IslandCoreTestSupport/* ]] && continue
    # Swift 6.4 hides CGRect's conformances behind CoreGraphics; Linux gets them from Foundation, so only a
    # canImport-guarded CoreGraphics import is allowed.
    if [[ $module == CoreGraphics ]] && sed -n "$((line - 1))p" "$file" | grep -qE '^[[:space:]]*#if canImport\(CoreGraphics\)'; then
        continue
    fi
    report "$file:$line: IslandCore may only import Foundation/Observation"
done < <(scan '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]' Packages/IslandCore/Sources)

# 2. IslandFeatures never imports IslandServices.
while IFS=: read -r file line _; do
    report "$file:$line: IslandFeatures may not import IslandServices"
done < <(scan '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+IslandServices\b' Packages/IslandFeatures/Sources)

# 3. IslandServices never imports SwiftUI.
while IFS=: read -r file line _; do
    report "$file:$line: IslandServices may not import SwiftUI"
done < <(scan '^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+SwiftUI\b' Packages/IslandServices/Sources)

# 4. Forbidden private APIs and process/accessibility escapes.
forbidden='MediaRemote|SkyLight|\bSLS[A-Z]|\bCGS[A-Z][A-Za-z]*\(|DisplayServices|CoreBrightness|\bdlopen\b|\bdlsym\b|AXIsProcessTrusted|AXUIElement|CGEventPost|CGEvent\.post|\bNSTask\b|Process\(\)|/usr/bin/|sharingType'
while IFS=: read -r file line text; do
    symbol=$(grep -oE "$forbidden" <<<"$text" | head -1)
    report "$file:$line: forbidden symbol $symbol"
done < <(scan "$forbidden" App Packages/*/Sources)

# 5. No synchronous hops onto the main queue.
while IFS=: read -r file line _; do
    report "$file:$line: DispatchQueue.main.sync is forbidden"
done < <(scan 'DispatchQueue\.main\.sync\b' App/Sources Packages/*/Sources)

if ((violations > 0)); then
    exit 1
fi
echo "architecture OK"
