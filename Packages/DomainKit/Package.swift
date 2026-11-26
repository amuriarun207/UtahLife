// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DomainKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "DomainKit", targets: ["DomainKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit")
    ],
    targets: [
        .target(
            name: "DomainKit",
            dependencies: ["CoreKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DomainKitTests",
            dependencies: ["DomainKit", "CoreKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
