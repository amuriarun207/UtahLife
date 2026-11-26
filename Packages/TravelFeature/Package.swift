// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TravelFeature",
    platforms: [.iOS(.v26)],
    products: [.library(name: "TravelFeature", targets: ["TravelFeature"])],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem"),
        .package(path: "../FeatureUI")
    ],
    targets: [
        .target(
            name: "TravelFeature",
            dependencies: ["CoreKit", "DomainKit", "DesignSystem", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TravelFeatureTests",
            dependencies: ["TravelFeature", "DomainKit", "CoreKit", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
