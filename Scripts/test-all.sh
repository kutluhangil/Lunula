#!/usr/bin/env bash
# Runs every package's tests, then the app-hosted tests.
set -euo pipefail
cd "$(dirname "$0")/.."

for p in IslandCore IslandDesign IslandServices IslandFeatures; do
    swift test --package-path "Packages/$p"
done
xcodebuild test -project Lunula.xcodeproj -scheme Lunula -destination 'platform=macOS' -quiet
