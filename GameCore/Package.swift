// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GameCore",
    platforms: [.watchOS(.v10), .iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "GameCore", targets: ["GameCore"]),
        .library(name: "HordeCore", targets: ["HordeCore"]),
        .library(name: "FXCore", targets: ["FXCore"])
    ],
    targets: [
        .target(name: "GameCore"),
        .target(name: "HordeCore", dependencies: ["GameCore"]),
        .target(name: "FXCore", dependencies: ["GameCore"]),
        .testTarget(name: "GameCoreTests", dependencies: ["GameCore"]),
        .testTarget(name: "HordeCoreTests", dependencies: ["HordeCore", "GameCore"]),
        .testTarget(name: "FXCoreTests", dependencies: ["FXCore", "GameCore"])
    ]
)
