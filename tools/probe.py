"""Probe the 06 04 mode report: change one byte at a time, hold, restore baseline.

Only sends report IDs 06 0A (palette) and 06 04 (mode), using the base payloads in kreo/payloads.py.
usage: python tools/probe.py --index 18 --values 1,2,3 [--hold 5] [--rgb 255,0,0]
"""
import argparse, sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
from kreo.payloads import PALETTE_BASE, MODE_BASE
from kreo.device import open_keyboard
from kreo.protocol import COLOR_OFFSET as SEED


def base_payloads():
    return bytearray(PALETTE_BASE), bytearray(MODE_BASE)


def open_kreo():
    return open_keyboard()


def apply(h, pal, mode, rgb):
    pal = bytearray(pal); pal[SEED:SEED + 3] = bytes(rgb)
    assert pal[:2] == b'\x06\x0a' and mode[:2] == b'\x06\x04' and len(pal) == len(mode) == 520
    h.send_feature_report(bytes(pal)); time.sleep(0.05); h.send_feature_report(bytes(mode))


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--index', type=int, required=True)
    ap.add_argument('--values', required=True)
    ap.add_argument('--hold', type=float, default=5)
    ap.add_argument('--rgb', default='255,0,0')
    a = ap.parse_args()
    rgb = [int(x) for x in a.rgb.split(',')]
    pal, mode = base_payloads()
    h = open_kreo()
    try:
        for v in [int(x, 0) for x in a.values.split(',')]:
            m = bytearray(mode); m[a.index] = v
            print(f'byte[{a.index}]={v:#04x} ...', flush=True)
            apply(h, pal, m, rgb); time.sleep(a.hold)
    finally:
        apply(h, pal, mode, [255, 0, 0]); h.close(); print('restored baseline (mode 1, red)')
