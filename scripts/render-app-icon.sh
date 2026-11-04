#!/bin/bash
# Renders StreamIn's Icon Composer document in every iOS 26 appearance, for
# checking the design without a device and for the PR's screenshots.
#
#   scripts/render-app-icon.sh [icon-document] [output-directory] [size]
#
# Defaults: StreamIn/Resources/AppIcon.icon, $TMPDIR/streamin-app-icon, 1024 px.
# Renders stay out of the repo: the .icon document is the source.
set -euo pipefail

# The selected Xcode's, so a versioned or beta install works too.
ictool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
icon="${1:-StreamIn/Resources/AppIcon.icon}"
out="${2:-${TMPDIR:-/tmp}/streamin-app-icon}"
size="${3:-1024}"

mkdir -p "$out"
for rendition in Default Dark TintedLight TintedDark ClearLight ClearDark; do
  "$ictool" "$icon" --export-image \
    --output-file "$out/$rendition.png" \
    --platform iOS --rendition "$rendition" \
    --width "$size" --height "$size" --scale 1
done
echo "Rendered to $out"
