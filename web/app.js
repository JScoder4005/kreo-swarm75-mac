import { MODES, buildReports, hexToRgb } from "./protocol.js";
import * as kb from "./device.js";
import { createPreview } from "./preview.js";
import { loadProfiles, saveProfiles } from "./profiles.js";

const $ = (id) => document.getElementById(id);
const SWATCHES = ["#ff3b3b", "#ff8a1f", "#ffd21f", "#3ddc84", "#17c8c8", "#2f7bff", "#8a5cff", "#ff4fd8", "#ffffff"];
const NO_COLOR_MODES = new Set([2, 11]); // rainbow-style effects ignore the chosen color
const PRESS_MODES = new Set([7, 12]);
const STORE = "kreo-last-v1";

const preview = createPreview($("keys"));
let dev = null, timer = null;
let s = { color: "#ff4d5e", mode: 1, brightness: 100, speed: 50 };
try { s = { ...s, ...JSON.parse(localStorage.getItem(STORE)) }; } catch { /* first run */ }

const setStatus = (text, state) => { $("status").textContent = text; $("conn").dataset.state = state ?? $("conn").dataset.state; };

function ink(rgb) { return (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) > 150 ? "#111" : "#fff"; }

function render() {
  const rgb = hexToRgb(s.color);
  preview.set({ rgb, mode: s.mode, brightness: s.brightness / 100, speed: s.speed / 100 });
  const bright = rgb.reduce((a, b) => a + b, 0) < 120 ? [140, 150, 180] : rgb;
  document.documentElement.style.setProperty("--accent", `rgb(${bright})`);
  document.documentElement.style.setProperty("--accent-ink", ink(bright));
  $("color").value = s.color;
  if (document.activeElement !== $("hex")) $("hex").value = s.color;
  $("bv").textContent = s.brightness + "%";
  $("sv").textContent = s.speed + "%";
  $("brightness").value = s.brightness;
  $("speed").value = s.speed;
  for (const b of $("modes").children) b.setAttribute("aria-pressed", String(Number(b.dataset.mode) === s.mode));
  for (const b of $("swatches").children) b.setAttribute("aria-pressed", String(b.dataset.c === s.color));
  $("colornote").textContent = NO_COLOR_MODES.has(s.mode) ? "This effect uses its own colors and ignores your pick." : "";
  $("hint").hidden = !PRESS_MODES.has(s.mode);
  try { localStorage.setItem(STORE, JSON.stringify(s)); } catch { /* storage blocked */ }
}

async function apply() {
  if (!dev) return;
  try {
    await kb.send(dev, buildReports({ color: hexToRgb(s.color), mode: s.mode, brightness: s.brightness, speed: s.speed }));
    setStatus("Sent to keyboard", "on");
  } catch (e) { setStatus("Send failed: " + e.message, "err"); }
}

function change(patch) {
  s = { ...s, ...patch };
  render();
  clearTimeout(timer);
  timer = setTimeout(apply, 80);
}

// controls
for (const [n, name] of MODES) {
  const b = Object.assign(document.createElement("button"), { className: "mode", textContent: name, type: "button" });
  b.dataset.mode = n; b.onclick = () => change({ mode: n });
  $("modes").append(b);
}
for (const c of SWATCHES) {
  const b = Object.assign(document.createElement("button"), { className: "sw", type: "button", title: c, ariaLabel: "Color " + c });
  b.dataset.c = c; b.style.background = c; b.onclick = () => change({ color: c });
  $("swatches").append(b);
}
$("color").addEventListener("input", (e) => change({ color: e.target.value }));
$("hex").addEventListener("input", (e) => {
  const v = e.target.value.startsWith("#") ? e.target.value : "#" + e.target.value;
  if (/^#[0-9a-f]{6}$/i.test(v)) change({ color: v.toLowerCase() });
});
$("hex").addEventListener("blur", render);
$("brightness").addEventListener("input", (e) => change({ brightness: Number(e.target.value) }));
$("speed").addEventListener("input", (e) => change({ speed: Number(e.target.value) }));

// profiles
let profiles = loadProfiles();
function renderProfiles() {
  const box = $("profiles");
  box.replaceChildren();
  if (!profiles.length) { box.append(Object.assign(document.createElement("p"), { className: "empty", textContent: "No profiles yet. Set a look, name it, and save it." })); return; }
  profiles.forEach((p, i) => {
    const wrap = Object.assign(document.createElement("span"), { className: "profile" });
    const use = Object.assign(document.createElement("button"), { type: "button", textContent: p.name });
    use.style.borderLeft = `6px solid ${p.color}`;
    use.onclick = () => change({ color: p.color, mode: p.mode, brightness: p.brightness, speed: p.speed });
    const del = Object.assign(document.createElement("button"), { type: "button", className: "x", textContent: "×", ariaLabel: "Delete " + p.name });
    del.onclick = () => { profiles.splice(i, 1); saveProfiles(profiles); renderProfiles(); };
    wrap.append(use, del); box.append(wrap);
  });
}
$("saveform").addEventListener("submit", (e) => {
  e.preventDefault();
  const name = $("pname").value.trim();
  if (!name) return $("pname").focus();
  profiles = [...profiles.filter((p) => p.name !== name), { name, ...s }];
  saveProfiles(profiles); renderProfiles(); $("pname").value = "";
});

// connection
async function connected(d) {
  dev = d;
  $("connect").textContent = "Reconnect";
  $("previewonly").hidden = true;
  setStatus("Connected", "on");
  apply();
}
function disconnected() {
  dev = null;
  $("connect").textContent = "Connect keyboard";
  $("previewonly").hidden = false;
  setStatus("Keyboard unplugged", "off");
}
if (!kb.supported()) {
  setStatus("WebHID not available. Use Chrome or Edge.", "err");
  $("connect").disabled = true;
} else {
  $("connect").onclick = async () => {
    try {
      const d = await kb.pick();
      if (!d) return setStatus("No device chosen. Pick Kreo Swarm.", "err");
      await d.open(); await connected(d);
    } catch (e) { setStatus("Connect failed: " + e.message, "err"); }
  };
  kb.previouslyGranted().then((d) => d && d.open().then(() => connected(d)).catch(() => {}));
  navigator.hid.addEventListener("disconnect", (e) => { if (e.device === dev) disconnected(); });
}

render();
renderProfiles();
