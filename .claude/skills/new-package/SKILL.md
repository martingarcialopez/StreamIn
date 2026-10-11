---
name: new-package
description: Scaffold a new local Swift package under Packages/ (a layer like Persistence, or a *Feature screen) following StreamIn's layout, and register it in the Xcode project. Use when a phase needs a new module.
argument-hint: <PackageName>
---

# New local package

## 1. Decide the layer

Check the Architecture table in CLAUDE.md. Features depend on Domain and
DesignSystem (plus Preferences / ReferenceData when needed) — never on
TMDBClient or SwiftData. If the layer or its dependencies are ambiguous, ask
Martín before creating anything.

## 2. Scaffold

Copy the layout of the closest existing package: `Packages/SearchFeature` for a
screen, `Packages/ReferenceData` for a non-UI layer.

```
Packages/<Name>/
├── .gitignore                         (copy from Packages/ReferenceData)
├── Package.swift
├── Sources/<Name>/<FirstType>.swift
└── Tests/<Name>Tests/<FirstType>Tests.swift   (Swift Testing)
```

`Package.swift` keeps the project conventions:

```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "<Name>",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "<Name>", targets: ["<Name>"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "<Name>",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "<Name>Tests",
            dependencies: [
                "<Name>",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
```

If the package shows UI text, add `Sources/<Name>/Translations/Localizable.xcstrings`
(`{"sourceLanguage" : "en", "strings" : {}, "version" : "1.0"}`),
`resources: [.process("Translations/Localizable.xcstrings")]` on the target,
and add strings with the `localize` skill.

## 3. Wire it up

- Add `.package(path: "../<Name>")` and the product to every consumer's `Package.swift`.
- Register it in the Xcode project — never hand-edit `project.pbxproj` for this:

  ```bash
  python3 .claude/skills/new-package/scripts/add_local_package.py <Name>
  ```

  Add `--no-link` if the App target doesn't import the package itself. The
  script adds the same entries Xcode would, validates with `plutil -lint`,
  restores the file on failure, and does nothing if the package is already
  registered. Tell Martín to reopen the project if Xcode has it open.
- Add one line for the package to the Architecture table in CLAUDE.md.

## 4. Verify

Build the app and run the new package's tests (commands in the `ship-phase` skill).
