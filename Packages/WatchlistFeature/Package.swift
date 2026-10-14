// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WatchlistFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WatchlistFeature",
            targets: ["WatchlistFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Watchlist"),
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "WatchlistFeature",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "Watchlist", package: "Watchlist"),
                .product(name: "DesignSystem", package: "DesignSystem"),
            ],
            resources: [.process("Translations/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "WatchlistFeatureTests",
            dependencies: [
                "WatchlistFeature",
                .product(name: "Domain", package: "Domain"),
                .product(name: "Watchlist", package: "Watchlist"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
