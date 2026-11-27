cask "lunula" do
  version "0.1.0"
  sha256 :no_check # Replaced automatically with the notarized DMG SHA-256 on tagged releases

  url "https://github.com/kutluhangil/Lunula/releases/download/v#{version}/Lunula-#{version}.dmg",
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
