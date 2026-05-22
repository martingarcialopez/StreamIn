// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DetailsFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DetailsFeature",
            targets: ["DetailsFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Preferences"),
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "DetailsFeature",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "Preferences", package: "Preferences"),
                .product(name: "DesignSystem", package: "DesignSystem"),
            ],
            resources: [.process("Translations/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "DetailsFeatureTests",
            dependencies: [
                "DetailsFeature",
                .product(name: "Domain", package: "Domain"),
                .product(name: "Preferences", package: "Preferences"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
