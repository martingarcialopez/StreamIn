// swift-tools-version: 6.2
//
// SwiftData lives here and nowhere else: features reach saved movies through
// Domain's `WatchlistRepository`, so no SwiftData type leaves this package.

import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Persistence",
            targets: ["Persistence"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "Persistence",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
