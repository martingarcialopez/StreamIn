#!/usr/bin/env bash
# Opens StreamIn in the simulator in one language, for the translation review.
#
#   scripts/translations/translator-preview.sh <en|es> [--onboarding] [--build]
#
# The app shows the edits in streamin-translations.numbers, next to this
# script, saved or still on screen in Numbers, without touching the String
# Catalogs: they go into a copy of the built app (translations.sh preview). The
# workbook comes from `scripts/translations/translations.sh export`.
#
# The app is built only on the first run (through xcodebuild-locked.sh, so it
# queues behind other sessions' builds); later runs reuse that build. The copy
# is installed on this checkout's simulator and launched with its UI and TMDB
# content in that language, for this launch only.
#
#   --onboarding  start from the first-launch onboarding (no services picked)
#   --build       build again, after the code or the catalogs changed

set -euo pipefail

usage() { echo "Usage: $0 <en|es> [--onboarding] [--build]" >&2; exit 64; }

language=""
onboarding=false
force_build=false
for arg in "$@"; do
  case "$arg" in
    en|es) language=$arg ;;
    --onboarding) onboarding=true ;;
    --build) force_build=true ;;
    *) usage ;;
  esac
done
case "$language" in
  en) locale=en_US; content=en-US ;;
  es) locale=es_ES; content=es-ES ;;
  *) usage ;;
esac

cd "$(dirname "$0")/../.."

workbook=scripts/translations/streamin-translations.numbers
if [[ ! -f "$workbook" ]]; then
  echo "Error: no $workbook. Create it with: scripts/translations/translations.sh export" >&2
  exit 1
fi

derived=build/translator-preview
app="$derived/Build/Products/Debug-iphonesimulator/StreamIn.app"
simulator=$(scripts/worktree-simulator.sh)

if $force_build || [[ ! -d "$app" ]]; then
  echo "Building StreamIn for \"$simulator\"…" >&2
  scripts/xcodebuild-locked.sh build -quiet \
    -project StreamIn.xcodeproj -scheme StreamIn -configuration Debug \
    -derivedDataPath "$derived" \
    -destination "platform=iOS Simulator,name=$simulator,OS=latest"
fi

installed="$derived/Preview/StreamIn.app"
rm -rf "$installed"
mkdir -p "$(dirname "$installed")"
cp -R "$app" "$installed"
scripts/translations/translations.sh preview "$installed" "$workbook"

xcrun simctl boot "$simulator" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$simulator" -b >/dev/null
xcrun simctl install "$simulator" "$installed"

bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$installed/Info.plist")
# The locale's region is the default Region until one is picked in Settings.
launch_args=(-AppleLanguages "($language)" -AppleLocale "$locale" -settings.language.code "$content")
# Onboarding shows while no service is picked (until Phase 6's
# hasCompletedOnboarding flag replaces that trigger).
if $onboarding; then
  launch_args+=(-settings.subscribedProviders.ids none)
fi
xcrun simctl launch --terminate-running-process "$simulator" "$bundle_id" "${launch_args[@]}" >/dev/null
echo "StreamIn is open in \"$simulator\", in $language, with the edits in $workbook."
