import unittest
from kreo import protocol as p
from kreo.cli import main


class ProtocolTests(unittest.TestCase):
    def test_lengths_and_ids(self):
        pal, mode = p.build_reports()
        self.assertEqual((len(pal), pal[:2]), (520, b"\x06\x0a"))
        self.assertEqual((len(mode), mode[:2]), (520, b"\x06\x04"))

    def test_color_mode_brightness_speed(self):
        pal, mode = p.build_reports(p.parse_color("#00ff80"), 2, brightness=50, speed=100)
        self.assertEqual(pal[29:32], bytes([0, 255, 128]))
        self.assertEqual(mode[18], 2)
        self.assertEqual(mode[31], 128)
        self.assertEqual(mode[19], 0x20)

    def test_only_intended_bytes_change(self):
        base_pal, base_mode = p.build_reports()
        pal, mode = p.build_reports(b"\x01\x02\x03", 3, 10, 10)
        diff = lambda a, b: {i for i in range(520) if a[i] != b[i]}
        self.assertLessEqual(diff(base_pal, pal), {29, 30, 31})
        self.assertLessEqual(diff(base_mode, mode), {18, 19, 31})

    def test_defaults_match_capture(self):
        from kreo.payloads import MODE_BASE
        self.assertEqual(p.build_reports()[1], MODE_BASE)

    def test_validation(self):
        for bad in (lambda: p.parse_color("fff"), lambda: p.parse_mode("nope"),
                    lambda: p.parse_mode("16"), lambda: p.build_reports(brightness=101),
                    lambda: p.build_reports(raw=[(0, 1)])):
            with self.assertRaises(ValueError):
                bad()

    def test_cli_dry_run(self):
        self.assertEqual(main(["set", "--color", "ff0000", "--mode", "static", "--brightness", "80", "--dry-run"]), 0)


if __name__ == "__main__":
    unittest.main()
