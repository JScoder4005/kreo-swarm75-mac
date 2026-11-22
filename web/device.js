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

// The Kreo Hive 75 and Hive 98 share this VID/PID; the Swarm reports were never tested on them.
export const SUPPORTED_PRODUCT = "Kreo Swarm";

export async function send(dev, { pal, mode }) {
  if (!dev.productName.startsWith(SUPPORTED_PRODUCT)) {
    throw new Error(`Found "${dev.productName}". Only the Kreo Swarm 75 is supported, so nothing was sent.`);
  }
  if (!dev.opened) await dev.open();
  // WebHID takes the report ID separately; the data excludes byte 0.
  await dev.sendFeatureReport(pal[0], pal.slice(1));
  await new Promise((r) => setTimeout(r, 50));
  await dev.sendFeatureReport(mode[0], mode.slice(1));
}
