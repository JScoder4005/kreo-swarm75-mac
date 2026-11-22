"""Extract HID SET_REPORT(feature) payloads from a USBPcap capture (stdlib only)."""
import struct, sys, json

def records(path):
    d = open(path, 'rb').read()
    assert d[:4] == b'\xd4\xc3\xb2\xa1'
    off = 24
    while off + 16 <= len(d):
        ts_s, ts_u, cap, _ = struct.unpack_from('<IIII', d, off)
        off += 16
        yield ts_s + ts_u / 1e6, d[off:off + cap]
        off += cap

def parse(path):
    out = []
    for i, (ts, p) in enumerate(records(path)):
        if len(p) < 27:
            continue
        hlen, irp, status, func, info, bus, dev, ep, ttype, dlen = struct.unpack_from('<HQIHBHHBBI', p, 0)
        row = dict(n=i, ts=ts, dev=dev, ep=ep, ttype=ttype, info=info, hlen=hlen, dlen=dlen)
        if ttype == 2 and hlen >= 28:
            stage = p[27]
            row['stage'] = stage
            if stage == 0 and len(p) >= 36:
                bm, br, wv, wi, wl = struct.unpack_from('<BBHHH', p, 28)
                row.update(bm=bm, br=br, wv=wv, wi=wi, wl=wl)
            row['data'] = p[hlen:hlen + dlen] if stage != 0 else p[hlen + 8:]
        else:
            row['data'] = p[hlen:]
        out.append(row)
    return out

if __name__ == '__main__':
    rows = parse(sys.argv[1])
    from collections import Counter
    print(len(rows), 'records')
    print(Counter((r['ttype'], r['ep'], r.get('bm'), r.get('br')) for r in rows).most_common(30))
