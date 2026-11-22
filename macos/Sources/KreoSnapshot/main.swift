// Renders README/release images without opening the keyboard:
//   swift run KreoSnapshot screens <dir>   window screenshots, dark and light
//   swift run KreoSnapshot gif <file.gif>  animated demo of the effects
//   swift run KreoSnapshot icon <file.png> 1024px app icon
//   swift run KreoSnapshot instagram <dir> 15s Reel (MP4) + 4 carousel slides; reads ../docs/window-*.png
import AppKit
import AVFoundation
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

// MARK: Instagram

enum IG {
    static let ink = Color.white
    static let dim = Color.white.opacity(0.62)
    static let bg = LinearGradient(colors: [Color(red: 0.075, green: 0.085, blue: 0.13), Color(red: 0.03, green: 0.035, blue: 0.05)],
                                   startPoint: .top, endPoint: .bottom)
    static let rainbow = LinearGradient(colors: [.cyan, .blue, .purple, .pink, .orange], startPoint: .leading, endPoint: .trailing)
    static func title(_ s: String, _ size: CGFloat) -> some View {
        Text(s).font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(ink)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }
    static func rainbowTitle(_ s: String, _ size: CGFloat) -> some View {
        Text(s).font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(rainbow)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }
    static func body(_ s: String, _ size: CGFloat) -> some View {
        Text(s).font(.system(size: size, weight: .medium, design: .rounded)).foregroundStyle(dim)
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }
    static let rainbowLook = LightingSettings(color: RGB(255, 59, 59), effect: 2, brightness: 100, speed: 50)
}

struct AppIconSmall: View {
    var size: CGFloat
    var body: some View { AppIconArt().scaleEffect(size / 1024).frame(width: size, height: size) }
}

/// Window screenshot with a soft shadow, as it looks on a desktop.
struct WindowShot: View {
    let image: NSImage
    let height: CGFloat
    var body: some View {
        Image(nsImage: image).resizable().interpolation(.high).scaledToFit().frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 18)
    }
}

/// 1080×1350 carousel slides.
struct Slide: View {
    let index: Int
    let dark: NSImage
    let light: NSImage

    var body: some View {
        ZStack {
            IG.bg
            switch index {
            case 0:
                VStack(spacing: 34) {
                    AppIconSmall(size: 170)
                    IG.rainbowTitle("SwarmGlow", 112)
                    IG.body("The missing Mac app for the\nKreo Swarm 75 keyboard", 46)
                    KeyboardPreview(settings: IG.rainbowLook).frame(width: 940, height: 390)
                        .environment(\.previewFrozenTime, 1.4)
                }
            case 1:
                VStack(spacing: 40) {
                    IG.title("Pick a look.\nSee it live.", 76)
                    WindowShot(image: dark, height: 900)
                }
            case 2:
                VStack(spacing: 40) {
                    IG.title("Save profiles. It applies\nwhen you plug in.", 64)
                    WindowShot(image: light, height: 900)
                }
            default:
                VStack(alignment: .leading, spacing: 44) {
                    IG.title("Free & open source", 84)
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(["13 effects, 5-step brightness & speed",
                                 "Set once over USB, stays on Bluetooth",
                                 "Apple Silicon + Intel, macOS 14+",
                                 "Unofficial, not affiliated with Kreo"], id: \.self) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 18) {
                                Circle().fill(IG.rainbow).frame(width: 16, height: 16)
                                Text(line).font(.system(size: 44, weight: .medium, design: .rounded)).foregroundStyle(IG.ink)
                            }
                        }
                    }
                    Text("Link in bio  →  GitHub").font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(IG.rainbow).padding(.top, 20)
                }
                .padding(.horizontal, 90)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 1080, height: 1350)
    }
}

/// One frame of the 1080×1920 Reel. Text stays in the upper two thirds, clear of Instagram's buttons.
struct ReelFrame: View {
    let t: Double
    let dark: NSImage

    private func fade(_ start: Double) -> Double { min(max((t - start) / 0.35, 0), 1) }

    var body: some View {
        ZStack {
            IG.bg
            if t < 3 {
                VStack(spacing: 60) {
                    IG.title("Kreo's app is\nWindows-only.", 92).opacity(fade(0))
                    IG.rainbowTitle("So I built one\nfor Mac.", 92).opacity(fade(1.1))
                    KeyboardPreview(settings: IG.rainbowLook).frame(width: 980, height: 400)
                        .environment(\.previewFrozenTime, t).opacity(fade(0.3))
                }
                .offset(y: -150)
            } else if t < 9 {
                let scenes: [(LightingSettings, String)] = [
                    (IG.rainbowLook, "Rainbow wave"),
                    (LightingSettings(color: RGB(138, 92, 255), effect: 3, brightness: 100, speed: 50), "Breathing"),
                    (LightingSettings(color: RGB(23, 200, 200), effect: 7, brightness: 100, speed: 50), "Ripples"),
                    (LightingSettings(color: RGB(61, 220, 132), effect: 10, brightness: 100, speed: 50), "Retro snake"),
                ]
                let i = min(Int((t - 3) / 1.5), 3)
                VStack(spacing: 56) {
                    IG.body("13 effects", 52)
                    KeyboardPreview(settings: scenes[i].0).frame(width: 1000, height: 410)
                        .environment(\.previewFrozenTime, t)
                    IG.title(scenes[i].1, 96)
                }
                .offset(y: -170)
                .opacity(fade(3))
            } else if t < 12.5 {
                VStack(spacing: 48) {
                    IG.title("Live preview · profiles\nauto-applies on plug-in", 64)
                    WindowShot(image: dark, height: 1100)
                }
                .offset(y: -120)
                .opacity(fade(9))
            } else {
                VStack(spacing: 40) {
                    AppIconSmall(size: 260)
                    IG.rainbowTitle("SwarmGlow", 130)
                    IG.body("for the Kreo Swarm 75 on Mac", 54)
                    Text("Free & open source · Link in bio").font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(IG.ink).padding(.top, 30)
                }
                .offset(y: -180)
                .opacity(fade(12.5))
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

@MainActor func writeReel(to url: URL, dark: NSImage, seconds: Double = 15, fps: Int32 = 30) throws {
    try? FileManager.default.removeItem(at: url)
    let size = CGSize(width: 1080, height: 1920)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height),
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 10_000_000],
    ])
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: Int(size.width), kCVPixelBufferHeightKey as String: Int(size.height),
    ])
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let frames = Int(seconds * Double(fps))
    for i in 0..<frames {
        let r = ImageRenderer(content: ReelFrame(t: Double(i) / Double(fps), dark: dark))
        r.scale = 1
        guard let cg = r.cgImage, let pool = adaptor.pixelBufferPool else { continue }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        guard let pb = buffer else { continue }
        CVPixelBufferLockBaseAddress(pb, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: Int(size.width), height: Int(size.height),
                            bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        ctx?.draw(cg, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(pb, [])
        while !input.isReadyForMoreMediaData { usleep(2000) }
        adaptor.append(pb, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    if writer.status != .completed { throw writer.error ?? CocoaError(.fileWriteUnknown) }
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

    case "instagram":
        guard let dark = NSImage(contentsOfFile: "../docs/window-dark.png"),
              let light = NSImage(contentsOfFile: "../docs/window-light.png") else {
            print("run from macos/: needs ../docs/window-dark.png and window-light.png"); exit(1)
        }
        try? FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        for i in 0..<4 {
            try? png(Slide(index: i, dark: dark, light: light), scale: 1)?
                .write(to: target.appendingPathComponent("slide-\(i + 1).png"))
        }
        print("wrote 4 slides")
        do {
            try writeReel(to: target.appendingPathComponent("swarmglow-reel.mp4"), dark: dark)
            print("wrote reel")
        } catch {
            print("reel failed: \(error)")
        }

    default:
        print("unknown mode \(args[0])")
    }
}
