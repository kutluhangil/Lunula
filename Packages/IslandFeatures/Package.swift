// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IslandFeatures",
    defaultLocalization: "en",
    platforms: [.macOS("26.0")],
    products: [.library(name: "IslandFeatures", targets: ["IslandFeatures"])],
    dependencies: [.package(path: "../IslandCore"), .package(path: "../IslandDesign")],
    targets: [
        .target(
            name: "IslandFeatures",
            dependencies: [
                .product(name: "IslandCore", package: "IslandCore"),
                .product(name: "IslandDesign", package: "IslandDesign"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "IslandFeaturesTests",
            dependencies: ["IslandFeatures", .product(name: "IslandCoreTestSupport", package: "IslandCore")]
        ),
    ]
)
