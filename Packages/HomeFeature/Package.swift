// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HomeFeature",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "HomeFeature", targets: ["HomeFeature"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem"),
        .package(path: "../FeatureUI")
    ],
    targets: [
        .target(
            name: "HomeFeature",
            dependencies: ["CoreKit", "DomainKit", "DesignSystem", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "HomeFeatureTests",
            dependencies: ["HomeFeature", "DomainKit", "CoreKit", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
