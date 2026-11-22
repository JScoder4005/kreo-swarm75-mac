// Renders README/release images without opening the keyboard:
//   swift run KreoSnapshot screens <dir>   window screenshots, dark and light
//   swift run KreoSnapshot gif <file.gif>  animated demo of the effects
//   swift run KreoSnapshot icon <file.png> 1024px app icon
import AppKit
import ImageIO
import KreoCore
import KreoUI
import SwiftUI
import UniformTypeIdentifiers

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

/// One frame of the demo GIF: the preview with the effect's name underneath.
struct DemoFrame: View {
    let settings: LightingSettings
    let title: String
    let time: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            KeyboardPreview(settings: settings)
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Text("SwarmGlow for Kreo Swarm 75").font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.horizontal, 6)
        }
        .padding(22)
        .frame(width: 680)
        .background(Color(red: 0.055, green: 0.063, blue: 0.09))
        .environment(\.previewFrozenTime, time)
    }
}

@MainActor func png(_ view: some View, scale: CGFloat) -> Data? {
    let r = ImageRenderer(content: view)
    r.scale = scale
    guard let tiff = r.nsImage?.tiffRepresentation else { return nil }
    return NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
}

@MainActor func window(_ state: AppState, dark: Bool) -> some View {
    MenuView()
        .environmentObject(state)
        .environment(\.snapshotMode, true)
        .environment(\.previewFrozenTime, 2.2)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.colorScheme, dark ? .dark : .light)
}

let args = Array(CommandLine.arguments.dropFirst())
guard args.count == 2 else {
    print("usage: KreoSnapshot screens <dir> | gif <file.gif> | icon <file.png>")
    exit(1)
}
let target = URL(fileURLWithPath: args[1])

MainActor.assumeIsolated {
    _ = NSApplication.shared
    switch args[0] {
    case "icon":
        try? png(AppIconArt(), scale: 1)?.write(to: target)
        print("wrote icon")

    case "screens":
        let profiles = [
            Profile(name: "Work", settings: LightingSettings(color: RGB(47, 123, 255), effect: 1, brightness: 75, speed: 50)),
            Profile(name: "Gaming", settings: LightingSettings(color: RGB(255, 59, 59), effect: 2, brightness: 100, speed: 75)),
            Profile(name: "Night", settings: LightingSettings(color: RGB(138, 92, 255), effect: 3, brightness: 25, speed: 25)),
        ]
        let shots: [(String, AppState, Bool)] = [
            ("window-dark", .preview(profiles[1].settings, profiles: profiles, connected: true), true),
            ("window-light", .preview(profiles[0].settings, profiles: profiles, connected: true), false),
        ]
        for (name, state, dark) in shots {
            try? png(window(state, dark: dark), scale: 2)?.write(to: target.appendingPathComponent("\(name).png"))
            print("wrote \(name).png")
        }

    case "gif":
        let fps = 12.0
        let scenes: [(LightingSettings, String, Double)] = [
            (LightingSettings(color: RGB(255, 59, 59), effect: 2, brightness: 100, speed: 50), "Rainbow wave", 3),
            (LightingSettings(color: RGB(138, 92, 255), effect: 3, brightness: 100, speed: 50), "Breathing", 3),
            (LightingSettings(color: RGB(23, 200, 200), effect: 7, brightness: 100, speed: 50), "Ripples", 3),
            (LightingSettings(color: RGB(61, 220, 132), effect: 10, brightness: 100, speed: 50), "Retro snake", 3),
            (LightingSettings(color: RGB(47, 123, 255), effect: 1, brightness: 100, speed: 50), "Static", 1.5),
        ]
        var frames: [CGImage] = []
        for (settings, title, seconds) in scenes {
            for i in 0..<Int(seconds * fps) {
                let r = ImageRenderer(content: DemoFrame(settings: settings, title: title, time: Double(i) / fps))
                r.scale = 1
                if let img = r.cgImage { frames.append(img) }
            }
        }
        guard let dest = CGImageDestinationCreateWithURL(target as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
            print("could not create gif"); exit(1)
        }
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps]] as CFDictionary
        for f in frames { CGImageDestinationAddImage(dest, f, frameProps) }
        print(CGImageDestinationFinalize(dest) ? "wrote gif, \(frames.count) frames" : "gif failed")

    default:
        print("unknown mode \(args[0])")
    }
}
