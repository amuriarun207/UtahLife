// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "EnvironmentFeature",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "EnvironmentFeature", targets: ["EnvironmentFeature"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem"),
        .package(path: "../FeatureUI")
    ],
    targets: [
        .target(
            name: "EnvironmentFeature",
            dependencies: ["CoreKit", "DomainKit", "DesignSystem", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "EnvironmentFeatureTests",
            dependencies: ["EnvironmentFeature", "DomainKit", "CoreKit", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
