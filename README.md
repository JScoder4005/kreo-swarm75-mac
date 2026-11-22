# kreo-swarm75-mac

Control the RGB lighting of a **Kreo Swarm75** keyboard from a Mac. Kreo's own software is Windows-only.

<p align="center">
  <img src="docs/preview.svg" alt="Animated rainbow wave across a keyboard preview" width="760">
</p>

- A command-line tool: `kreo set --color ff0000 --mode static --brightness 80`
- A web page (WebHID, Chrome) with a live keyboard preview, color picker, effect list, sliders and saved profiles
- Documented protocol notes, decoded from a Windows capture and tested byte by byte on real hardware

> **Status:** works over **USB**. Lighting set over USB stays in the keyboard, so it survives unplugging and
> Bluetooth. **Live control over Bluetooth does not work** (see [Limitations](#limitations)).
> Tested on one keyboard and one Mac. Not affiliated with Kreo.

## Quick start

```sh
git clone https://github.com/JScoder4005/kreo-swarm75-mac.git
cd kreo-swarm75-mac
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt      # installs hidapi, nothing else
```

Plug the keyboard in with the cable (Bluetooth does not expose the lighting interface).
If macOS blocks access, allow your terminal under **System Settings > Privacy & Security > Input Monitoring**.

### Command line

```sh
bin/kreo set --color ff0000 --mode static --brightness 80
bin/kreo set --color 00aaff --mode breathing
bin/kreo set --mode rainbow-wave --speed 40
bin/kreo set --mode 11                      # any effect number 1-15
bin/kreo modes                              # list named effects
bin/kreo set --color 00ff00 --dry-run       # print the reports, send nothing
```

| Option | Values |
|---|---|
| `--color` | `RRGGBB` hex. Ignored by rainbow effects |
| `--mode` | `static`, `rainbow-wave`, `breathing`, `ripple`, `snake`, `trail`, or a number 1-15 |
| `--brightness` | 0-100 |
| `--speed` | 0-100, animated effects only |
| `--raw INDEX=VALUE` | override one byte of the mode report (for experiments) |

### Web page

```sh
cd web && python3 -m http.server 8765 --bind 127.0.0.1
```

Open `http://127.0.0.1:8765/` in **Chrome** (or Edge; Safari and Firefox have no WebHID), click **Connect keyboard**
and choose *Kreo Swarm*. The preview works without a keyboard attached; the status line tells you whether anything
was actually sent.

## What was decoded

Full detail and evidence in [PROTOCOL.md](PROTOCOL.md).

| Setting | Where | Values |
|---|---|---|
| Color | report `06 0A`, bytes 29-31 | R, G, B |
| Effect | report `06 04`, byte 18 | 1-15 (see the table in PROTOCOL.md) |
| Speed | report `06 04`, byte 19 | `0x00` slow, `0x08` medium, `0x80`+ fast (clamps) |
| Brightness | report `06 04`, byte 31 | `0x10` dim to `0xFF` full |

Only two report types are ever sent: `06 0A` (palette) and `06 04` (mode), each 520 bytes, in the exact format
captured from the Windows app. Nothing else is sent: no firmware commands, no unknown report IDs.

## Limitations

- **USB only.** Over Bluetooth the keyboard shows up as a different device (`0x3554:0xFA07`) whose only vendor channel
  is a 19-byte report (ID `0x13`). The lighting protocol there is unknown, and Chrome's WebHID blocks Bluetooth keyboards.
- **Direction is not decoded.** Several "wave" effects (4, 5, 6, 8, 11, 13, 15) look alike and probably differ in
  direction, speed or palette. Only six effects have names.
- **Speed and brightness steps are approximate.** The exact clamp point for speed and what brightness `0` does are untested.
- The web preview **approximates** the effects; it is a simulation, not a read-back from the keyboard.
- **Key remapping** is not implemented and has not been investigated.
- One keyboard, one macOS machine. Firmware revisions may differ.

## Development

```sh
.venv/bin/python -m unittest discover -s tests -t .     # protocol builder tests (no hardware)
node tests/web_parity.mjs                               # JS builder produces the same bytes as Python
.venv/bin/python tools/probe.py --index 18 --values 1,2,3 --hold 6    # sweep a byte, restores static red after
```

```
kreo/        protocol builder, device access, CLI
web/         WebHID page (index.html, app.js, preview.js, protocol.js)
tools/       pcap extractor (stdlib), byte probe helpers
tests/       unit tests
PROTOCOL.md  decoded protocol and evidence
```

## Credits

The USB IDs, the vendor interface and the first working report replay come from
[yashsinghcodes/kreo-backlight](https://github.com/yashsinghcodes/kreo-backlight), whose Windows capture this
project analysed. That repository has no license, so its code and capture are not copied here.

## Disclaimer

Sends HID feature reports to your keyboard. The reports match the captured format and were limited to the
lighting commands, but use it at your own risk.

## License

[MIT](LICENSE)
