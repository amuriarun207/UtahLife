// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AlertsFeature",
    platforms: [.iOS(.v26)],
    products: [.library(name: "AlertsFeature", targets: ["AlertsFeature"])],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem"),
        .package(path: "../FeatureUI")
    ],
    targets: [
        .target(
            name: "AlertsFeature",
            dependencies: ["CoreKit", "DomainKit", "DesignSystem", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "AlertsFeatureTests",
            dependencies: ["AlertsFeature", "DomainKit", "CoreKit", "FeatureUI"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
