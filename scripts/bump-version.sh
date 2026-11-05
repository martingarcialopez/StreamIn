#!/usr/bin/env bash
# Sets the app's version (MARKETING_VERSION) in every target, for an App Store release.
#
#   scripts/bump-version.sh patch | minor | major | X.Y.Z
#
# Run it once per release, in the release PR, not per merge: patch for fixes,
# minor for features. The build number (CURRENT_PROJECT_VERSION) stays put: Xcode
# raises it at upload ("Manage Version and Build Number" when distributing).

set -euo pipefail

usage() { echo "usage: $0 patch | minor | major | X.Y.Z" >&2; exit 1; }

project="$(git rev-parse --show-toplevel)/StreamIn.xcodeproj/project.pbxproj"
current=$(grep -m1 -oE 'MARKETING_VERSION = [0-9]+(\.[0-9]+)*;' "$project" | grep -oE '[0-9.]+[0-9]|[0-9]') \
  || { echo "no numeric MARKETING_VERSION in $project" >&2; exit 1; }
IFS=. read -r major minor patch <<< "$current"
major=${major:-0} minor=${minor:-0} patch=${patch:-0}

case "${1:-}" in
  patch) next="$major.$minor.$((patch + 1))" ;;
  minor) next="$major.$((minor + 1)).0" ;;
  major) next="$((major + 1)).0.0" ;;
  *) [[ "${1:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && next="$1" || usage ;;
esac

# perl rather than sed -i, which differs between macOS and Linux (claude[bot]).
perl -pi -e "s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $next;/" "$project"
echo "$current → $next ($(grep -c "MARKETING_VERSION = $next;" "$project") build configurations)"
