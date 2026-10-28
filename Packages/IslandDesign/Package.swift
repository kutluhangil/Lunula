// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "IslandDesign",
    platforms: [.macOS("26.0")],
    products: [.library(name: "IslandDesign", targets: ["IslandDesign"])],
    dependencies: [.package(path: "../IslandCore")],
    targets: [
        .target(name: "IslandDesign", dependencies: [.product(name: "IslandCore", package: "IslandCore")]),
        .testTarget(name: "IslandDesignTests", dependencies: ["IslandDesign"]),
    ]
)
