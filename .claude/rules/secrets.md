---
paths:
  - "Secrets.example.xcconfig"
  - "StreamIn/Secrets/**"
---

# Build-time secrets

`Secrets.xcconfig` (gitignored) defines `TMDB_API_KEY`. A "Generate Secrets" Run
Script Phase, placed before "Compile Sources", writes
`StreamIn/Secrets/GeneratedSecrets.swift` (also gitignored) with the key as a
Swift constant. `AppConfig.tmdbAPIKey` reads it, rejects the sentinel
`your_tmdb_api_key_here`, and `preconditionFailure`s with setup instructions.

Claude never reads or edits the real secrets: `.claude/settings.json` denies
reading both files and a hook blocks editing them.

**Why not `INFOPLIST_KEY_TMDB_API_KEY = $(TMDB_API_KEY)`?** With
`GENERATE_INFOPLIST_FILE = YES`, Xcode only honors Info.plist keys it recognizes;
custom keys are silently dropped (confirmed empirically).

**One sentinel:** `your_tmdb_api_key_here` is the same in
`Secrets.example.xcconfig`, the script's `${TMDB_API_KEY:-…}` fallback and the
`AppConfig` guard, so misconfiguration always produces the same fix message.

The Run Script declares `$(SRCROOT)/StreamIn/Secrets/GeneratedSecrets.swift` as
an output file, so the build sandbox allows the write. It has no input files, so
after changing the key do a clean build (⇧⌘K); adding `$(SRCROOT)/Secrets.xcconfig`
as an input would make Xcode re-run it automatically.

**Fresh clones:** the app target uses a file-system-synchronized group, and Xcode
decides which files to compile before the Run Script runs. Without an existing
`GeneratedSecrets.swift`, the first build fails with "cannot find
'GeneratedSecrets'" (the second would pass). `scripts/setup.sh` creates
`Secrets.xcconfig` from the template and a placeholder `GeneratedSecrets.swift`;
README and CI both run it.
