import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import { apiOrigin } from './build-vercel.mjs';

test('public Backend origin is normalized without adding /api', () => {
  assert.equal(apiOrigin('https://tho-xay-api.onrender.com/'), 'https://tho-xay-api.onrender.com');
});
test('cloud build refuses missing settings, local APIs, credentials and endpoint suffixes', () => {
  for (const url of [undefined, '', 'http://192.168.1.16:8080', 'https://localhost', 'https://127.0.0.1',
    'https://[::1]', 'https://test.internal', 'https://test.local', 'https://user:pass@api.example.com',
    'https://api.example.com/api', 'https://api.example.com?token=private', 'https://api.example.com/#private']) {
    assert.throws(() => apiOrigin(url), undefined, `Should refuse ${url}`);
  }
});
test('cloud schema contains constraints and private KYC but no sample accounts', () => {
  const result = spawnSync(process.execPath, ['scripts/export-cloud-schema.mjs'], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /CREATE TABLE IF NOT EXISTS kyc_images/);
  assert.match(result.stdout, /CREATE TABLE IF NOT EXISTS wallet_entries/);
  assert.doesNotMatch(result.stdout, /INSERT INTO|0900000001|Demo-only password/);
  assert.match(result.stdout, /COMMIT;\s*$/);
});
