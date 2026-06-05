// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "QuickNav",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "QuickNav",
            path: "Sources/QuickNav"
        )
    ]
)
