#!/usr/bin/env node
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const requiredDirectories = [
  'android',
  'ios',
  'assets',
  'lib/app',
  'lib/core',
  'lib/shared',
  'lib/features',
  'test',
  'integration_test',
];

const missing = requiredDirectories.filter((directory) => !existsSync(join(root, directory)));
if (missing.length > 0) {
  console.error('check:build-test FAILED — required mobile scaffold directories are missing\n');
  for (const directory of missing) console.error(directory);
  process.exit(1);
}

function* walk(directory) {
  if (!existsSync(directory)) return;
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) yield* walk(path);
    else yield path;
  }
}

const dartFiles = [
  ...walk(join(root, 'lib')),
  ...walk(join(root, 'test')),
  ...walk(join(root, 'integration_test')),
].filter((file) => file.endsWith('.dart'));

if (!existsSync(join(root, 'pubspec.yaml'))) {
  if (dartFiles.length > 0) {
    console.error('check:build-test FAILED — Dart source exists before pubspec.yaml');
    process.exit(1);
  }
  console.log('check:build-test OK — architecture scaffold is ready; Flutter build activates with pubspec.yaml');
  process.exit(0);
}

const run = (command, args, cwd = root) => {
  console.log(`\n${command} ${args.join(' ')}`);
  const result = spawnSync(command, args, { cwd, stdio: 'inherit', shell: process.platform === 'win32' });
  if (result.error || result.status !== 0) {
    console.error(`check:build-test FAILED — ${command} ${args.join(' ')}`);
    process.exit(result.status ?? 1);
  }
};

run('node', ['--test', 'scripts/run-android.test.mjs']);
run('flutter', ['pub', 'get']);
run('dart', ['format', '--output=none', '--set-exit-if-changed', 'lib', 'test', 'integration_test']);
run('flutter', ['analyze']);
run('flutter', ['test']);
run('flutter', ['build', 'apk', '--debug']);
run(process.platform === 'win32' ? 'gradlew.bat' : './gradlew', [':app:testDebugUnitTest', '--console=plain'], join(root, 'android'));

console.log('\ncheck:build-test OK — formatting, analysis, Flutter and Android tests, and debug APK build passed');
