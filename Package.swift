// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "QuickNav",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "QuickNavCore",
            path: "Sources/Core"
        ),
        .target(
            name: "QuickNavAppKit",
            dependencies: ["QuickNavCore"],
            path: "Sources/AppKit"
        ),
        .executableTarget(
            name: "QuickNav",
            dependencies: ["QuickNavAppKit"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "QuickNavCoreTests",
            dependencies: ["QuickNavCore"],
            path: "Tests/CoreTests"
        )
    ]
)
