#!/usr/bin/env bash
# Publishes PR screenshots to the pr-screenshots branch and prints their URLs.
#
#   scripts/publish-screenshots.sh <folder> <png>...
#
# GitHub has no API to attach an image to a PR description, so the
# pr-screenshots skill pushes the images to an orphan branch, pr-screenshots,
# and the description embeds them by raw URL. The commit is built with git
# plumbing on a temporary index: this checkout, its branch and its index are
# never touched. Each PR writes only its own folder (its branch name), so when
# another session pushed first, the commit is rebuilt on top of theirs.
#
# Images are scaled to at most 800 px, about twice the 180 px the description
# shows them at. Prints "<png>\t<url>" per image. The URLs name the commit, so
# publishing again never changes what an older PR shows.

set -euo pipefail

branch=pr-screenshots
usage="usage: scripts/publish-screenshots.sh <folder> <png>..."

folder=${1:?$usage}
shift
(( $# > 0 )) || { echo "$usage" >&2; exit 64; }
[[ "$folder" =~ ^[A-Za-z0-9._/-]+$ && "$folder" != /* && "$folder" != *..* ]] ||
  { echo "Folder must be a relative path of letters, digits, '.', '_', '-' and '/': $folder" >&2; exit 64; }

repo=$(git remote get-url origin | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

sources=("$@")
names=()
for png in "${sources[@]}"; do
  name=$(basename "$png")
  [[ "$name" =~ ^[A-Za-z0-9._-]+\.png$ ]] ||
    { echo "Expected a PNG named with letters, digits, '.', '_' and '-': $png" >&2; exit 65; }
  [[ ! -e "$work/$name" ]] || { echo "Two images named $name" >&2; exit 65; }
  sips -Z 800 "$png" --out "$work/$name" >/dev/null
  names+=("$name")
done

for attempt in 1 2 3; do
  parent=()
  export GIT_INDEX_FILE="$work/index"
  rm -f "$GIT_INDEX_FILE"
  if git ls-remote --exit-code --heads origin "$branch" >/dev/null; then
    git fetch --quiet origin "+refs/heads/$branch:refs/remotes/origin/$branch"
    parent=(-p "$(git rev-parse "refs/remotes/origin/$branch")")
    git read-tree "${parent[1]}"
  else
    git read-tree --empty
  fi

  for name in "${names[@]}"; do
    blob=$(git hash-object -w "$work/$name")
    git update-index --add --cacheinfo "100644,$blob,$folder/$name"
  done
  tree=$(git write-tree)
  unset GIT_INDEX_FILE

  # ${parent[@]+…}: macOS's bash 3.2 calls an empty array unbound under set -u.
  sha=$(git commit-tree "$tree" ${parent[@]+"${parent[@]}"} -m "📸 Screenshots for $folder")
  if git push --quiet origin "$sha:refs/heads/$branch" 2>"$work/push.log"; then
    for i in "${!names[@]}"; do
      printf '%s\t%s\n' "${sources[$i]}" "https://raw.githubusercontent.com/$repo/$sha/$folder/${names[$i]}"
    done
    exit 0
  fi
  echo "Push $attempt failed; rebuilding on the latest $branch…" >&2
done

cat "$work/push.log" >&2
exit 1
