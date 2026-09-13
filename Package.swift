// swift-tools-version: 6.4

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
    dependencies: [
        .package(url: "https://github.com/markos92i/ZafirUI.git", exact: "1.0.0")
    ],
    targets: [
        .target(
            name: "CameraKit",
            dependencies: [
                .product(name: "ZafirUI", package: "ZafirUI")
            ],
            resources: [.process("Resources")]
        )
    ]
)
