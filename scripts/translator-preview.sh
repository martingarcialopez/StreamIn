#!/usr/bin/env bash
# Opens StreamIn in the simulator in one language, for the translation review.
#
#   scripts/translator-preview.sh <en|es> [--onboarding] [--no-build]
#
# Builds the app (through xcodebuild-locked.sh, so it queues behind other
# sessions' builds), boots this checkout's simulator, opens the Simulator app
# and launches StreamIn with its UI and TMDB content in that language — the
# same pair the in-app language picker sets, for this launch only.
#
#   --onboarding  start from the first-launch onboarding (no services picked)
#   --no-build    relaunch the last build, e.g. to switch language quickly
#
# After `scripts/translations.sh import`, run it again to see the new copy.

set -euo pipefail
cd "$(dirname "$0")/.."

usage() { echo "Usage: $0 <en|es> [--onboarding] [--no-build]" >&2; exit 64; }

case "${1:-}" in
  en) ui=en; locale=en_US; content=en-US ;;
  es) ui=es; locale=es_ES; content=es-ES ;;
  *) usage ;;
esac
shift

onboarding=false
build=true
for arg in "$@"; do
  case "$arg" in
    --onboarding) onboarding=true ;;
    --no-build) build=false ;;
    *) usage ;;
  esac
done

derived=build/translator-preview
app="$derived/Build/Products/Debug-iphonesimulator/StreamIn.app"
simulator=$(scripts/worktree-simulator.sh)

if $build; then
  echo "Building StreamIn for \"$simulator\"…" >&2
  scripts/xcodebuild-locked.sh build -quiet \
    -project StreamIn.xcodeproj -scheme StreamIn -configuration Debug \
    -derivedDataPath "$derived" \
    -destination "platform=iOS Simulator,name=$simulator,OS=latest"
elif [[ ! -d "$app" ]]; then
  echo "No build at $app yet; run without --no-build first." >&2
  exit 1
fi

xcrun simctl boot "$simulator" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$simulator" -b >/dev/null
xcrun simctl install "$simulator" "$app"

bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Info.plist")
# The locale's region is the default Region until one is picked in Settings.
launch_args=(-AppleLanguages "($ui)" -AppleLocale "$locale" -settings.language.code "$content")
# Onboarding shows while no service is picked (until Phase 6's
# hasCompletedOnboarding flag replaces that trigger).
if $onboarding; then
  launch_args+=(-settings.subscribedProviders.ids none)
fi
xcrun simctl launch --terminate-running-process "$simulator" "$bundle_id" "${launch_args[@]}" >/dev/null
echo "StreamIn is open in \"$simulator\", in $ui."
