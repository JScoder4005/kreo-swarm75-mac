import KreoCore
import SwiftUI

enum Theme {
    static let plate = Color(red: 0.090, green: 0.102, blue: 0.141)   // #171A24
    static let cap = Color(red: 0.161, green: 0.180, blue: 0.239)     // #292E3D
    static let capEdge = Color(red: 0.208, green: 0.231, blue: 0.302)

    /// The user's lighting color, lifted when it is too dark to work as an accent.
    static func accent(_ rgb: RGB) -> Color {
        let sum = Int(rgb.r) + Int(rgb.g) + Int(rgb.b)
        return sum < 120 ? Color.accentColor : Color(rgb: rgb)
    }
}

extension Color {
    init(rgb: RGB) {
        self.init(.sRGB, red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255)
    }
}

// For README screenshots and the demo GIF: AppKit controls can't render offscreen, and the
// preview needs a fixed moment in time.
private struct SnapshotModeKey: EnvironmentKey { static let defaultValue = false }
private struct FrozenTimeKey: EnvironmentKey { static let defaultValue: Double? = nil }

public extension EnvironmentValues {
    var snapshotMode: Bool {
        get { self[SnapshotModeKey.self] }
        set { self[SnapshotModeKey.self] = newValue }
    }
    var previewFrozenTime: Double? {
        get { self[FrozenTimeKey.self] }
        set { self[FrozenTimeKey.self] = newValue }
    }
}

/// A drawn Swarm 75 that plays an approximation of the chosen effect. Purely visual: it never
/// reads the keyboard, and reactive effects are shown with simulated key presses.
public struct KeyboardPreview: View {
    let settings: LightingSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.previewFrozenTime) private var frozenTime

    public init(settings: LightingSettings) { self.settings = settings }
    // Only animate while the window is in front; in the background the preview costs nothing.
    @Environment(\.controlActiveState) private var activeState

    private var paused: Bool { reduceMotion || activeState == .inactive }

    private static let rows: [[Double]] = [
        Array(repeating: 1, count: 16),
        Array(repeating: 1, count: 13) + [2, 1],
        [1.5] + Array(repeating: 1, count: 12) + [1.5, 1],
        [1.75] + Array(repeating: 1, count: 11) + [2.25, 1],
        [2.25] + Array(repeating: 1, count: 10) + [1.75, 1, 1],
        [1.25, 1.25, 1.25, 6.25, 1, 1, 1, 1, 1, 1],
    ]

    private struct Key { let rect: CGRect; let cx: Double; let cy: Double; let index: Int }

    private static let layout: [(x: Double, y: Double, w: Double)] = {
        var out: [(Double, Double, Double)] = []
        for (r, row) in rows.enumerated() {
            var x = 0.0
            for w in row { out.append((x, Double(r), w)); x += w }
        }
        return out
    }()

    public var body: some View {
        Group {
            if let frozenTime {
                Canvas { g, size in draw(&g, size: size, t: frozenTime) }
            } else {
                TimelineView(.animation(minimumInterval: 1 / 15, paused: paused || settings.effect == 1)) { ctx in
                    Canvas { g, size in
                        draw(&g, size: size, t: reduceMotion ? 1.5 : ctx.date.timeIntervalSinceReferenceDate)
                    }
                    .drawingGroup()  // rasterize on the GPU so each frame is one layer update
                }
            }
        }
        .aspectRatio(16.0 / 6.4, contentMode: .fit)
        .padding(14)
        .background(Theme.plate, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("Keyboard preview")
    }

    private func draw(_ g: inout GraphicsContext, size: CGSize, t: Double) {
        let unit = size.width / 16
        let gap = max(2, unit * 0.09)
        let keys: [Key] = Self.layout.enumerated().map { i, k in
            let rect = CGRect(x: k.x * unit + gap / 2, y: k.y * unit * 1.0 + gap / 2,
                              width: k.w * unit - gap, height: unit - gap)
            return Key(rect: rect, cx: k.x + k.w / 2, cy: k.y, index: i)
        }
        let speed = 0.25 + Double(settings.speed) / 100 * 1.5
        let brightness = Double(settings.brightness) / 100

        for k in keys {
            let (rgb, level) = light(k, count: keys.count, t: t * speed)
            let v = max(0, min(1, level)) * brightness
            let shape = Path(roundedRect: k.rect, cornerRadius: unit * 0.16)
            g.fill(shape, with: .color(Theme.cap))
            g.stroke(shape, with: .color(Theme.capEdge), lineWidth: 0.5)
            guard v > 0.02 else { continue }
            let lit = Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2)
            // Light spills up from the bottom edge of each cap, like a real per-key LED.
            g.fill(shape, with: .linearGradient(
                Gradient(colors: [lit.opacity(0.18 * v), lit.opacity(0.55 * v)]),
                startPoint: CGPoint(x: k.rect.midX, y: k.rect.minY),
                endPoint: CGPoint(x: k.rect.midX, y: k.rect.maxY)))
            let glow = CGRect(x: k.rect.minX + unit * 0.12, y: k.rect.maxY - unit * 0.16,
                              width: k.rect.width - unit * 0.24, height: unit * 0.08)
            g.fill(Path(roundedRect: glow, cornerRadius: unit * 0.04), with: .color(lit.opacity(v)))
        }
    }

    private func light(_ k: Key, count: Int, t: Double) -> ((Double, Double, Double), Double) {
        let base = (Double(settings.color.r) / 255, Double(settings.color.g) / 255, Double(settings.color.b) / 255)
        switch settings.effect {
        case 1:
            return (base, 1)
        case 2, 11:
            return (hue(k.cx * 22 - t * 90), 1)
        case 3:
            return (hue(t * 40), 0.5 + 0.5 * sin(t * 2.4))
        case 7, 12:
            // Simulated presses: a new key every 0.7s, chosen deterministically.
            var level = 0.0
            let beat = 0.7
            for back in 0..<3 {
                let n = floor(t / beat) - Double(back)
                let pressed = Self.layout[Int(abs(n * 7919).truncatingRemainder(dividingBy: Double(count)))]
                let age = t - n * beat
                let px = pressed.x + pressed.w / 2, py = pressed.y
                if settings.effect == 7 {
                    let d = hypot(k.cx - px, (k.cy - py) * 1.1)
                    level = max(level, exp(-pow(d - age * 9, 2) / 1.4) * max(0, 1 - age / 2))
                } else if abs(k.cx - px) < 0.6 && k.cy == py {
                    level = max(level, exp(-age * 1.8))
                }
            }
            return (base, level)
        case 10:
            let head = (t * 14).truncatingRemainder(dividingBy: Double(count))
            let d = (head - Double(k.index) + Double(count)).truncatingRemainder(dividingBy: Double(count))
            return (base, max(0, 1 - d / 8))
        default:
            let along: Double
            switch settings.effect {
            case 6: along = k.cx * 0.4 + k.cy * 0.9
            case 13: along = k.cy * 1.8
            case 15: along = hypot(k.cx - 8, k.cy * 2 - 5) * 0.8
            default: along = k.cx * 0.45
            }
            let direction = settings.effect == 8 ? -1.0 : 1.0
            let pace = settings.effect == 4 ? 0.5 : 1.0
            let jitter = settings.effect == 5 ? 0.6 * sin(k.cy * 2.7 + k.cx * 1.3 + t) : 0
            return (base, 0.5 + 0.5 * sin(along + jitter - direction * t * 3.2 * pace))
        }
    }

    private func hue(_ degrees: Double) -> (Double, Double, Double) {
        let h = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 60
        let x = 1 - abs(h.truncatingRemainder(dividingBy: 2) - 1)
        switch Int(h) {
        case 0: return (1, x, 0)
        case 1: return (x, 1, 0)
        case 2: return (0, 1, x)
        case 3: return (0, x, 1)
        case 4: return (x, 0, 1)
        default: return (1, 0, x)
        }
    }
}
