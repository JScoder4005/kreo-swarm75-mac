// Live keyboard preview. Effects are approximations of the keyboard's own firmware effects.
const ROWS = [
  [["escape","Esc",1],["f1","F1",1],["f2","F2",1],["f3","F3",1],["f4","F4",1],["f5","F5",1],["f6","F6",1],["f7","F7",1],["f8","F8",1],["f9","F9",1],["f10","F10",1],["f11","F11",1],["f12","F12",1],["printscreen","Prt",1],["delete","Del",1],["home","Home",1]],
  [["`","`",1],..."1234567890".split("").map((k) => [k,k,1]),["-","-",1],["=","=",1],["backspace","Bksp",2],["pageup","PgUp",1]],
  [["tab","Tab",1.5],..."qwertyuiop".split("").map((k) => [k,k.toUpperCase(),1]),["[","[",1],["]","]",1],["\\","\\",1.5],["pagedown","PgDn",1]],
  [["capslock","Caps",1.75],..."asdfghjkl".split("").map((k) => [k,k.toUpperCase(),1]),[";",";",1],["'","'",1],["enter","Enter",2.25],["end","End",1]],
  [["shift","Shift",2.25],..."zxcvbnm".split("").map((k) => [k,k.toUpperCase(),1]),[",",",",1],[".",".",1],["/","/",1],["shift2","Shift",1.75],["arrowup","↑",1],["insert","Ins",1]],
  [["control","Ctrl",1.25],["meta","Cmd",1.25],["alt","Alt",1.25],[" ","",6.25],["alt2","Alt",1],["fn","Fn",1],["control2","Ctrl",1],["arrowleft","←",1],["arrowdown","↓",1],["arrowright","→",1]],
];

const hsl = (h, s, l) => {
  h = ((h % 360) + 360) % 360;
  const a = s * Math.min(l, 1 - l);
  const f = (n) => { const k = (n + h / 30) % 12; return l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)); };
  return [f(0) * 255, f(8) * 255, f(4) * 255];
};
const hue = (h) => hsl(h, 1, 0.5);

export function createPreview(root) {
  const keys = [];
  ROWS.forEach((row, r) => {
    const rowEl = document.createElement("div");
    rowEl.className = "krow";
    root.append(rowEl);
    let x = 0;
    row.forEach(([id, label, w]) => {
      const el = document.createElement("div");
      el.className = "key";
      el.style.setProperty("--w", w);
      el.textContent = label;
      rowEl.append(el);
      keys.push({ id, el, x: x + w / 2, y: r, press: -99 });
      x += w;
    });
  });
  const state = { rgb: [255, 0, 0], mode: 1, brightness: 1, speed: 0.5 };
  const ripples = [];
  const snakeOrder = keys.map((_, i) => i);

  const idFor = (e) => {
    const k = e.key.toLowerCase();
    if (k === "shift") return e.location === 2 ? "shift2" : "shift";
    if (k === "control") return e.location === 2 ? "control2" : "control";
    if (k === "alt") return e.location === 2 ? "alt2" : "alt";
    return k;
  };

  function press(id, t) {
    const k = keys.find((q) => q.id === id) ?? keys[Math.floor(Math.random() * keys.length)];
    k.press = t;
    ripples.push({ x: k.x, y: k.y * 1.2, t0: t });
    if (ripples.length > 12) ripples.shift();
  }

  function level(k, i, t, sp) {
    const { mode, rgb } = state;
    switch (mode) {
      case 1: return { c: rgb, l: 1 };
      case 2: return { c: hue(k.x * 18 - t * 70 * sp), l: 1 };
      case 3: return { c: hue(t * 30 * sp), l: 0.5 + 0.5 * Math.sin(t * 2.2 * sp) };
      case 7: {
        let l = 0;
        for (const r of ripples) {
          const d = Math.hypot(k.x - r.x, (k.y * 1.2) - r.y), age = t - r.t0;
          l = Math.max(l, Math.exp(-((d - age * 7 * sp * 2) ** 2) / 1.2) * Math.max(0, 1 - age / 1.6));
        }
        return { c: rgb, l };
      }
      case 10: {
        const head = (t * 22 * sp) % snakeOrder.length, d = (head - i + snakeOrder.length) % snakeOrder.length;
        return { c: rgb, l: Math.max(0, 1 - d / 9) };
      }
      case 12: return { c: rgb, l: Math.exp(-(t - k.press) * 1.6) };
      default: {
        const dir = mode === 8 ? -1 : 1;
        const along = mode === 13 ? k.y * 1.8 : mode === 6 ? k.x * 0.4 + k.y * 0.9 : mode === 15 ? Math.hypot(k.x - 8, k.y * 2 - 5) * 0.8 : k.x * 0.45;
        const slow = mode === 4 ? 0.5 : 1;
        const jitter = mode === 5 ? 0.6 * Math.sin(k.y * 2.7 + k.x * 1.3 + t) : 0;
        const l = 0.5 + 0.5 * Math.sin(along + jitter - dir * t * 3 * sp * slow);
        return { c: mode === 11 ? hue(k.x * 8 + t * 40 * sp) : rgb, l };
      }
    }
  }

  const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
  function frame(ms) {
    const t = reduced ? 0 : ms / 1000, sp = 0.15 + state.speed * 1.6;
    keys.forEach((k, i) => {
      const { c, l } = level(k, i, t, sp);
      const v = Math.max(0, Math.min(1, l)) * state.brightness;
      const css = `${Math.round(c[0] * v)} ${Math.round(c[1] * v)} ${Math.round(c[2] * v)}`;
      k.el.style.setProperty("--c", `rgb(${css})`);
      k.el.style.setProperty("--g", `rgb(${css} / ${0.55 * v})`);
      k.el.style.setProperty("--lit", v > 0.04 ? "1" : "0");
    });
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);

  addEventListener("keydown", (e) => { if (!e.repeat) press(idFor(e), performance.now() / 1000); });
  root.addEventListener("pointerdown", (e) => {
    const k = keys.find((q) => q.el === e.target.closest(".key"));
    if (k) press(k.id, performance.now() / 1000);
  });

  return { set(patch) { Object.assign(state, patch); } };
}
