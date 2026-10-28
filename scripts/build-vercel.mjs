import { createHash } from 'node:crypto';
import { createReadStream, createWriteStream, existsSync, mkdirSync, readFileSync, renameSync, unlinkSync } from 'node:fs';
import { isIP } from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

const root = fileURLToPath(new URL('../', import.meta.url));
const version = readFileSync(path.join(root, '.flutter-version'), 'utf8').trim();
const storage = 'https://storage.googleapis.com/flutter_infra_release/releases';

export function apiOrigin(value) {
  let url;
  try { url = new URL(value); } catch { throw new Error('Set API_BASE_URL to the public HTTPS Backend origin before deploying.'); }
  const host = url.hostname.replace(/^\[|\]$/g, '');
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash ||
      url.pathname !== '/' || isIP(host) || !host.includes('.') ||
      /(^|\.)(localhost|local|internal|invalid)$/.test(host)) {
    throw new Error('API_BASE_URL must be a public HTTPS origin, e.g. https://tho-xay-api.onrender.com (no /api, credentials, IP or query).');
  }
  return url.origin;
}

function run(executable, args, options = {}) {
  const settings = { cwd: root, stdio: 'inherit', ...options };
  let result;
  if (process.platform === 'win32' && /\.(bat|cmd)$/i.test(executable)) {
    const quoted = [executable, ...args].map(value => {
      if (/["%!&|<>^\r\n]/.test(value)) throw new Error('Unsupported Windows command character.');
      return `"${value}"`;
    }).join(' ');
    result = spawnSync(quoted, { ...settings, shell: process.env.ComSpec || 'cmd.exe' });
  } else {
    result = spawnSync(executable, args, settings);
  }
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${path.basename(executable)} failed (exit ${result.status}).`);
  return result;
}

async function fetchOk(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(10 * 60 * 1000) });
  if (!response.ok) throw new Error(`Flutter SDK download failed (${response.status}).`);
  return response;
}

async function flutterSdk() {
  // Local/CI verification can reuse an already installed SDK of the exact pinned version.
  if (process.env.FLUTTER_BIN) return process.env.FLUTTER_BIN;
  if (process.platform !== 'linux' || process.arch !== 'x64') {
    throw new Error('Automatic SDK installation targets Vercel Linux x64. Set FLUTTER_BIN for local builds.');
  }
  const cache = path.join(root, '.vercel/cache', `flutter-${version}`);
  const executable = path.join(cache, 'flutter/bin/flutter');
  if (existsSync(executable)) return executable;
  mkdirSync(cache, { recursive: true });
  const manifest = await (await fetchOk(`${storage}/releases_linux.json`)).json();
  const release = manifest.releases.find(r => r.version === version && r.channel === 'stable' &&
    r.dart_sdk_arch === 'x64');
  if (!release || !/^stable\/linux\/flutter_linux_[\w.+-]+-stable\.tar\.xz$/.test(release.archive) ||
      !/^[0-9a-f]{64}$/i.test(release.sha256)) throw new Error(`No verified stable Linux x64 Flutter ${version} archive.`);
  const archive = path.join(cache, 'sdk.tar.xz');
  const temporary = `${archive}.part`;
  console.log(`Downloading official Flutter ${version} SDK...`);
  const response = await fetchOk(`${storage}/${release.archive}`);
  await pipeline(Readable.fromWeb(response.body), createWriteStream(temporary));
  const digest = createHash('sha256');
  for await (const chunk of createReadStream(temporary)) digest.update(chunk);
  if (digest.digest('hex').toLowerCase() !== release.sha256.toLowerCase()) {
    unlinkSync(temporary);
    throw new Error('Flutter archive SHA-256 mismatch. Build stopped.');
  }
  renameSync(temporary, archive);
  run('tar', ['-xJf', archive, '-C', cache]);
  unlinkSync(archive);
  return executable;
}

export async function build() {
  // Validate BEFORE downloading or compiling, so a missing setting never ships the LAN API.
  const backend = apiOrigin(process.env.API_BASE_URL);
  const flutter = await flutterSdk();
  const sdk = run(flutter, ['--version', '--machine'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'] });
  if (JSON.parse(sdk.stdout).frameworkVersion !== version) throw new Error(`Use Flutter ${version} as pinned in .flutter-version.`);
  const options = { cwd: path.join(root, 'mobile_app') };
  run(flutter, ['config', '--no-analytics'], options);
  run(flutter, ['pub', 'get', '--enforce-lockfile'], options);
  run(flutter, ['build', 'web', '--release', '--no-wasm-dry-run', `--dart-define=API_BASE_URL=${backend}`], options);
  console.log('Vercel output ready: mobile_app/build/web');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  build().catch(error => { console.error(error.message); process.exitCode = 1; });
}
