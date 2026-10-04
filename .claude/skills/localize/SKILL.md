---
name: localize
description: Add or update a user-facing string in a StreamIn package's String Catalog with every supported language (en, es) and regenerated Swift symbols. Use whenever UI text is added or its copy changes.
argument-hint: <Package> <key>
---

# Localize a string

StreamIn localizes per package: each package with UI owns
`Sources/<Package>/Translations/Localizable.xcstrings` plus a committed
`GeneratedStringSymbols_Localizable.swift`. Xcode doesn't regenerate symbols
for package catalogs, so `Text(.newKey)` won't compile until the generator
runs. The bundled script edits the catalog and regenerates symbols in one step.

## Steps

1. **Pick the package** whose view shows the string.
2. **Name the key** in lowerCamelCase with the feature prefix used in that catalog
   (`details…`, `search…`, `settings…`, `watchlist…`, `error…`). Grep the catalog
   first: reuse an existing key if the meaning is the same.
3. **Write the copy.** English first, then natural Spain Spanish (`tú`, same tone
   as the neighbouring strings). Interpolations: `%@` for strings, `%lld` for
   integers, positional (`%1$@`, `%2$lld`) when there are several.
4. **Run the script** from the repo root:

   ```bash
   python3 .claude/skills/localize/scripts/add_strings.py <Package> <key> \
     --comment "<where it appears and what it means, for translators>" \
     --value en="…" --value es="…"
   ```

   It refuses if any language already in the catalog is missing, keeps the
   catalog's JSON style (diffs show only your key), and regenerates symbols.
   Running it again with the same key updates the copy.
5. **Use the symbol** at the call site: `Text(.key)`, `Button(.key, action: …)`,
   `String(localized: .key)`. Interpolated keys become functions:
   `Text(.key(name, count))`.
6. **Report the copy** (both languages) in your summary so Martín can adjust tone.

## Not covered

Adding a whole new language touches every catalog, `StreamIn/InfoPlist.xcstrings`,
`knownRegions` in the project and the `Language` picker — follow the localization
checklist in the roadmap instead.
