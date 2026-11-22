// Passive listener for the Swarm75's Bluetooth vendor report (ID 0x13). Sends nothing.
// Opens the device non-exclusively so typing keeps working. Only report 0x13 is printed;
// other reports (keystrokes etc.) are counted, never logged.
// usage: swift tools/ble_listen.swift [seconds]
import Foundation
import IOKit.hid

let vid = 0x3554, pid = 0xFA07, vendorReport: UInt32 = 0x13
let seconds = Double(CommandLine.arguments.dropFirst().first ?? "60") ?? 60
setvbuf(stdout, nil, _IOLBF, 0)  // line-buffered so output shows live when redirected to a file
var otherCounts: [UInt32: Int] = [:]
let start = Date()

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey: vid, kIOHIDProductIDKey: pid] as CFDictionary)

let callback: IOHIDReportCallback = { _, result, _, _, reportID, report, length in
    if reportID == vendorReport {
        let bytes = (0..<length).map { String(format: "%02x", report[$0]) }.joined(separator: " ")
        print(String(format: "+%6.2fs  0x13 len=%d  %@", Date().timeIntervalSince(start), length, bytes))
    } else {
        otherCounts[reportID, default: 0] += 1
    }
}

IOHIDManagerRegisterDeviceMatchingCallback(manager, { _, _, _, device in
    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 256)
    IOHIDDeviceRegisterInputReportCallback(device, buf, 256, callback, nil)
    let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "?"
    let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? "?"
    print("attached: \(name) (\(transport))")
}, nil)

IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
let rc = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
print(rc == kIOReturnSuccess ? "listening \(Int(seconds))s (non-exclusive)..." : String(format: "open failed: 0x%08x", rc))
fflush(stdout)

CFRunLoopRunInMode(CFRunLoopMode.defaultMode, seconds, false)
print("done. other reports received (counts only):", otherCounts.sorted { $0.key < $1.key }.map { "id \($0.key): \($0.value)" })
