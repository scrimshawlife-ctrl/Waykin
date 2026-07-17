// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Waykin",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WaykinCore", targets: ["WaykinCore"]),
        .executable(name: "waykin-sim", targets: ["WaykinSim"]),
    ],
    targets: [
        .target(name: "WaykinCore"),
        .executableTarget(name: "WaykinSim", dependencies: ["WaykinCore"]),
        .testTarget(name: "WaykinCoreTests", dependencies: ["WaykinCore"]),
    ]
)
