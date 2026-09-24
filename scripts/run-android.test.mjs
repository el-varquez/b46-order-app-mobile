import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, existsSync, unlinkSync, rmdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { androidApiUrl } from './run-android.mjs';

const root = fileURLToPath(new URL('..', import.meta.url));
const address = (value, internal = false) => ({ address: value, family: 'IPv4', internal });

test('automatic detection uses Wi-Fi instead of WSL or loopback', () => {
  assert.equal(androidApiUrl('', '8080', {
    'vEthernet (WSL (Hyper-V firewall))': [address('172.29.0.1')],
    'Wi-Fi': [address('192.168.100.75')],
    Loopback: [address('127.0.0.1', true)],
  }), 'http://192.168.100.75:8080');
});

test('LAN detection supports macOS/Linux names and custom backend ports', () => {
  for (const name of ['en0', 'wlan0', 'Ethernet']) {
    assert.equal(androidApiUrl('', '9090', { [name]: [address('10.1.2.3')] }), 'http://10.1.2.3:9090');
  }
});

test('missing or ambiguous LAN configuration stops before building', () => {
  assert.throws(() => androidApiUrl('', '8080', {}), /No LAN address/);
  assert.throws(() => androidApiUrl('', '8080', {
    WiFi: [address('192.168.1.2')], Ethernet: [address('10.0.0.2')],
  }), /Multiple LAN addresses/);
  assert.throws(() => androidApiUrl('', '99999', {}), /BACKEND_PORT/);
});

test('explicit endpoints take precedence, but loopback cannot silently require USB', () => {
  assert.equal(androidApiUrl('https://api.example.com', '8080', {}), 'https://api.example.com');
  for (const host of ['127.0.0.1', 'localhost', '[::1]', '0.0.0.0']) {
    assert.throws(() => androidApiUrl(`http://${host}:8080`, '8080', {}), /phone itself/);
  }
});

test('make run-android uses the configured network URL without an ADB tunnel', () => {
  const directory = mkdtempSync(join(tmpdir(), 'b46-android-test-'));
  try {
    const stub = join(directory, 'device-stub.cjs');
    const log = join(directory, 'calls.jsonl');
    writeFileSync(stub, `
      const fs = require('node:fs');
      const [kind, ...args] = process.argv.slice(2);
      fs.appendFileSync(process.env.B46_ANDROID_TEST_LOG, JSON.stringify({
        kind,
        api: args.find(arg => arg.startsWith('--dart-define=API_BASE_URL=')),
        device: args.includes('test-phone'),
      }) + '\\n');
    `);
    const result = spawnSync('make', [
      '--silent', 'run-android',
      `FLUTTER=node "${stub}" flutter`,
      `ADB=node "${stub}" adb`,
      'API_BASE_URL=http://192.168.50.20:9090',
      'DEVICE=test-phone',
    ], { cwd: root, encoding: 'utf8', env: { ...process.env, B46_ANDROID_TEST_LOG: log } });
    assert.equal(result.status, 0, result.stderr);
    const calls = readFileSync(log, 'utf8').trim().split('\n').map(JSON.parse);
    assert.deepEqual(calls, [{
      kind: 'flutter',
      api: '--dart-define=API_BASE_URL=http://192.168.50.20:9090',
      device: true,
    }]);
  } finally {
    for (const name of ['device-stub.cjs', 'calls.jsonl']) {
      const file = join(directory, name);
      if (existsSync(file)) unlinkSync(file);
    }
    rmdirSync(directory);
  }
});
