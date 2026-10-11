---
paths:
  - "**/*.xcstrings"
  - "**/Translations/**"
  - "Packages/SettingsFeature/Sources/SettingsFeature/SettingsView.swift"
  - "Packages/Domain/Sources/Domain/Domain.swift"
---

# Localization

## Per-package String Catalogs

Every package with user-facing strings owns its catalog:

```
Packages/<Pkg>/Sources/<Pkg>/Translations/
├── Localizable.xcstrings                    — all keys, every language
└── GeneratedStringSymbols_Localizable.swift — generated typed symbols (committed)
```

Declared in `Package.swift` with `resources: [.process("Translations/Localizable.xcstrings")]`.
Call sites use symbols for compile-time safety: `Text(.searchPrompt)`,
`Button(.detailsRetry, action: …)`, `String(localized: .errorOffline)`;
interpolated keys become functions (`Text(.detailsLoadFailed(message))`).

Per-package rather than one shared catalog: it matches the build-time module
boundaries and keeps each feature self-contained. Shared strings (`Cancel`, `OK`)
move to DesignSystem's catalog only once a key is duplicated more than twice.

**Symbols aren't generated automatically for package catalogs** (Xcode 26 only
does it for app-target catalogs). The `localize` skill and the `after-edit` hook
run `xcrun xcstringstool generate-symbols` for you; never edit the generated file.

## App target

- `StreamIn/InfoPlist.xcstrings` localizes `CFBundleDisplayName` in en + es. It's
  load-bearing: the app-level localized resource is what makes iOS show the
  per-app Language picker (Settings → Apps → StreamIn → Language).
- `knownRegions = (en, es, Base)` in `project.pbxproj` declares supported languages.
  New languages go there and in `InfoPlist.xcstrings`.
- `INFOPLIST_KEY_CFBundleLocalizations` is silently dropped when
  `GENERATE_INFOPLIST_FILE = YES`; don't use it.

## In-app language picker

Settings → Language writes both `prefs.language` (TMDB's `language=` parameter)
and `UserDefaults.standard.AppleLanguages` (the bundle locale iOS picks at launch),
so one control switches UI and content together.

Bundles cache their localization at launch, so switching shows a "Restart now /
Later" alert. **Restart now** calls `exit(0)` (against the HIG but the common
pattern; if App Review objects, drop it and rely on next launch). **Later**
persists the choice for the next launch.

The binding is deferred: nothing changes until the user taps an alert button, so
the picker briefly snaps back to the old value — accepted for data correctness.

## Supported languages

The picker (`Language.allKnown` in Domain) must only offer languages that every
catalog actually translates — today en and es. Adding one means: every package
catalog, `InfoPlist.xcstrings`, `knownRegions`, then the `Language` list.
