import { networkInterfaces } from 'node:os';
import { spawnSync } from 'node:child_process';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const virtualInterface = /^(vethernet|veth|docker|br-|virbr|vmnet|vboxnet|utun|tun|tap|tailscale|zerotier|wg)|virtualbox|vmware/i;

function privateIPv4(address) {
  const [a, b] = address.split('.').map(Number);
  return a === 10 || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168);
}

export function androidApiUrl(explicitUrl, port = '8080', interfaces = networkInterfaces()) {
  if (explicitUrl) {
    const url = new URL(explicitUrl);
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
      throw new Error('API_BASE_URL must be an HTTP(S) server URL without credentials.');
    }
    if (url.hostname === 'localhost' || url.hostname === '[::1]' ||
        url.hostname.startsWith('127.') || url.hostname === '0.0.0.0') {
      throw new Error('API_BASE_URL points to the phone itself. Use the laptop LAN address or remove the override for automatic detection.');
    }
    return explicitUrl;
  }
  if (!/^\d+$/.test(port) || Number(port) < 1 || Number(port) > 65535) {
    throw new Error('BACKEND_PORT must be from 1 to 65535.');
  }
  const addresses = new Set();
  for (const [name, entries] of Object.entries(interfaces)) {
    if (virtualInterface.test(name)) continue;
    for (const entry of entries ?? []) {
      if (entry.family === 'IPv4' && !entry.internal && privateIPv4(entry.address)) {
        addresses.add(entry.address);
      }
    }
  }
  if (addresses.size !== 1) {
    throw new Error(addresses.size === 0
      ? 'No LAN address found. Connect to the phone\'s network or set API_BASE_URL explicitly.'
      : `Multiple LAN addresses found (${[...addresses].join(', ')}). Set API_BASE_URL to the address reachable from your phone.`);
  }
  return `http://${[...addresses][0]}:${port}`;
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  try {
    const [make = 'make', explicitUrl = '', port = '8080', device = ''] = process.argv.slice(2);
    const url = androidApiUrl(explicitUrl, port);
    console.log(`Android backend: ${url}`);
    const result = spawnSync(make, ['run', `API_BASE_URL=${url}`, `DEVICE=${device}`], {
      stdio: 'inherit',
    });
    if (result.error) throw result.error;
    process.exitCode = result.status ?? 1;
  } catch (error) {
    console.error(`Cannot start Android: ${error.message}`);
    process.exitCode = 1;
  }
}
