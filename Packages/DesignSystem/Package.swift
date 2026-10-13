// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        ),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            resources: [
                .process("Resources/Assets.xcassets"),
                // Read pixel by pixel by `WorldMap`, so it ships as is.
                .copy("Resources/worldMap.png"),
            ]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
