// swift-tools-version: 6.0
// Purpose: Swift package for the HoldoutCore game simulation. Notes: docs/features/core-api.md
import PackageDescription

let package = Package(
    name: "HoldoutCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "HoldoutCore", targets: ["HoldoutCore"])
    ],
    targets: [
        .target(name: "HoldoutCore"),
        .testTarget(name: "HoldoutCoreTests", dependencies: ["HoldoutCore"])
    ]
)
