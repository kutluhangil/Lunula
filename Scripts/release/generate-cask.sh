#!/usr/bin/env bash
# Generates a Homebrew Cask definition (Casks/lunula.rb) for a GitHub Release DMG.
# Usage: Scripts/release/generate-cask.sh --version 0.1.0 --tag v0.1.0-rc1 --sha256 <hex> [--output Casks/lunula.rb]
set -euo pipefail

version=""
tag=""
sha256=""
output="Casks/lunula.rb"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) version="$2"; shift 2 ;;
        --tag) tag="$2"; shift 2 ;;
        --sha256) sha256="$2"; shift 2 ;;
        --output) output="$2"; shift 2 ;;
        *) echo "usage: $0 --version VERSION --tag TAG --sha256 SHA256 [--output PATH]" >&2; exit 64 ;;
    esac
done

[[ -n "$version" && -n "$tag" && -n "$sha256" ]] || {
    echo "error: --version, --tag, and --sha256 are required" >&2
    exit 64
}

mkdir -p "$(dirname "$output")"
cat >"$output" <<EOF
cask "lunula" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/kutluhangil/Lunula/releases/download/$tag/Lunula-#{version}.dmg",
      verified: "github.com/kutluhangil/Lunula/"
  name "Lunula"
  desc "Native, sandboxed macOS notch island for media, timers, calendar, shelf, and tools"
  homepage "https://github.com/kutluhangil/Lunula"

  depends_on macos: ">= :tahoe"

  app "Lunula.app"

  zap trash: [
    "~/Library/Containers/com.kutluhangul.lunula",
    "~/Library/Preferences/com.kutluhangul.lunula.plist",
  ]
end
EOF

if command -v ruby >/dev/null 2>&1; then
    ruby -c "$output" >/dev/null
fi
echo "$output"
