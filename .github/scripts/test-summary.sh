#!/bin/bash
# Prints a Markdown summary of an .xcresult bundle: one row per package test
# bundle, then every failing test with its message. CI appends it to the job
# summary; run it locally on any result bundle the same way.
#
#   .github/scripts/test-summary.sh path/to/TestResults.xcresult

set -euo pipefail
results="${1:?usage: test-summary.sh <path.xcresult>}"

tests=$(xcrun xcresulttool get test-results tests --path "$results" --compact)
summary=$(xcrun xcresulttool get test-results summary --path "$results" --compact)

jq -r '
  "### \(if .result == "Passed" then "✅" else "❌" end) \(.passedTests) passed, \(.failedTests) failed, \(.skippedTests) skipped",
  "",
  "On \(.devicesAndConfigurations[0].device.deviceName // "?"), iOS \(.devicesAndConfigurations[0].device.osVersion // "?")",
  ""
' <<<"$summary"

jq -r '
  def cases: [.. | objects | select(.nodeType == "Test Case")];
  "| Package tests | Passed | Failed |",
  "|---|---:|---:|",
  (.testNodes[].children[]
    | select(.nodeType == "Unit test bundle")
    | (cases) as $c
    | "| \(.name) | \($c | map(select(.result == "Passed")) | length) | \($c | map(select(.result == "Failed")) | length) |")
' <<<"$tests"

failures=$(jq -r '
  [.. | objects | select(.nodeType == "Test Case" and .result == "Failed")]
  | .[]
  | "- `\(.nodeIdentifier)`: \([.children[]? | select(.nodeType == "Failure Message") | .name] | join(" / "))"
' <<<"$tests")

if [[ -n "$failures" ]]; then
    printf '\n#### Failures\n\n%s\n' "$failures"
fi
