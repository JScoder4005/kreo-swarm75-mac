// Builds the two feature reports the keyboard accepts. Same bytes as kreo/protocol.py. No I/O here.

public struct RGB: Codable, Equatable, Sendable {
    public var r: UInt8, g: UInt8, b: UInt8
    public init(_ r: UInt8, _ g: UInt8, _ b: UInt8) { self.r = r; self.g = g; self.b = b }
}

public struct LightingSettings: Codable, Equatable, Sendable {
    public var color: RGB
    public var effect: Int      // byte 18 of report 06 04
    public var brightness: Int  // 0-100
    public var speed: Int       // 0-100

    public init(color: RGB = RGB(255, 0, 0), effect: Int = 1, brightness: Int = 100, speed: Int = 50) {
        self.color = color; self.effect = effect; self.brightness = brightness; self.speed = speed
    }
}

public struct Effect: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let animated: Bool
}

public enum KreoProtocol {
    public static let reportLength = 520
    static let colorOffset = 29        // 06 0A: R G B
    static let effectOffset = 18       // 06 04
    static let speedOffset = 19        // 06 04
    static let brightnessOffset = 31   // 06 04
    static let speedMax = 0x20

    /// Effects as observed on the keyboard (byte 18 values). Unnamed ones were all wave variants.
    public static let effects: [Effect] = [
        Effect(id: 1, name: "Static", animated: false),
        Effect(id: 2, name: "Rainbow wave", animated: true),
        Effect(id: 3, name: "Breathing", animated: true),
        Effect(id: 7, name: "Ripples (on key press)", animated: true),
        Effect(id: 10, name: "Retro snake", animated: true),
        Effect(id: 12, name: "Trail (on key press)", animated: true),
        Effect(id: 4, name: "Slow wave", animated: true),
        Effect(id: 5, name: "Irregular wave", animated: true),
        Effect(id: 6, name: "Wave 6", animated: true),
        Effect(id: 8, name: "Wave 8", animated: true),
        Effect(id: 11, name: "Wave 11", animated: true),
        Effect(id: 13, name: "Wave 13", animated: true),
        Effect(id: 15, name: "Wave 15", animated: true),
    ]

    public static func buildReports(_ s: LightingSettings) -> (palette: [UInt8], mode: [UInt8]) {
        var pal = bytes(Payloads.paletteHex)
        pal[colorOffset] = s.color.r
        pal[colorOffset + 1] = s.color.g
        pal[colorOffset + 2] = s.color.b
        var mode = bytes(Payloads.modeHex)
        mode[effectOffset] = UInt8(clamping: s.effect)
        mode[brightnessOffset] = scaled(s.brightness, to: 255)
        mode[speedOffset] = scaled(s.speed, to: speedMax)
        return (pal, mode)
    }

    // Round half up, matching the Python and JS builders.
    static func scaled(_ percent: Int, to maximum: Int) -> UInt8 {
        let p = min(max(percent, 0), 100)
        return UInt8((Double(p * maximum) / 100 + 0.5).rounded(.down))
    }

    static func bytes(_ hex: String) -> [UInt8] {
        var out = [UInt8](); out.reserveCapacity(hex.count / 2)
        var i = hex.startIndex
        while i < hex.endIndex {
            let j = hex.index(i, offsetBy: 2)
            out.append(UInt8(hex[i..<j], radix: 16)!)
            i = j
        }
        return out
    }
}
