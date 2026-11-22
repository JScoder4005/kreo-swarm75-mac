import Foundation
import IOKit.hid
import KreoCore
import os

let log = Logger(subsystem: "com.jscoder4005.swarmglow", category: "hid")

/// Watches for the Swarm75's USB vendor interface and sends lighting reports to it.
/// Only report ID 0x06 (palette 06 0A, mode 06 04) is ever sent.
final class KeyboardLink: ObservableObject {
    static let supportedProduct = "Kreo Swarm"

    @Published private(set) var connected = false
    /// Set when macOS refuses access, so the window can say why instead of "not on cable".
    @Published private(set) var problem: String?
    var onAttach: (() -> Void)?

    private let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    private var device: IOHIDDevice?

    init() {
        // The vendor collection (page 0xFF00) shares USB interface 1 with keyboard collections, so macOS
        // reports that interface's primary page as 0x0001. Match on any usage pair, not the primary page.
        let match: [String: Any] = [
            kIOHIDVendorIDKey: 0x258A,
            kIOHIDProductIDKey: 0x010C,
            kIOHIDDeviceUsagePageKey: 0xFF00,
        ]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { ctx, _, _, dev in
            Unmanaged<KeyboardLink>.fromOpaque(ctx!).takeUnretainedValue().attached(dev)
        }, ctx)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { ctx, _, _, dev in
            Unmanaged<KeyboardLink>.fromOpaque(ctx!).takeUnretainedValue().removed(dev)
        }, ctx)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        // The lighting interface shares a USB interface with keyboard collections, so macOS
        // treats access as Input Monitoring. Ask for it; this shows the system prompt once.
        let access = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
        log.notice("input monitoring access: \(access.rawValue, privacy: .public)")
        if access != kIOHIDAccessTypeGranted {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
            problem = "Allow Kreo in System Settings > Privacy & Security > Input Monitoring, then reopen Kreo."
        }
        let rc = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        log.notice("manager open: \(String(format: "0x%08x", rc), privacy: .public)")
        if rc != kIOReturnSuccess {
            problem = String(format: "macOS blocked keyboard access (0x%08x). Allow Kreo in Input Monitoring, then reopen Kreo.", rc)
        }
    }

    @discardableResult
    func send(_ settings: LightingSettings) -> Bool {
        guard let dev = device else { return false }
        let (palette, mode) = KreoProtocol.buildReports(settings)
        guard setFeature(dev, palette) else { log.error("palette report failed"); return false }
        usleep(50_000)
        let ok = setFeature(dev, mode)
        log.notice("sent effect \(settings.effect, privacy: .public): \(ok ? "ok" : "mode report failed", privacy: .public)")
        return ok
    }

    private func setFeature(_ dev: IOHIDDevice, _ report: [UInt8]) -> Bool {
        // Like hidapi: the buffer starts with the report ID and the ID is also passed separately.
        report.withUnsafeBufferPointer { buf in
            IOHIDDeviceSetReport(dev, kIOHIDReportTypeFeature, CFIndex(report[0]), buf.baseAddress!, buf.count) == kIOReturnSuccess
        }
    }

    private func attached(_ dev: IOHIDDevice) {
        // The Kreo Hive 75 and Hive 98 share this VID/PID; the Swarm reports were never tested on them.
        let name = IOHIDDeviceGetProperty(dev, kIOHIDProductKey as CFString) as? String ?? ""
        guard name.hasPrefix(Self.supportedProduct) else {
            log.notice("ignored unsupported keyboard: \(name, privacy: .public)")
            problem = "Found \"\(name)\". Only the Kreo Swarm 75 is supported, so nothing will be sent."
            return
        }
        log.notice("keyboard attached")
        device = dev
        connected = true
        problem = nil
        // Give the keyboard a moment after enumeration before talking to it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in self?.onAttach?() }
    }

    private func removed(_ dev: IOHIDDevice) {
        guard dev == device else { return }
        device = nil
        connected = false
    }
}
