import fs from 'node:fs';
import crypto from 'node:crypto';
import { parseEnv } from 'node:util';
import { assertLocalDevelopment, localLedgerDirectory } from '../lib/local-development';
import { FOOD_TEST_FILE, foodApproval, FOOD_TEST_MODEL, type FoodTestApproval } from '../lib/ai/supervised-food';
import { privateConfiguration } from './lib/gemini-development';

async function main() {
  if (process.env.VERCEL || process.env.DATABASE_URL) throw new Error('Clean local process required.');
  Object.assign(process.env, parseEnv(fs.readFileSync('.local-development/backend.env', 'utf8')));
  assertLocalDevelopment();
  const command = process.argv[2];
  const directory = localLedgerDirectory();
  const ledger = JSON.parse(fs.readFileSync(directory + '/requests.json', 'utf8'));
  if (command === '--status') {
    const a = foodApproval();
    console.log(JSON.stringify({ requests: ledger.requests, approvedCap: 21, enabled: a?.enabled ?? false, state: a?.state ?? 'not-armed' }));
    return;
  }
  if (command === '--disarm') {
    const a = foodApproval();
    if (a) { a.enabled = false; a.state = 'disarmed'; fs.writeFileSync(FOOD_TEST_FILE, JSON.stringify(a), { mode: 0o600 }); }
    console.log('Live food permission disabled. The ledger was not changed.'); return;
  }
  if (command !== '--arm-owner-approved-21-one-food') throw new Error('Explicit owner approval required.');
  if (fs.existsSync(FOOD_TEST_FILE) || ledger.requests !== 19 || ledger.blocked || ledger.model !== FOOD_TEST_MODEL || !ledger.modelAccessible) throw new Error('One-use approval or existing ledger needs review. Never reset either.');
  const credentials = privateConfiguration('.env.gemini-development.local');
  if (credentials.model !== FOOD_TEST_MODEL) throw new Error('Private model mismatch.');
  const { prisma } = await import('../lib/db');
  try {
    const user = await prisma.user.findUniqueOrThrow({ where: { phone: '+9647000000000' }, include: { profile: true, subscriptions: true } });
    if (user.email !== 'bnyad-local@example.test' || !user.profile?.onboarded || !user.subscriptions.some(s => s.active && s.expiresAt > new Date())) throw new Error('Fictional Premium QA account required.');
    const a: FoodTestApproval = { version: 1, id: crypto.randomUUID(), userId: user.id, operation: 'food', model: FOOD_TEST_MODEL,
      requestCap: 21, startRequests: 19, enabled: true, state: 'armed', expiresAt: new Date(Date.now() + 20 * 60000).toISOString() };
    fs.writeFileSync(FOOD_TEST_FILE, JSON.stringify(a), { mode: 0o600, flag: 'wx' });
    console.log('One authenticated iPhone food scan armed for 20 minutes. Two HTTP attempts maximum; no retries. Current ledger 19/21.');
  } finally { await prisma.$disconnect(); }
}
main().catch(() => { console.error('Supervised test control refused. Preserve the ledger and approval; review local configuration.'); process.exitCode = 1; });
