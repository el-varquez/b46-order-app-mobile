#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const contractPath = join(root, 'contracts', 'backend', 'openapi.json');
const sourcePath = join(root, 'contracts', 'backend', 'source.json');
const bytes = readFileSync(contractPath);
const contract = JSON.parse(bytes);
const source = JSON.parse(readFileSync(sourcePath, 'utf8'));
const digest = createHash('sha256').update(bytes).digest('hex');
const failures = [];

if (contract.openapi !== '3.1.1') failures.push('backend contract must use OpenAPI 3.1.1');
if (contract.info?.version !== source.openapi_version) failures.push('OpenAPI version does not match source.json');
if (digest !== source.sha256) failures.push('OpenAPI SHA-256 does not match source.json');
if (!source.source_contract_blob || source.source_contract_blob.length !== 40) failures.push('source contract blob is missing');
if (!/^[0-9a-f]{40}$/.test(source.source_commit ?? '')) failures.push('source commit must be an immutable Git SHA');
if (!contract.paths?.['/v1/products']?.get) failures.push('pinned contract is missing GET /v1/products');

if (failures.length > 0) {
  console.error('check:contract-pin FAILED\n');
  failures.forEach((failure) => console.error(failure));
  process.exit(1);
}
console.log(`check:contract-pin OK — backend OpenAPI ${source.openapi_version} matches ${digest}`);
