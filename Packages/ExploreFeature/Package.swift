// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ExploreFeature",
    platforms: [.iOS(.v26)],
    products: [.library(name: "ExploreFeature", targets: ["ExploreFeature"])],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem"),
        .package(path: "../FeatureUI")
    ],
    targets: [
        .target(
            name: "ExploreFeature",
            dependencies: ["CoreKit", "DomainKit", "DesignSystem", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ExploreFeatureTests",
            dependencies: ["ExploreFeature", "DomainKit", "CoreKit", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
