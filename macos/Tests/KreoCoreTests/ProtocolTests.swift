import Foundation
import XCTest
@testable import KreoCore

final class ProtocolTests: XCTestCase {
    struct Golden: Decodable {
        let color: [UInt8]; let effect: Int; let brightness: Int; let speed: Int
        let palette: String; let mode: String
    }

    func testMatchesPythonBuilder() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "golden", withExtension: "json"))
        let cases = try JSONDecoder().decode([Golden].self, from: Data(contentsOf: url))
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let s = LightingSettings(color: RGB(c.color[0], c.color[1], c.color[2]),
                                     effect: c.effect, brightness: c.brightness, speed: c.speed)
            let (pal, mode) = KreoProtocol.buildReports(s)
            XCTAssertEqual(hex(pal), c.palette, "palette for \(c.effect)/\(c.brightness)/\(c.speed)")
            XCTAssertEqual(hex(mode), c.mode, "mode for \(c.effect)/\(c.brightness)/\(c.speed)")
        }
    }

    func testReportShape() {
        let (pal, mode) = KreoProtocol.buildReports(LightingSettings())
        XCTAssertEqual(pal.count, KreoProtocol.reportLength)
        XCTAssertEqual(mode.count, KreoProtocol.reportLength)
        XCTAssertEqual(Array(pal.prefix(2)), [0x06, 0x0A])
        XCTAssertEqual(Array(mode.prefix(2)), [0x06, 0x04])
    }

    func testOutOfRangePercentsClamp() {
        XCTAssertEqual(KreoProtocol.scaled(150, to: 255), 255)
        XCTAssertEqual(KreoProtocol.scaled(-5, to: 255), 0)
    }

    private func hex(_ b: [UInt8]) -> String { b.map { String(format: "%02x", $0) }.joined() }
}
