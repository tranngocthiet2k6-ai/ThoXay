import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const source = readFileSync(path.join(root, 'schema.sql'), 'utf8');
const marker = '-- Demo-only password for all three accounts: password';
const index = source.indexOf(marker);
if (index < 0) throw new Error('Demo boundary missing; refusing to export a potentially seeded schema.');
const ddl = source.slice(0, index);
if (/(?:^|;)\s*(INSERT|UPDATE|DELETE|TRUNCATE|DROP)\b/im.test(ddl.replace(/^--.*$/gm, ''))) {
  throw new Error('Unexpected data mutation before the demo boundary. Review schema.sql first.');
}
const output = '-- Cloud initialization: schema only, no demo accounts or jobs.\n' + ddl.trimEnd() + '\nCOMMIT;\n';
if (process.argv[2] === '--output' && process.argv[3]) {
  const destination = path.resolve(process.argv[3]);
  mkdirSync(path.dirname(destination), { recursive: true });
  writeFileSync(destination, output, { encoding: 'utf8', flag: 'wx' });
  console.log('Schema exported without demo data. Apply only to a NEW empty database.');
} else if (process.argv.length === 2) {
  process.stdout.write(output);
} else {
  throw new Error('Usage: node scripts/export-cloud-schema.mjs [--output .local/cloud-schema.sql]');
}
