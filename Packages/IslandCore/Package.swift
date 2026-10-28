// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IslandCore",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "IslandCore", targets: ["IslandCore"]),
        .library(name: "IslandCoreTestSupport", targets: ["IslandCoreTestSupport"]),
    ],
    targets: [
        .target(name: "IslandCore"),
        .target(name: "IslandCoreTestSupport", dependencies: ["IslandCore"]),
        .testTarget(name: "IslandCoreTests", dependencies: ["IslandCore", "IslandCoreTestSupport"]),
    ]
)
