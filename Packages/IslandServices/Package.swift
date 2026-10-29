// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IslandServices",
    platforms: [.macOS("26.0")],
    products: [.library(name: "IslandServices", targets: ["IslandServices"])],
    dependencies: [.package(path: "../IslandCore")],
    targets: [
        .target(name: "IslandServices", dependencies: [.product(name: "IslandCore", package: "IslandCore")]),
        .testTarget(
            name: "IslandServicesTests",
            dependencies: ["IslandServices", .product(name: "IslandCoreTestSupport", package: "IslandCore")],
            resources: [.copy("Resources")]
        ),
    ]
)
