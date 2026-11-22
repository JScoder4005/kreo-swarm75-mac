const KEY = "kreo-profiles-v1";

export function loadProfiles() {
  try { return JSON.parse(localStorage.getItem(KEY)) ?? []; } catch { return []; }
}

export function saveProfiles(list) {
  try { localStorage.setItem(KEY, JSON.stringify(list)); } catch { /* storage blocked: profiles last for this tab only */ }
}
