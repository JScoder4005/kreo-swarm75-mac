// Renders the Kreo window to PNG files for design review. Never opens the keyboard.
// usage: swift run KreoSnapshot <output-dir>
import AppKit
import KreoCore
import KreoUI
import SwiftUI

let out = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
let profiles = [
    Profile(name: "Work", settings: LightingSettings(color: RGB(47, 123, 255), effect: 1, brightness: 75, speed: 50)),
    Profile(name: "Gaming", settings: LightingSettings(color: RGB(255, 59, 59), effect: 7, brightness: 100, speed: 75)),
]

@MainActor func render(_ name: String, _ state: AppState, dark: Bool) {
    let view = MenuView()
        .environmentObject(state)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.colorScheme, dark ? .dark : .light)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
          let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
        print("failed: \(name)"); return
    }
    try? png.write(to: out.appendingPathComponent("\(name).png"))
    print("wrote \(name).png")
}

MainActor.assumeIsolated {
    _ = NSApplication.shared
    render("connected-dark", .preview(LightingSettings(color: RGB(255, 59, 59), effect: 2, brightness: 75, speed: 50),
                                      profiles: profiles, connected: true), dark: true)
    render("static-light", .preview(LightingSettings(color: RGB(47, 123, 255), effect: 1, brightness: 75, speed: 50),
                                    profiles: profiles, connected: true), dark: false)
    render("unplugged-dark", .preview(LightingSettings(color: RGB(61, 220, 132), effect: 10, brightness: 100, speed: 25),
                                      connected: false), dark: true)
}
