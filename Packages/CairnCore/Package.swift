// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CairnCore",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "CairnCore", targets: ["CairnCore"]),
    ],
    targets: [
        .target(name: "CairnCore"),
        .testTarget(name: "CairnCoreTests", dependencies: ["CairnCore"]),
    ]
)
