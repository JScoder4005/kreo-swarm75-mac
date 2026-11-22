import time

VID, PID = 0x258A, 0x010C
VENDOR_PAGE, INTERFACE = 0xFF00, 1


def open_keyboard():
    import hid
    for d in hid.enumerate(VID, PID):
        if d.get("usage_page") == VENDOR_PAGE and d.get("interface_number") == INTERFACE:
            h = hid.device()
            h.open_path(d["path"])
            return h
    raise SystemExit(
        "Kreo Swarm vendor interface not found. Connect the USB cable (Bluetooth does not expose it) "
        "and allow your terminal under System Settings > Privacy & Security > Input Monitoring."
    )


def send(palette, mode):
    h = open_keyboard()
    try:
        h.send_feature_report(palette)
        time.sleep(0.05)
        h.send_feature_report(mode)
    finally:
        h.close()
