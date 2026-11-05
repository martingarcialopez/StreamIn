#!/usr/bin/env bash
# The App Store screenshots, and the README's, from one UI test on live TMDB data.
#
#   scripts/store-screenshots.sh [--readme] [--demo] [--device iphone|ipad] [--language en|es]
#
# Runs StreamInUITests/StoreScreenshotTests (Screenshots.xctestplan) on freshly
# erased simulators with a 9:41 status bar, once per device and language:
#
#   iPhone 17 Pro Max → 1320 × 2868 (App Store's 6.9")
#   iPad Pro 13-inch  → 2064 × 2752 (App Store's 13")
#
# and writes build/store-screenshots/<iphone|ipad>/<en|es>/NN-name.png (gitignored;
# upload 01–06 to App Store Connect from there; 90- shots are for the README).
# en is the UK, es is Spain.
#
#   --readme  also copies the iPhone/en set to docs/screenshots/, 460 px wide.
#   --demo    also records testDemoTour on the iPhone (en) and turns it into
#             docs/screenshots/demo.gif with scripts/make-demo-gif.swift.
#
# Needs a real TMDB key in Secrets.xcconfig. Each checkout gets its own two
# simulators, "StreamIn Store iPhone 6.9 <folder>" and "StreamIn Store iPad 13
# <folder>", because the script erases them.

set -euo pipefail
cd "$(dirname "$0")/.."

readme=false
demo=false
devices=(iphone ipad)
languages=(en es)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --readme) readme=true ;;
    --demo) demo=true ;;
    --device) devices=("$2"); shift ;;
    --language) languages=("$2"); shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ ($readme == true || $demo == true) &&
      !(" ${devices[*]} " == *" iphone "* && " ${languages[*]} " == *" en "*) ]]; then
  echo "--readme and --demo need the iPhone/en set in the same run." >&2
  exit 2
fi

if grep -q "your_tmdb_api_key_here" Secrets.xcconfig 2>/dev/null || [[ ! -f Secrets.xcconfig ]]; then
  echo "Secrets.xcconfig has no TMDB key; the tour needs live data." >&2
  exit 1
fi

out=build/store-screenshots
work=build/store-screenshots-work
derived=build/store-screenshots-derived
rm -rf "$work"
mkdir -p "$out" "$work"

checkout=$(basename "$PWD")
device_name() { [[ $1 == iphone ]] && echo "StreamIn Store iPhone 6.9 $checkout" || echo "StreamIn Store iPad 13 $checkout"; }
device_type() {
  [[ $1 == iphone ]] && echo com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max \
    || echo com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB
}
device_size() { [[ $1 == iphone ]] && echo "1320 2868" || echo "2064 2752"; }

runtime=$(xcrun simctl list runtimes -j | jq -r '
  [.runtimes[] | select(.platform == "iOS" and .isAvailable)]
  | sort_by(.version | split(".") | map(tonumber)) | last | .identifier')

# Creates the device if needed, erases it, boots it and fixes the status bar.
# Prints its UDID.
prepare_simulator() {
  local name udid
  name=$(device_name "$1")
  udid=$(xcrun simctl list devices -j | jq -r --arg n "$name" \
    '[.devices[][] | select(.name == $n and .isAvailable)] | first | .udid // empty')
  if [[ -z "$udid" ]]; then
    udid=$(xcrun simctl create "$name" "$(device_type "$1")" "$runtime")
    echo "Created simulator \"$name\"." >&2
  fi
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid"
  # A US locale, so the status bar reads 9:41 rather than a 24-hour 09:41.
  # The app's own language and region come from the test's launch arguments.
  # On iPad, "Full Screen Apps" rather than windowed ones, whose resize grabber
  # would sit in the corner of every shot.
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" >/dev/null
  xcrun simctl spawn "$udid" defaults write -g AppleLocale en_US
  xcrun simctl spawn "$udid" defaults write -g AppleICUForce24HourTime -bool false
  xcrun simctl spawn "$udid" defaults write com.apple.springboard SBMedusaMultitaskingEnabled -bool false
  xcrun simctl shutdown "$udid"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" >/dev/null
  xcrun simctl status_bar "$udid" override --time 9:41 \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --operatorName "" \
    --batteryState discharging --batteryLevel 100
  echo "$udid"
}

echo "Building for testing…" >&2
scripts/xcodebuild-locked.sh build-for-testing -quiet \
  -project StreamIn.xcodeproj -scheme StreamIn -testPlan Screenshots \
  -destination "generic/platform=iOS Simulator" -derivedDataPath "$derived"

# Runs one test of the tour on a simulator. $1 device UDID, $2 language,
# $3 test name, $4 result bundle.
run_tour() {
  TEST_RUNNER_STREAMIN_SHOTS_LANGUAGE="$2" scripts/xcodebuild-locked.sh test-without-building -quiet \
    -project StreamIn.xcodeproj -scheme StreamIn -testPlan Screenshots \
    -destination "id=$1" -derivedDataPath "$derived" \
    -only-testing "StreamInUITests/StoreScreenshotTests/$3" \
    -resultBundlePath "$4"
}

for device in "${devices[@]}"; do
  udid=$(prepare_simulator "$device")
  read -r width height <<<"$(device_size "$device")"
  for language in "${languages[@]}"; do
    echo "Capturing ${device} / ${language}…" >&2
    bundle="$work/$device-$language.xcresult"
    run_tour "$udid" "$language" testStoreTour "$bundle"

    attachments="$work/$device-$language"
    xcrun xcresulttool export attachments --path "$bundle" --output-path "$attachments"
    target="$out/$device/$language"
    rm -rf "$target"
    mkdir -p "$target"
    # Attachment "01-landing" → 01-landing.png; XCTest's own attachments are skipped.
    jq -r '.[].attachments[]
      | select((.exportedFileName | endswith(".png")) and (.suggestedHumanReadableName | test("^[0-9]{2}-")))
      | "\(.exportedFileName)\t\(.suggestedHumanReadableName)"' \
      "$attachments/manifest.json" | while IFS=$'\t' read -r file name; do
      cp "$attachments/$file" "$target/${name%%_*}.png"
    done

    for png in "$target"/*.png; do
      size=$(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixel/ { printf "%s ", $2 }')
      if [[ "$size" != "$width $height " ]]; then
        echo "$png is ${size% }, expected $width $height." >&2
        exit 1
      fi
    done
    echo "  $(ls "$target" | wc -l | tr -d ' ') shots in $target" >&2
  done

  if [[ "$device" == iphone && "$demo" == true ]]; then
    echo "Recording the demo…" >&2
    video="$work/demo.mov"
    xcrun simctl io "$udid" recordVideo --codec h264 --force "$video" &
    recorder=$!
    sleep 2
    status=0
    run_tour "$udid" en testDemoTour "$work/demo.xcresult" || status=$?
    kill -INT "$recorder"
    wait "$recorder" || true
    [[ $status -eq 0 ]] || exit "$status"
    swift scripts/make-demo-gif.swift "$video" docs/screenshots/demo.gif
  fi
  xcrun simctl shutdown "$udid"
done

if [[ "$readme" == true ]]; then
  # README name ← shot name
  readme_shots=(
    "landing-slot-machine:01-landing"
    "search-results:02-results"
    "details-watch-now:03-watch-now"
    "details-abroad:04-abroad"
    "watchlist:05-watchlist"
    "onboarding-services:06-services"
    "details-read-a-book:90-read-a-book"
  )
  for pair in "${readme_shots[@]}"; do
    sips --resampleWidth 460 "$out/iphone/en/${pair#*:}.png" \
      --out "docs/screenshots/${pair%%:*}.png" >/dev/null
  done
  echo "README screenshots updated in docs/screenshots/." >&2
fi

echo "Done: $out" >&2
