// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "KreoMenu",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KreoCore"),
        .executableTarget(name: "KreoMenu", dependencies: ["KreoCore"]),
        .testTarget(name: "KreoCoreTests", dependencies: ["KreoCore"], resources: [.copy("golden.json")]),
    ]
)
