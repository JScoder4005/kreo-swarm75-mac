// Renders the SwarmGlow window to PNG files for design review, or the 1024px app icon.
// Never opens the keyboard.
// usage: swift run KreoSnapshot <output-dir>
//        swift run KreoSnapshot icon <file.png>
import AppKit
import KreoCore
import KreoUI
import SwiftUI

/// A slice of keycaps with per-key underglow sweeping across the spectrum, on a dark plate.
struct AppIconArt: View {
    var body: some View {
        Canvas { g, size in
            let s = size.width
            let body = CGRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8)
            let plate = Path(roundedRect: body, cornerRadius: s * 0.18, style: .continuous)
            g.fill(plate, with: .linearGradient(
                Gradient(colors: [Color(red: 0.15, green: 0.16, blue: 0.24), Color(red: 0.06, green: 0.07, blue: 0.10)]),
                startPoint: CGPoint(x: body.midX, y: body.minY), endPoint: CGPoint(x: body.midX, y: body.maxY)))

            let cols = 4, rows = 3
            let gap = s * 0.035
            let inset = s * 0.2
            let key = (s - inset * 2 - gap * CGFloat(cols - 1)) / CGFloat(cols)
            let top = (s - (key * CGFloat(rows) + gap * CGFloat(rows - 1))) / 2
            for r in 0..<rows {
                for c in 0..<cols {
                    let rect = CGRect(x: inset + CGFloat(c) * (key + gap), y: top + CGFloat(r) * (key + gap),
                                      width: key, height: key)
                    let t = Double(c + r) / Double(cols + rows - 2)
                    let lit = Color(hue: 0.62 - 0.62 * t, saturation: 0.85, brightness: 1)
                    let cap = Path(roundedRect: rect, cornerRadius: key * 0.2, style: .continuous)
                    var glow = g
                    glow.addFilter(.blur(radius: s * 0.03))
                    glow.fill(Path(roundedRect: rect.insetBy(dx: key * 0.08, dy: key * 0.3).offsetBy(dx: 0, dy: key * 0.3),
                                   cornerRadius: key * 0.1), with: .color(lit.opacity(0.9)))
                    g.fill(cap, with: .linearGradient(
                        Gradient(colors: [Color(red: 0.20, green: 0.22, blue: 0.30), lit.opacity(0.55)]),
                        startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
                    let bar = CGRect(x: rect.minX + key * 0.16, y: rect.maxY - key * 0.15, width: key * 0.68, height: key * 0.06)
                    g.fill(Path(roundedRect: bar, cornerRadius: key * 0.03), with: .color(lit))
                }
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "icon" {
    MainActor.assumeIsolated {
        let renderer = ImageRenderer(content: AppIconArt())
        renderer.scale = 1
        if let tiff = renderer.nsImage?.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
            print("wrote icon")
        }
    }
    exit(0)
}

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
