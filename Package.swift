// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "CameraKit",
    defaultLocalization: "es",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "CameraKit",
            targets: ["CameraKit"]
        )
    ],
    targets: [
        .target(
            name: "CameraKit",
            resources: [.process("Resources")]
        )
    ]
)
