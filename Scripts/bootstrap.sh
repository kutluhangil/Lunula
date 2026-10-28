#!/usr/bin/env bash
# Installs xcodegen if missing, seeds Signing.xcconfig and generates Lunula.xcodeproj.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || brew install xcodegen
[[ -f Config/Signing.xcconfig ]] || cp Config/Signing.xcconfig.example Config/Signing.xcconfig
xcodegen generate
