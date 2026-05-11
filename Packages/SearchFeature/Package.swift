// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SearchFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SearchFeature",
            targets: ["SearchFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Preferences"),
    ],
    targets: [
        .target(
            name: "SearchFeature",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "Preferences", package: "Preferences"),
            ],
            resources: [.process("Translations/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "SearchFeatureTests",
            dependencies: [
                "SearchFeature",
                .product(name: "Domain", package: "Domain"),
                .product(name: "Preferences", package: "Preferences"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
