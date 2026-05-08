// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TMDBClient",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "TMDBClient", targets: ["TMDBClient"]),
    ],
    dependencies: [
        // Local sibling package. Path is relative to this Package.swift.
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "TMDBClient",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "TMDBClientTests",
            dependencies: [
                "TMDBClient",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
