#!/usr/bin/env bash
# Turns the PR review's findings into the "ios-reviewer verdict" check.
#
#   review-verdict.sh <verdict.json> <override: true|false>
#
# Prints the check run's JSON fields: conclusion, title, summary, text.
# The model writes verdict.json; this script, not the model, decides what it
# means for merging:
#
#   any critical or high   → failure (merge blocked; neutral with the override label)
#   worst is medium        → neutral (mergeable)
#   only low, or nothing   → success
#
# A missing or malformed verdict.json is a failure: a review that didn't finish
# must not read as a pass.
#
# verdict.json, as the review prompt asks for it:
#   {
#     "new":        [{"severity": "high", "title": "…", "where": "File.swift:21"}],
#     "still_open": [{"thread_id": "PRRT_…", "severity": "medium", "title": "…", "where": "…"}],
#     "resolved":   [{"thread_id": "PRRT_…", "title": "…"}],
#     "checked_against": ["CLAUDE.md", "…"]
#   }
#
# `text` carries verdict.json itself, so adding or removing the override label
# can re-evaluate the verdict without running the review again.

set -euo pipefail

verdict_file="${1:?usage: review-verdict.sh <verdict.json> <override: true|false>}"
override="${2:-false}"

failure() {
  jq -n --arg title "$1" --arg summary "$2" \
    '{conclusion: "failure", title: $title, summary: $summary, text: ""}'
}

if [[ ! -s "$verdict_file" ]] || ! jq -e '
    (.new | type == "array") and (.still_open | type == "array") and
    ([.new[], .still_open[]] | all(.severity as $s | ["critical", "high", "medium", "low"] | index($s)))
  ' "$verdict_file" >/dev/null 2>&1; then
  failure "Review didn't finish: comment \"@claude review\" to retry" \
    "The review produced no valid findings file, so there is no verdict for this commit. Check the \`claude-review\` job's log, then comment \`@claude review\` on the PR."
  exit 0
fi

jq --argjson override "$override" '
  def icon: {critical: "🔴", high: "🔴", medium: "🟠", low: "🟡"}[.];
  def count($s): [.open[] | select(.severity == $s)] | length;
  def plural($n; $word): "\($n) \($word)";

  . as $v
  | {open: ([.new[], .still_open[]] | sort_by({critical: 0, high: 1, medium: 2, low: 3}[.severity]))}
  | .critical = count("critical") | .high = count("high")
  | .medium = count("medium") | .low = count("low")
  | .blocking = .critical + .high
  | .counts = ([
        (if .critical > 0 then "🔴 \(.critical) critical" else empty end),
        (if .high > 0 then "🔴 \(.high) high" else empty end),
        (if .medium > 0 then "🟠 \(.medium) medium" else empty end),
        (if .low > 0 then "🟡 \(.low) low" else empty end)
      ] | join(" · "))
  | .conclusion = (
        if .blocking > 0 then (if $override then "neutral" else "failure" end)
        elif .medium > 0 then "neutral"
        else "success" end)
  | .title = (
        if .blocking > 0 and $override then "⚠️ \(.blocking) blocking finding(s) overridden with review-override · \(.counts)"
        elif .blocking > 0 then "\(.counts): fix before merging"
        elif .medium > 0 then "\(.counts): merge at your discretion"
        elif .low > 0 then "✅ Ready to merge · \(.counts)"
        else "✅ Ready to merge: no findings" end)
  | .rows = (.open | map("| \(.severity | icon) | \(.title) | `\(.where // "")` |") | join("\n"))
  | .resolved_rows = ($v.resolved // [] | map("- ✅ \(.title)") | join("\n"))
  | {
      conclusion,
      title,
      summary: ([
          "**\(.title)**",
          (if (.open | length) > 0 then "\n| | Open finding | Where |\n|---|---|---|\n\(.rows)" else empty end),
          (if .resolved_rows != "" then "\n**Fixed since the last review**\n\(.resolved_rows)" else empty end),
          (if ($v.checked_against // [] | length) > 0 then "\n<details><summary>Checked against</summary>\n\n\($v.checked_against | join(" · "))\n</details>" else empty end),
          "\nCritical and high findings block the merge; add the `review-override` label to merge anyway. The next push removes the label."
        ] | join("\n")),
      text: ($v | tojson)
    }
' "$verdict_file"
