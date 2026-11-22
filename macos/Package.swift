// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "KreoMenu",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KreoCore"),
        .target(name: "KreoUI", dependencies: ["KreoCore"]),
        .executableTarget(name: "KreoMenu", dependencies: ["KreoUI"]),
        // Renders the window to a PNG for design review. Never opens the keyboard.
        .executableTarget(name: "KreoSnapshot", dependencies: ["KreoUI", "KreoCore"]),
        .testTarget(name: "KreoCoreTests", dependencies: ["KreoCore"], resources: [.copy("golden.json")]),
    ]
)
