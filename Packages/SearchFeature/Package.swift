// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SearchFeature",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SearchFeature",
            targets: ["SearchFeature"]
        ),
    ],
    dependencies: [
        // Sibling local package, resolved by relative path.
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "SearchFeature",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "SearchFeatureTests",
            dependencies: [
                "SearchFeature",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ]
)
