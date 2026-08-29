# Homebrew cask for WrapScribe — a template, not an installable cask.
#
# It lives here rather than in the tap so it is versioned alongside the app.
# Publishing is automated: scripts/release.sh fills the `version` and `sha256`
# placeholders below from the DMG it just uploaded and pushes the result to
# shrix1/homebrew-tap as `Casks/wrapscribe.rb`, on every release.
#
# That step is deliberately allowed to fail without failing the release — the
# cask is derived metadata, and the app is already published by the time it
# runs. When it does fail the script prints the manual fallback, which is the
# same thing by hand:
#
#     shasum -a 256 WrapScribe-<version>.dmg
#     sed -e "s/1.8.2/<version>/" -e "s/1af4944995e7a6223a8c53d51b8b63d52459e1c7e250c15045771ba59aff47e1/<digest>/" \
#       packaging/homebrew/wrapscribe.rb > ../homebrew-tap/Casks/wrapscribe.rb
#
# docs/RELEASING.md §5 has the whole sequence.
#
# Not submitted to the official homebrew-cask: that tap requires a project to
# be "notable" (roughly 75+ stars or 30+ forks) and would close the PR
# otherwise. A personal tap has no such rule and is installed with:
#
#     brew tap shrix1/tap
#     brew install --cask wrapscribe
cask "wrapscribe" do
  # Placeholders, filled in at publish time. Deliberately not `version :latest`
  # / `sha256 :no_check`: the URL below is versioned because releases never
  # publish a rolling "latest.dmg" — a cask pins a sha256 against a URL, so
  # content changing under a stable name would break verification for everyone.
  version "1.8.2"
  sha256 "1af4944995e7a6223a8c53d51b8b63d52459e1c7e250c15045771ba59aff47e1"

  # R2, not the GitHub release asset and not wrapscribe.com: the repository is
  # private so its release assets are not publicly downloadable, and the DMG is
  # published to this bucket by scripts/release.sh.
  url "https://pub-c32d9a0988724edea2fd65c2ef924228.r2.dev/WrapScribe-#{version}.dmg"
  name "WrapScribe"
  # Not "On-device dictation for macOS": `brew style` rejects a desc that names
  # the platform, and every cask in the tap is a Mac app anyway.
  desc "On-device dictation"
  homepage "https://wrapscribe.com/"

  # The app auto-updates itself (Settings → General → Check for Updates), so
  # Homebrew must not also try to manage versions or the two will fight.
  auto_updates true
  # No blank line above: `brew style` (Cask/StanzaGrouping) keeps auto_updates
  # and depends_on in one group.
  #
  # The core binary uses macOS 26-only APIs (SpeechAnalyzer, Foundation
  # Models). The bundle's launcher deploys back to 13 purely so older systems
  # get a readable alert instead of a Launch Services error, which is not a
  # reason to let Homebrew install it there.
  #
  # Deliberate style deviation: `brew style` suggests the bare `:tahoe` symbol,
  # but that form means *exactly* macOS 26 and would refuse to install on 27.
  depends_on macos: ">= :tahoe"

  app "WrapScribe.app"

  # Quit the running copy before Homebrew replaces or removes the bundle.
  # Without this, `brew upgrade` swaps the app out from under a live process
  # that keeps owning the global hotkeys and the menu-bar icon — while the
  # bundle its Accessibility grant was keyed to no longer exists on disk, so
  # the zombie loses the grant: the app looks like the old version, Settings
  # reports the new one, and pasting stops working.
  uninstall quit: "com.wrapscribe.app"

  # Everything the app creates. `zap` is what `brew uninstall --zap` removes;
  # a plain uninstall deliberately leaves preferences and downloaded models
  # alone so reinstalling does not mean re-downloading ~500 MB.
  zap trash: [
    "~/Library/Application Support/WrapScribe",
    "~/Library/Caches/com.wrapscribe.app",
    "~/Library/HTTPStorages/com.wrapscribe.app",
    "~/Library/Preferences/com.wrapscribe.app.plist",
  ]
end
