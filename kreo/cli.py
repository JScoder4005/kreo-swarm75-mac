import argparse
import sys

from . import protocol


def parse_raw(text):
    index, value = text.split("=")
    return int(index, 0), int(value, 0)


def main(argv=None):
    p = argparse.ArgumentParser(prog="kreo", description="Kreo Swarm75 lighting (USB only)")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("set", help="set color, mode, brightness, speed")
    s.add_argument("--color", default="ff0000", help="RRGGBB hex (default ff0000)")
    s.add_argument("--mode", default="static", help="name or number 1-15 (default static)")
    s.add_argument("--brightness", type=int, help="0-100")
    s.add_argument("--speed", type=int, help="0-100, effects only")
    s.add_argument("--raw", action="append", type=parse_raw, default=[], metavar="INDEX=VALUE",
                   help="override one byte of the 06 04 report (experiments)")
    s.add_argument("--dry-run", action="store_true", help="print the reports, send nothing")
    sub.add_parser("modes", help="list named modes")
    a = p.parse_args(argv)

    if a.cmd == "modes":
        for name, n in protocol.MODES.items():
            print(f"{name:14} {n}")
        print("others: numbers 1-15 (observed as waves or unverified)")
        return 0

    try:
        pal, mode = protocol.build_reports(
            protocol.parse_color(a.color), protocol.parse_mode(a.mode), a.brightness, a.speed, a.raw)
    except ValueError as e:
        p.error(str(e))
    if a.dry_run:
        print("06 0A:", pal[:40].hex(" "), "...")
        print("06 04:", mode[:40].hex(" "), "...")
        return 0
    from . import device
    device.send(pal, mode)
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
