// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SwarmGlow",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KreoCore"),
        .target(name: "KreoUI", dependencies: ["KreoCore"]),
        .executableTarget(name: "SwarmGlow", dependencies: ["KreoUI"]),
        // Renders the window and the app icon to PNG. Never opens the keyboard.
        .executableTarget(name: "KreoSnapshot", dependencies: ["KreoUI", "KreoCore"]),
        .testTarget(name: "KreoCoreTests", dependencies: ["KreoCore"], resources: [.copy("golden.json")]),
    ]
)
