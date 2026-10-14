#!/bin/bash
# One-time setup after cloning: creates the two gitignored secrets files the
# build needs and enables the repository's git hooks. Safe to run again; it
# never overwrites existing files.
#
# - Secrets.xcconfig: copied from the template. Put your TMDB key in it.
# - StreamIn/Secrets/GeneratedSecrets.swift: a placeholder. The "Generate
#   Secrets" build phase rewrites it with the key on every build, but Xcode
#   decides which files to compile before that phase runs, so the file must
#   already exist or the first build fails with "cannot find 'GeneratedSecrets'".

set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f Secrets.xcconfig ]]; then
    cp Secrets.example.xcconfig Secrets.xcconfig
    echo "Created Secrets.xcconfig: replace the placeholder with your TMDB API key."
fi

generated=StreamIn/Secrets/GeneratedSecrets.swift
if [[ ! -f "$generated" ]]; then
    cat > "$generated" <<'EOF'
// Auto-generated at build time. DO NOT EDIT. DO NOT COMMIT.
enum GeneratedSecrets {
    static let tmdbAPIKey = "your_tmdb_api_key_here"
}
EOF
    echo "Created $generated (the build fills in the key)."
fi

# The repository's git hooks (.githooks/pre-commit: no commits on main).
# Shared by every worktree of this clone.
if [[ "$(git config --get core.hooksPath || true)" != ".githooks" ]]; then
    git config core.hooksPath .githooks
    echo "Enabled the repository's git hooks (.githooks)."
fi
