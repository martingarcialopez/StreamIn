#!/usr/bin/env bash
# Translation review: the app's strings to a spreadsheet and back.
#
#   scripts/translations.sh export [--force]      # scripts/streamin-translations.numbers
#   scripts/translations.sh import [--dry-run]
#   scripts/translations.sh preview <StreamIn.app>  # what translator-preview.sh runs
#   scripts/translations.sh test
#
# Runs scripts/translations/translations.py in its own venv, created on first
# use with the pinned openpyxl (requirements.txt); `export --help` and
# `import --help` list the other options. docs/translations.md has the whole
# loop, from export to seeing the new copy in the simulator.

set -euo pipefail

dir="$(cd "$(dirname "$0")/translations" && pwd)"
venv="$dir/.venv"

# The venv keeps a copy of the requirements it was built from, so a new pin
# reinstalls.
if [[ ! -x "$venv/bin/python3" ]] || ! cmp -s "$dir/requirements.txt" "$venv/requirements.txt"; then
  echo "Setting up the translations venv (openpyxl)…" >&2
  python3 -m venv "$venv"
  "$venv/bin/pip" install --quiet --disable-pip-version-check -r "$dir/requirements.txt"
  cp "$dir/requirements.txt" "$venv/requirements.txt"
fi

if [[ "${1:-}" == "test" ]]; then
  exec "$venv/bin/python3" -m unittest discover -s "$dir" -p "test_*.py" -v
fi
exec "$venv/bin/python3" "$dir/translations.py" "$@"
