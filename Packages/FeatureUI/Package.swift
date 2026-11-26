// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureUI",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "FeatureUI", targets: ["FeatureUI"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit"),
        .package(path: "../DesignSystem")
    ],
    targets: [
        .target(
            name: "FeatureUI",
            dependencies: ["CoreKit", "DomainKit", "DesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
