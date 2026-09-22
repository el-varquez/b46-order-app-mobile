#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const lib = join(root, 'lib');
const lockPath = join(root, 'architecture', 'dependencies.json');
const hits = [];
const skipped = new Set(['.git', '.dart_tool', 'build', 'coverage']);

function* walk(directory) {
  if (!existsSync(directory)) return;
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && skipped.has(entry.name)) continue;
    const path = join(directory, entry.name);
    if (entry.isDirectory()) yield* walk(path);
    else yield path;
  }
}

const rel = (path) => relative(root, path).split(sep).join('/');
const requiredDirectories = [
  'lib/app/bootstrap',
  'lib/app/routing',
  'lib/app/theme',
  'lib/core/config',
  'lib/core/errors',
  'lib/core/networking',
  'lib/core/storage',
  'lib/shared/components',
  'lib/shared/services',
  'test/architecture',
  'test/unit',
  'test/widget',
  'integration_test',
];
const features = new Set([
  'authentication',
  'catalog',
  'cart_checkout',
  'customer_orders',
  'cashier_fulfillment',
  'admin_cashier_management',
]);
const layerShape = {
  presentation: new Set(['screens', 'components', 'cubit']),
  application: new Set(['use_cases']),
  domain: new Set(['entities', 'repositories']),
  data: new Set(['models', 'sources', 'repositories']),
};

for (const directory of requiredDirectories) {
  if (!existsSync(join(root, directory))) hits.push(`${directory}: R2 required architecture directory is missing`);
}
for (const feature of features) {
  for (const [layer, areas] of Object.entries(layerShape)) {
    for (const area of areas) {
      const directory = `lib/features/${feature}/${layer}/${area}`;
      if (!existsSync(join(root, directory))) hits.push(`${directory}: R2 required feature directory is missing`);
    }
  }
}
if (!existsSync(lockPath)) hits.push('architecture/dependencies.json: R1 dependency lock is missing');

const allDartFiles = [...walk(lib)].filter((file) => file.endsWith('.dart'));
const classify = (file) => {
  const parts = rel(file).split('/');
  if (parts[0] !== 'lib') return null;
  if (parts[1] !== 'features') return { kind: parts[1], path: rel(file), area: parts[2] };
  return { kind: 'feature', path: rel(file), feature: parts[2], layer: parts[3], area: parts[4] };
};

for (const file of allDartFiles) {
  const info = classify(file);
  if (info?.kind !== 'feature') continue;
  if (!features.has(info.feature) || !(info.layer in layerShape) || !layerShape[info.layer].has(info.area)) {
    hits.push(`${info.path}: R2 breaks lib/features/<feature>/<layer>/<approved-area>/<file>`);
  }
}

let packageName = 'b46_order_app_mobile';
const pubspecPath = join(root, 'pubspec.yaml');
if (existsSync(pubspecPath) && existsSync(lockPath)) {
  const pubspecText = readFileSync(pubspecPath, 'utf8');
  packageName = pubspecText.match(/^name:\s*([a-z0-9_]+)\s*$/m)?.[1] ?? packageName;
  const lock = JSON.parse(readFileSync(lockPath, 'utf8'))['pubspec.yaml'] ?? {};
  const sections = { dependencies: [], dev_dependencies: [] };
  let current = null;
  for (const line of pubspecText.split(/\r?\n/)) {
    const top = line.match(/^([a-z_]+):\s*$/);
    if (top) {
      current = top[1] in sections ? top[1] : null;
      continue;
    }
    if (/^\S/.test(line) && line.trim() !== '') current = null;
    if (!current) continue;
    const dependency = line.match(/^ {2}([a-z0-9_]+):/);
    if (dependency) sections[current].push(dependency[1]);
  }
  for (const section of Object.keys(sections)) {
    const actual = [...sections[section]].sort();
    const expected = [...(lock[section] ?? [])].sort();
    for (const dependency of expected) {
      if (!actual.includes(dependency)) hits.push(`pubspec.yaml: R1 missing ${section} dependency "${dependency}"`);
    }
    for (const dependency of actual) {
      if (!expected.includes(dependency)) {
        hits.push(`pubspec.yaml: R1 undeclared ${section} dependency "${dependency}" — update the lock in the same PR`);
      }
    }
  }
}

const internalTarget = (source, imported) => {
  if (imported.startsWith(`package:${packageName}/`)) return join(lib, imported.slice(packageName.length + 9));
  if (imported.startsWith('.')) return resolve(dirname(source), imported);
  return null;
};
const directives = (text) => [...text.matchAll(/^\s*(?:import|export)\s+'([^']+)'/gm)].map((match) => match[1]);
const forbiddenTargets = {
  domain: new Set(['application', 'data', 'presentation']),
  application: new Set(['data', 'presentation']),
  data: new Set(['application', 'presentation']),
  presentation: new Set(['data']),
};
const presentationPackages = new Set(['flutter', 'flutter_bloc', 'bloc', 'equatable']);

const selfTest = join(
  root,
  'architecture',
  'fixtures',
  'lib',
  'features',
  'authentication',
  'domain',
  'entities',
  'forbidden.dart.txt',
);
if (!existsSync(selfTest)) {
  hits.push('architecture/fixtures: architecture checker self-test is missing');
} else {
  const detected = directives(readFileSync(selfTest, 'utf8')).some((imported) =>
    imported.startsWith('package:flutter/'),
  );
  if (!detected) hits.push('architecture/fixtures: self-test did not detect its intentional domain -> Flutter violation');
}

for (const file of allDartFiles) {
  const info = classify(file);
  for (const imported of directives(readFileSync(file, 'utf8'))) {
    const targetPath = internalTarget(file, imported);
    const target = targetPath ? classify(targetPath) : null;
    const externalPackage = imported.match(/^package:([a-z0-9_]+)\//)?.[1];

    if ((info?.kind === 'core' || info?.kind === 'shared') && target?.kind === 'feature') {
      hits.push(`${info.path}: R4 ${info.kind} cannot import feature implementation ${target.path}`);
    }
    if (info?.kind !== 'feature') continue;

    if (target?.kind === 'feature' && target.feature !== info.feature) {
      hits.push(`${info.path}: R4 feature "${info.feature}" cannot import feature "${target.feature}"`);
      continue;
    }
    if (target?.kind === 'feature' && forbiddenTargets[info.layer]?.has(target.layer)) {
      hits.push(`${info.path}: R3 ${info.layer} cannot import ${target.layer} from ${target.path}`);
    }
    if (info.layer === 'domain' && externalPackage && externalPackage !== packageName) {
      hits.push(`${info.path}: R3 domain cannot import vendor package "${externalPackage}"`);
    }
    if (info.layer === 'application' && externalPackage && externalPackage !== packageName) {
      hits.push(`${info.path}: R3 application cannot import vendor package "${externalPackage}"`);
    }
    if (info.layer === 'presentation' && externalPackage && externalPackage !== packageName && !presentationPackages.has(externalPackage)) {
      hits.push(`${info.path}: R3 presentation package "${externalPackage}" is not approved`);
    }
    if (imported.startsWith('package:flutter/') && info.layer !== 'presentation') {
      hits.push(`${info.path}: R3 Flutter imports belong in presentation, app, or shared UI modules`);
    }
  }
}

if (hits.length > 0) {
  console.error('check:architecture FAILED — Flutter Clean Architecture rules violated\n');
  for (const hit of hits) console.error(hit);
  process.exit(1);
}
console.log('check:architecture OK — dependency lock, feature shape, import direction, and feature isolation hold');
