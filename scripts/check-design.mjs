#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const lib = join(root, 'lib');
const tokenSource = join(root, 'design', 'tokens.json');
const tokenDart = join(root, 'lib', 'app', 'theme', 'tokens.dart');
const hits = [];

function* walk(directory) {
  if (!existsSync(directory)) return;
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) yield* walk(path);
    else yield path;
  }
}

const rel = (path) => relative(root, path).split(sep).join('/');
const dartFiles = [...walk(lib)].filter((file) => file.endsWith('.dart'));

if (dartFiles.length === 0) {
  console.log('check:design OK — scaffold mode; token enforcement activates with Dart source');
  process.exit(0);
}

if (!existsSync(tokenSource)) hits.push('design/tokens.json: missing canonical Pop Shelf tokens');
if (!existsSync(tokenDart)) hits.push('lib/app/theme/tokens.dart: missing generated or mirrored Flutter theme tokens');

if (existsSync(tokenSource) && existsSync(tokenDart)) {
  const tokens = JSON.parse(readFileSync(tokenSource, 'utf8'));
  const dart = readFileSync(tokenDart, 'utf8').toUpperCase();
  for (const [name, value] of Object.entries(tokens)) {
    if (typeof value !== 'string' || !value.startsWith('#')) continue;
    const hex = value.slice(1).toUpperCase();
    const needle = `0X${hex.length === 8 ? '' : 'FF'}${hex}`;
    if (!dart.includes(needle)) hits.push(`design/tokens.json: token "${name}" value ${value} is missing from tokens.dart`);
  }
}

for (const file of dartFiles) {
  if (file === tokenDart) continue;
  readFileSync(file, 'utf8').split(/\r?\n/).forEach((text, index) => {
    if (/\bColor\(0x/.test(text)) hits.push(`${rel(file)}:${index + 1}: raw color literal — use a Pop Shelf token`);
    if (/\bColors\.(?!transparent\b)/.test(text)) hits.push(`${rel(file)}:${index + 1}: Material color — use a Pop Shelf token`);
  });
}

if (hits.length > 0) {
  console.error('check:design FAILED — Pop Shelf design-system rules violated\n');
  for (const hit of hits) console.error(hit);
  process.exit(1);
}
console.log('check:design OK — tokens match and no raw colors escape the theme');
