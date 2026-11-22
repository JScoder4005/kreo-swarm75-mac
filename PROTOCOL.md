# Kreo Swarm75 HID protocol notes

Device over USB: VID `0x258A`, PID `0x010C`, vendor interface 1 (usage page `0xFF00`).

Sources: the USBPcap capture of the Windows app from
[yashsinghcodes/kreo-backlight](https://github.com/yashsinghcodes/kreo-backlight)
(`swarmkreo/capture.pcap`, not redistributed here), parsed with `tools/extract.py` (stdlib only),
plus byte-probing on real hardware.

Legend: **CONFIRMED** = seen in the capture or tested on hardware. **HYPOTHESIS** = a guess.
Everything below was observed on one keyboard (Swarm75, USB), one macOS machine.

## Transport (USB)

- HID `SET_REPORT` (feature): `bmRequestType=0x21, bRequest=0x09, wValue=0x0306, wIndex=1, wLength=0x208`. CONFIRMED.
- Report ID `0x06`, 520 bytes including the ID byte. CONFIRMED.
- Readback: `GET_REPORT` (`0xA1, 0x01`, same wValue/wIndex). CONFIRMED in the capture.
- Reports end with the marker `5a a5 00 00 00 00` near the tail (offset 513 for `0A`, 130 for `04`).

## Reports seen in the capture

| Byte 1 | Name (guess) | Direction | Notes |
|---|---|---|---|
| `82` | query / handshake | SET then GET (14 byte reply) | once; purpose unknown, **not sent by this project** |
| `84` | read current mode config | SET then GET (136 byte reply) | the reply is the current `04` report; **not sent by this project** |
| `04` | mode / effect config | SET | sent by this project |
| `0A` | color palette | SET | sent by this project |

The Windows app sends `84` (read), then `04`, then `0A` on each apply. This project sends only `0A` then `04`,
which works on hardware.

## 06 0A (palette)

- Header `06 0a 00 00 01 00 00 02`, then zeros. CONFIRMED.
- Bytes 29, 30, 31 = `R G B`. CONFIRMED on hardware (static color changes).
- From offset 29 the report looks like a table of 4-byte entries (`fef7f500, ff000000, ffffff00, ...`).
  HYPOTHESIS: entry 0 is the primary color, the rest are per-effect colors. Not tested.

## 06 04 (mode)

Base header: `06 04 00 00 01 00 80 00 00 03 03 01 00 00 04 04 07 00 ...`

| Byte | Meaning | Evidence |
|---|---|---|
| 18 | effect / mode | CONFIRMED. Values 1-15 tested, see below |
| 19 | speed | CONFIRMED. `0x00` slow, `0x08` medium, `0x80` and `0xFF` fast and identical (clamps) |
| 31 | brightness | CONFIRMED. `0x10` dim, `0x80` brighter, `0xFF` full (capture default). `0x00` untested |
| 20 | no visible effect | tested `0x00` and `0xFF` in mode 2 (rainbow wave): no change |

### Mode values (byte 18)

Descriptions are what the keyboard's owner reported seeing, one value at a time at default color/speed.

| Value | Observed |
|---|---|
| 1 | static color |
| 2 | rainbow wave |
| 3 | breathing, colors changing |
| 4 | slow wave |
| 5 | irregular wave |
| 6 | wave |
| 7 | key press spreads color outward (ripple) |
| 8 | wave |
| 9 | lights off |
| 10 | snake |
| 11 | wave |
| 12 | pressed key's light flows out (trail) |
| 13 | wave |
| 14 | lights off |
| 15 | wave-like |

Values above 15 were not tested. Several "wave" entries probably differ in direction, speed or palette; not resolved.

### Not decoded

- Direction. Bytes 20-30 and the key table from offset 64 (`ff ff 03 40 04 47 ...`) are unprobed or showed no effect in one mode.
- Exact speed steps (the clamp is somewhere between `0x08` and `0x80`).
- Brightness `0x00` behaviour.
- Whether modes 9 and 14 are real "off" modes or unsupported values.

## Bluetooth

Over BLE the keyboard enumerates as a **different device**: `Kreo Swarm 5.0`, VID `0x3554`, PID `0xFA07`.
The report descriptor (read from macOS `ioreg`, nothing sent) has:

- keyboard (report ID 1, with LED output), a 160-bit key bitmap (ID 2), consumer control (ID 3), system control (ID 4), mouse (ID 5),
- one vendor collection: usage page `0xFF02`, usage `0x02`, **report ID `0x13`, 19 bytes, Input and Output**. No Feature reports.

The 520-byte USB feature reports cannot be sent over it. The Bluetooth command protocol is unknown and nothing in the
capture uses it. Lighting set over USB persists after switching to Bluetooth. WebHID in Chrome generally cannot access
Bluetooth keyboards.

## Safety

Only report IDs `04` and `0A` are ever sent, in the captured format. Do not send other IDs without a reason:
nothing here has been checked against firmware update or key-remap commands.

## How to decode more

Capture the Windows app (USBPcap + Wireshark) changing ONE setting at a time, cabled: each direction option,
brightness steps, speed steps, each effect, per-effect colors. Diff the `06 04` and `06 0A` payloads.
Key remapping has not been looked at.
