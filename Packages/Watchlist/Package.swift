// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Watchlist",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Watchlist",
            targets: ["Watchlist"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "Watchlist",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "WatchlistTests",
            dependencies: [
                "Watchlist",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
