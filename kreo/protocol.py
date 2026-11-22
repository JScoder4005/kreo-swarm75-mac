"""Build the two feature reports the keyboard accepts. No I/O here."""
from .payloads import PALETTE_BASE, MODE_BASE

REPORT_LEN = 520
COLOR_OFFSET = 29        # 06 0A: R G B
MODE_OFFSET = 18         # 06 04: effect id
SPEED_OFFSET = 19        # 06 04: 0x00 slow ... clamps well below 0x80
BRIGHTNESS_OFFSET = 31   # 06 04: 0x10 dim ... 0xFF full

SPEED_MAX = 0x20         # capture default; the real clamp point is somewhere in 0x20..0x80

# Names only for modes whose behaviour was confirmed on hardware. Others: use the number.
MODES = {
    "static": 1,
    "rainbow-wave": 2,
    "breathing": 3,
    "ripple": 7,
    "snake": 10,
    "trail": 12,
}
MODE_RANGE = range(1, 16)


def parse_color(text):
    s = text.lstrip("#")
    if len(s) != 6:
        raise ValueError(f"color must be 6 hex digits, got {text!r}")
    return bytes.fromhex(s)


def parse_mode(text):
    if text in MODES:
        return MODES[text]
    try:
        n = int(text, 0)
    except ValueError:
        raise ValueError(f"unknown mode {text!r}; use one of {', '.join(MODES)} or a number 1-15")
    if n not in MODE_RANGE:
        raise ValueError(f"mode number must be 1-15, got {n}")
    return n


def pct(value, name):
    if not 0 <= value <= 100:
        raise ValueError(f"{name} must be 0-100, got {value}")
    return value


def build_reports(color=b"\xff\x00\x00", mode=1, brightness=None, speed=None, raw=()):
    """Return (palette_report, mode_report). brightness/speed are percents, None = keep capture default."""
    pal = bytearray(PALETTE_BASE)
    pal[COLOR_OFFSET:COLOR_OFFSET + 3] = color
    m = bytearray(MODE_BASE)
    m[MODE_OFFSET] = mode
    if brightness is not None:
        m[BRIGHTNESS_OFFSET] = round(pct(brightness, "brightness") * 255 / 100)
    if speed is not None:
        m[SPEED_OFFSET] = round(pct(speed, "speed") * SPEED_MAX / 100)
    for index, value in raw:
        if not 0 < index < REPORT_LEN or not 0 <= value <= 255:
            raise ValueError(f"bad raw override {index}={value}")
        m[index] = value
    assert len(pal) == len(m) == REPORT_LEN
    return bytes(pal), bytes(m)
