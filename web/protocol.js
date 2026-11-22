import { PALETTE_BASE, MODE_BASE } from "./payloads.js";

export const COLOR_OFFSET = 29;
export const MODE_OFFSET = 18;
export const SPEED_OFFSET = 19;
export const BRIGHTNESS_OFFSET = 31;
export const SPEED_MAX = 0x20;

// Names only where behaviour was confirmed on hardware; the rest are numbered.
export const MODES = [
  [1, "Static"], [2, "Rainbow wave"], [3, "Breathing"], [7, "Ripple (on keypress)"],
  [10, "Snake"], [12, "Trail (on keypress)"],
  [4, "Mode 4 (slow wave)"], [5, "Mode 5 (irregular wave)"], [6, "Mode 6 (wave)"],
  [8, "Mode 8 (wave)"], [11, "Mode 11 (wave)"], [13, "Mode 13 (wave)"], [15, "Mode 15 (wave-like)"],
];

const fromHex = (h) => Uint8Array.from(h.match(/../g), (b) => parseInt(b, 16));

// Same result as kreo/protocol.py build_reports(). Returns full 520-byte reports (ID in byte 0).
export function buildReports({ color = [255, 0, 0], mode = 1, brightness = null, speed = null } = {}) {
  const pal = fromHex(PALETTE_BASE);
  pal.set(color, COLOR_OFFSET);
  const m = fromHex(MODE_BASE);
  m[MODE_OFFSET] = mode;
  if (brightness !== null) m[BRIGHTNESS_OFFSET] = Math.round((brightness * 255) / 100);
  if (speed !== null) m[SPEED_OFFSET] = Math.round((speed * SPEED_MAX) / 100);
  return { pal, mode: m };
}

export function hexToRgb(hex) {
  const s = hex.replace("#", "");
  return [0, 2, 4].map((i) => parseInt(s.slice(i, i + 2), 16));
}
