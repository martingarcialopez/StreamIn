#!/usr/bin/env bash
# Tests for review-verdict.sh: every way a verdict can come out.
#   bash .github/scripts/review-verdict-test.sh

set -euo pipefail

script="$(dirname "$0")/review-verdict.sh"
dir="$(mktemp -d)"
trap 'rm -r "$dir"' EXIT

failures=0
expect() { # name, file, override, state, title fragment[, skip reason]
  local out state title
  out=$("$script" "$dir/$2" "$3" "${6:-}")
  state=$(jq -r .state <<<"$out")
  title=$(jq -r .title <<<"$out")
  if [[ "$state" == "$4" && "$title" == *"$5"* ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1: got $state / $title"
    failures=$((failures + 1))
  fi
}

cat > "$dir/high.json" <<'EOF'
{"new": [{"severity": "high", "title": "Feature imports TMDBClient", "where": "Package.swift:21"},
         {"severity": "medium", "title": "Fixed font size", "where": "WatchlistView.swift:27"}],
 "still_open": [{"thread_id": "T1", "severity": "low", "title": "Typo", "where": "A.swift:3"}],
 "resolved": [{"thread_id": "T0", "title": "Old thing"}],
 "checked_against": ["CLAUDE.md"]}
EOF
cat > "$dir/critical.json" <<'EOF'
{"new": [{"severity": "critical", "title": "Secret committed", "where": "Config.swift:1"}], "still_open": [], "resolved": []}
EOF
cat > "$dir/still-open-high.json" <<'EOF'
{"new": [], "still_open": [{"thread_id": "T1", "severity": "high", "title": "Failing test", "where": "T.swift:15"}], "resolved": []}
EOF
cat > "$dir/medium.json" <<'EOF'
{"new": [], "still_open": [{"thread_id": "T1", "severity": "medium", "title": "Hard-coded English", "where": "W.swift:29"}],
 "resolved": [{"thread_id": "T2", "title": "TMDBClient import"}]}
EOF
cat > "$dir/low.json" <<'EOF'
{"new": [{"severity": "low", "title": "Nit", "where": "X.swift:1"}], "still_open": [], "resolved": []}
EOF
echo '{"new": [], "still_open": [], "resolved": []}' > "$dir/none.json"
echo '{"new": [{"severity": "urgent", "title": "x"}], "still_open": []}' > "$dir/bad-severity.json"
echo '{"new": [{"severity": "high", "title": "x"}]}' > "$dir/no-still-open.json"
echo 'not json' > "$dir/garbage.json"

expect "high blocks"                      high.json            false failure "fix before merging"
expect "high with override passes"        high.json            true  success "overridden"
expect "critical blocks"                  critical.json        false failure "1 critical"
expect "a still-open high still blocks"   still-open-high.json false failure "fix before merging"
expect "medium passes, and says so"       medium.json          false success "merge at your discretion"
expect "override doesn't change medium"   medium.json          true  success "merge at your discretion"
expect "low only passes"                  low.json             false success "Ready to merge"
expect "nothing passes"                   none.json            false success "no findings"
expect "unknown severity fails"           bad-severity.json    false failure "didn't finish"
expect "missing field fails"              no-still-open.json   false failure "didn't finish"
expect "malformed JSON fails"             garbage.json         false failure "didn't finish"
expect "missing file fails"               missing.json         false failure "didn't finish"
expect "missing file is overridable"      missing.json         true  success "No finished review, overridden"
expect "workflow change says so"          missing.json         false failure "can't review itself" workflow-change
expect "workflow change is overridable"   missing.json         true  success "overridden"           workflow-change

# A status's description holds at most 140 characters, so long titles are cut.
for case in "high.json false" "missing.json false" "missing.json false workflow-change" "none.json true"; do
  read -r file override reason <<<"$case"
  out=$("$script" "$dir/$file" "$override" "${reason:-}")
  if jq -e '(.description | length) <= 140 and (.description | length) > 0' <<<"$out" >/dev/null; then
    echo "ok   description fits: $case"
  else
    echo "FAIL description too long or empty: $case"
    failures=$((failures + 1))
  fi
done

# GitHub rejects a status whose description holds a 4-byte character (#69),
# like the 🔴🟠🟡 severity dots in the title.
for case in "high.json false" "high.json true" "critical.json false" "medium.json false" "low.json false" "none.json false" "missing.json true"; do
  read -r file override <<<"$case"
  out=$("$script" "$dir/$file" "$override")
  if jq -e '(.description | explode | all(. < 65536)) and (.description | test("  ") | not)' <<<"$out" >/dev/null; then
    echo "ok   description has no 4-byte characters: $case ($(jq -r .description <<<"$out"))"
  else
    echo "FAIL description holds a 4-byte character or a double space: $case ($(jq -r .description <<<"$out"))"
    failures=$((failures + 1))
  fi
done

if (( failures > 0 )); then
  echo "$failures failing"
  exit 1
fi
echo "all passed"
