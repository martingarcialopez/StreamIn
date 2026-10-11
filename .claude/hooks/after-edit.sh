#!/bin/bash
# PostToolUse(Edit|Write|MultiEdit): keep derived files in sync and catch a
# broken Xcode project immediately. Exit 2 reports the problem to Claude.

file=$(jq -r '.tool_input.file_path // empty')

# Both checks need Apple tooling. On Linux (Claude in GitHub Actions) skip them
# rather than failing every edit.
command -v xcrun >/dev/null 2>&1 || exit 0

case "$file" in
    */Packages/*/Translations/Localizable.xcstrings)
        # Xcode regenerates symbols only for app-target catalogs; package
        # catalogs need xcstringstool, or `Text(.newKey)` won't compile.
        if ! output=$(xcrun xcstringstool generate-symbols "$file" \
                --output-directory "$(dirname "$file")" --language swift 2>&1); then
            printf 'Regenerating string symbols failed for %s:\n%s\n' "$file" "$output" >&2
            exit 2
        fi ;;
    */project.pbxproj)
        if ! output=$(plutil -lint "$file" 2>&1); then
            printf 'project.pbxproj is no longer valid; fix it before continuing:\n%s\n' "$output" >&2
            exit 2
        fi ;;
esac
exit 0
