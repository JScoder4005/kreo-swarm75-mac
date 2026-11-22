"""Send palette + mode report with byte overrides, and hold. usage: send.py 18=3 [19=0x10 ...]"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import probe

pal, mode = probe.base_payloads()
m = bytearray(mode)
for arg in sys.argv[1:]:
    i, v = arg.split('=')
    m[int(i)] = int(v, 0)
h = probe.open_kreo()
probe.apply(h, pal, m, [255, 0, 0]); h.close()
print('sent', ' '.join(sys.argv[1:]))
