// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SettingsFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SettingsFeature",
            targets: ["SettingsFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Preferences"),
    ],
    targets: [
        .target(
            name: "SettingsFeature",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "Preferences", package: "Preferences"),
            ],
            resources: [.process("Translations/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "SettingsFeatureTests",
            dependencies: [
                "SettingsFeature",
                .product(name: "Domain", package: "Domain"),
                .product(name: "Preferences", package: "Preferences"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
