#!/usr/bin/env bash
# Turns the PR review's findings into the "ios-reviewer verdict" commit status.
#
#   review-verdict.sh <verdict.json> <override: true|false> [skip reason]
#
# Prints the status's JSON fields: state, title, description (the title, cut to
# a status's 140 characters) and summary (the review run's job summary).
# The model writes verdict.json; this script, not the model, decides what it
# means for merging:
#
#   any critical or high   → failure (merge blocked; success with the override label)
#   worst is medium        → success, "🟠 … merge at your discretion"
#   only low, or nothing   → success
#
# A status, not a check run: a check run created through the API joins whatever
# check suite GitHub picks, and when that suite's workflow run is superseded
# (a draft PR marked ready runs the review twice on one commit) GitHub hides it,
# so the required check stays "Expected" (#59). A status has no neutral, so
# medium findings pass in green and say so in the description.
#
# A missing or malformed verdict.json is a failure: a review that didn't finish
# must not read as a pass. The override label still applies, so a PR whose
# review can't run (one that changes the review workflow) can be merged on
# purpose. The skip reason `workflow-change` says that's what happened.
#
# verdict.json, as the review prompt asks for it:
#   {
#     "new":        [{"severity": "high", "title": "…", "where": "File.swift:21"}],
#     "still_open": [{"thread_id": "PRRT_…", "severity": "medium", "title": "…", "where": "…"}],
#     "resolved":   [{"thread_id": "PRRT_…", "title": "…"}],
#     "checked_against": ["CLAUDE.md", "…"]
#   }
#
# The review workflow keeps verdict.json as an artifact, so adding or removing
# the override label can re-evaluate the verdict without running the review again.

set -euo pipefail

verdict_file="${1:?usage: review-verdict.sh <verdict.json> <override: true|false> [skip reason]}"
override="${2:-false}"
skip_reason="${3:-}"

# A status's description holds at most 140 characters.
describe() {
  jq '.description = (if (.title | length) > 140 then .title[:139] + "…" else .title end)'
}

no_verdict() {
  local title summary
  if [[ "$override" == "true" ]]; then
    jq -n '{state: "success",
            title: "⚠️ No finished review, overridden with review-override",
            summary: "There is no review for this commit, and the `review-override` label lets it merge anyway. The next push removes the label."}' \
      | describe
    return
  fi
  if [[ "$skip_reason" == "workflow-change" ]]; then
    title="This PR changes the review workflow, which can't review itself: add review-override to merge"
    summary="GitHub only runs the review workflow when it matches the one on \`main\`, so a PR that changes it gets no review. Review it yourself, then add the \`review-override\` label to merge."
  else
    title="Review didn't finish: comment \"@claude review\" to retry"
    summary="The review produced no valid findings file, so there is no verdict for this commit. Check the log of the \`run review\` job, then comment \`@claude review\` on the PR."
  fi
  jq -n --arg title "$title" --arg summary "$summary" \
    '{state: "failure", title: $title, summary: $summary}' | describe
}

if [[ ! -s "$verdict_file" ]] || ! jq -e '
    (.new | type == "array") and (.still_open | type == "array") and
    ([.new[], .still_open[]] | all(.severity as $s | ["critical", "high", "medium", "low"] | index($s)))
  ' "$verdict_file" >/dev/null 2>&1; then
  no_verdict
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
  | .state = (if .blocking > 0 and ($override | not) then "failure" else "success" end)
  | .title = (
        if .blocking > 0 and $override then "⚠️ \(.blocking) blocking finding(s) overridden with review-override · \(.counts)"
        elif .blocking > 0 then "\(.counts): fix before merging"
        elif .medium > 0 then "\(.counts): merge at your discretion"
        elif .low > 0 then "✅ Ready to merge · \(.counts)"
        else "✅ Ready to merge: no findings" end)
  | .rows = (.open | map("| \(.severity | icon) | \(.title) | `\(.where // "")` |") | join("\n"))
  | .resolved_rows = ($v.resolved // [] | map("- ✅ \(.title)") | join("\n"))
  | {
      state,
      title,
      summary: ([
          "**\(.title)**",
          (if (.open | length) > 0 then "\n| | Open finding | Where |\n|---|---|---|\n\(.rows)" else empty end),
          (if .resolved_rows != "" then "\n**Fixed since the last review**\n\(.resolved_rows)" else empty end),
          (if ($v.checked_against // [] | length) > 0 then "\n<details><summary>Checked against</summary>\n\n\($v.checked_against | join(" · "))\n</details>" else empty end),
          "\nCritical and high findings block the merge; add the `review-override` label to merge anyway. The next push removes the label."
        ] | join("\n"))
    }
' "$verdict_file" | describe
