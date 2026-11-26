// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DataKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "DataKit", targets: ["DataKit"])
    ],
    dependencies: [
        .package(path: "../CoreKit"),
        .package(path: "../DomainKit")
    ],
    targets: [
        .target(
            name: "DataKit",
            dependencies: ["CoreKit", "DomainKit"],
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DataKitTests",
            dependencies: ["DataKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
