// swift-tools-version: 5.9
// Daylight macOS menu bar client package manifest.
// Exports: DaylightMenuBar executable target
// Deps: AppKit via system frameworks

import PackageDescription

let package = Package(
    name: "DaylightMenuBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DaylightMenuBar", targets: ["DaylightMenuBar"])
    ],
    targets: [
        .target(
            name: "DaylightMenuBarKit",
            path: "Sources/DaylightMenuBar",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "DaylightMenuBar",
            dependencies: ["DaylightMenuBarKit"],
            path: "Sources/DaylightMenuBarApp"
        ),
        .testTarget(
            name: "DaylightMenuBarKitTests",
            dependencies: ["DaylightMenuBarKit"]
        )
    ]
)
