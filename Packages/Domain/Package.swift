// swift-tools-version: 6.2
// Place at: Packages/Domain/Package.swift
//
// The `Domain` package has NO dependencies. That's intentional and load-bearing.
// If you ever feel tempted to add `import Foundation` for networking or
// `import SwiftData` here, stop — those belong in the data layer.

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
    ],
    targets: [
        .target(
            name: "Domain"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
