// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Preferences",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Preferences",
            targets: ["Preferences"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "Preferences",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "PreferencesTests",
            dependencies: [
                "Preferences",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
