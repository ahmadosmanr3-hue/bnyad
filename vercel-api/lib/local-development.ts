import fs from 'node:fs';
import path from 'node:path';

type Env = Record<string, string | undefined>;
export const LOCAL_DATABASE = 'bnyad_local_iphone_20261020';
export const LOCAL_PORT = 55439;
export function assertLocalDevelopment(env: Env = process.env) {
  if (env.APP_ENV !== 'local-iphone' || env.NODE_ENV !== 'development' || env.VERCEL ||
      env.BNYAD_LOCAL_TEST !== 'true' || env.BNYAD_LOCAL_ENVIRONMENT_ID !== 'bnyad-local-iphone-v1') {
    throw new Error('Local iPhone development configuration rejected.');
  }
  try {
    const db = new URL(env.DATABASE_URL ?? '');
    if (db.protocol !== 'postgresql:' || db.hostname !== '127.0.0.1' || Number(db.port) !== LOCAL_PORT ||
        db.pathname !== `/${LOCAL_DATABASE}` || !db.username || !db.password || db.search || db.hash) throw new Error();
    if (!['mock', 'live'].includes(env.BNYAD_LOCAL_AI_MODE ?? '')) throw new Error();
  } catch { throw new Error('Only the dedicated loopback test database is permitted.'); }
}
export function localLedgerDirectory(env: Env = process.env) {
  assertLocalDevelopment(env);
  const directory = path.resolve('.gemini-development');
  // Never create a fresh ledger to replenish the owner's shared allowance.
  const file = path.join(directory, 'requests.json');
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || (stat.mode & 0o077)) throw new Error('Private existing request ledger required.');
  const ledger = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (ledger.version !== 1 || !Number.isInteger(ledger.requests) || ledger.requests < 19 || ledger.requests > 21) throw new Error('Request ledger needs review; never reset it.');
  return directory;
}
export function privateLanAddress(value: string) {
  const parts = value.split('.').map(Number);
  return parts.length === 4 && parts.every((n, i) => Number.isInteger(n) && n >= 0 && n <= 255 && String(n) === value.split('.')[i]) &&
    (parts[0] === 10 || (parts[0] === 192 && parts[1] === 168) || (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31));
}
