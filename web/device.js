export const FILTERS = [{ vendorId: 0x258a, productId: 0x010c, usagePage: 0xff00 }];

export const supported = () => "hid" in navigator;

export async function pick() {
  const [dev] = await navigator.hid.requestDevice({ filters: FILTERS });
  return dev ?? null;
}

export async function previouslyGranted() {
  const list = await navigator.hid.getDevices();
  return list.find((d) => d.vendorId === 0x258a && d.productId === 0x010c) ?? null;
}

export async function send(dev, { pal, mode }) {
  if (!dev.opened) await dev.open();
  // WebHID takes the report ID separately; the data excludes byte 0.
  await dev.sendFeatureReport(pal[0], pal.slice(1));
  await new Promise((r) => setTimeout(r, 50));
  await dev.sendFeatureReport(mode[0], mode.slice(1));
}
