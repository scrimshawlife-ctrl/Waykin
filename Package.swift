// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Waykin",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "WaykinCore", targets: ["WaykinCore"]),
        .executable(name: "WaykinDemo", targets: ["WaykinDemo"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WaykinCore",
            dependencies: [],
            path: "Sources/WaykinCore"
        ),
        .executableTarget(
            name: "WaykinDemo",
            dependencies: ["WaykinCore"],
            path: "Demo"
        ),
        .testTarget(
            name: "WaykinCoreTests",
            dependencies: ["WaykinCore"],
            path: "Tests/WaykinCoreTests"
        ),
    ]
)
