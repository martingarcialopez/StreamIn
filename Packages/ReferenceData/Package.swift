// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ReferenceData",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "ReferenceData",
            targets: ["ReferenceData"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
    ],
    targets: [
        .target(
            name: "ReferenceData",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "ReferenceDataTests",
            dependencies: [
                "ReferenceData",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
