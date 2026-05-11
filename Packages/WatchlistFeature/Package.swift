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
        .package(path: "../Domain")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WatchlistFeature",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ],
            resources: [.process("Translations/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "WatchlistFeatureTests",
            dependencies: [
                "WatchlistFeature",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
