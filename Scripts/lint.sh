#!/usr/bin/env bash
# Format check with the toolchain's swift-format; prints nothing and exits 0 when clean.
set -euo pipefail
cd "$(dirname "$0")/.."

swift format lint --strict --recursive App Packages
