// node tests/web_parity.mjs  -- checks web/protocol.js builds the same bytes as kreo/protocol.py
import { buildReports } from "../web/protocol.js";
import { execFileSync } from "node:child_process";

const cases = [
  { color: [255, 0, 0], mode: 1, brightness: 80, speed: 50 },
  { color: [0, 170, 255], mode: 3, brightness: 10, speed: 0 },
  { color: [1, 2, 3], mode: 12, brightness: 100, speed: 100 },
  { color: [9, 9, 9], mode: 5, brightness: 30, speed: 75 },  // .5 rounding cases
];
let bad = 0;
for (const c of cases) {
  const py = JSON.parse(execFileSync(".venv/bin/python", ["-c", `
import json
from kreo.protocol import build_reports
p,m = build_reports(bytes(${JSON.stringify(c.color)}), ${c.mode}, ${c.brightness}, ${c.speed})
print(json.dumps([p.hex(), m.hex()]))`]));
  const js = buildReports(c);
  const hex = (u) => Buffer.from(u).toString("hex");
  const ok = hex(js.pal) === py[0] && hex(js.mode) === py[1] && js.pal.length === 520 && js.mode.length === 520;
  console.log(ok ? "ok  " : "FAIL", JSON.stringify(c));
  if (!ok) bad++;
}
process.exit(bad ? 1 : 0);
