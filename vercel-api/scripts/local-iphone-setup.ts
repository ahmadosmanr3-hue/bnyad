import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { parseEnv } from 'node:util';
import { LOCAL_DATABASE, LOCAL_PORT, privateLanAddress } from '../lib/local-development';

// Explicit, one-time setup of a NEW cluster. Never accepts an external DB URL.
async function main() {
  const resume = process.argv[2] === '--resume-empty-local-only';
  if ((!resume && process.argv[2] !== '--initialize-new-local-only') || process.env.VERCEL) throw new Error();
  const host = process.argv[3];
  if (!host || !privateLanAddress(host)) throw new Error();
  const directory = path.resolve('.local-development');
  if (fs.existsSync(directory) && !resume) throw new Error('Local setup already exists. Preserve it; do not rerun initialization.');
  if (!resume) fs.mkdirSync(directory, { mode: 0o700 });
  if (resume && (fs.existsSync(path.join(directory, 'backend.env')) || !fs.existsSync(path.join(directory, 'pgdata/PG_VERSION')))) throw new Error();
  const write = (file: string, value: string) => fs.writeFileSync(path.join(directory, file), value, { mode: 0o600, flag: 'wx' });
  const admin = resume ? fs.readFileSync(path.join(directory, 'owner-password'), 'utf8') : crypto.randomBytes(32).toString('hex');
  const password = crypto.randomBytes(32).toString('hex');
  const qaPassword = crypto.randomBytes(14).toString('base64url') + '!a1';
  if (!resume) write('owner-password', admin);
  const bin = '/opt/homebrew/opt/postgresql@17/bin/';
  if (!resume) {
    execFileSync(bin + 'initdb', ['-D', path.join(directory, 'pgdata'), '-U', 'bnyad_local_owner', '--auth-local=trust', '--auth-host=scram-sha-256', '--pwfile=' + path.join(directory, 'owner-password')], { stdio: 'ignore' });
    execFileSync(bin + 'pg_ctl', ['-D', path.join(directory, 'pgdata'), '-l', path.join(directory, 'postgres.log'), '-o', `-h 127.0.0.1 -p ${LOCAL_PORT} -k ''`, '-w', 'start'], { stdio: 'ignore' });
  }
  const sql = (database: string, input: string) => execFileSync(bin + 'psql', ['-X', '-h', '127.0.0.1', '-p', String(LOCAL_PORT), '-U', 'bnyad_local_owner', '-d', database, '-v', 'ON_ERROR_STOP=1'], { input, env: { ...process.env, PGPASSWORD: admin }, stdio: ['pipe', 'pipe', 'pipe'] });
  if (!resume) sql('postgres', `CREATE ROLE bnyad_local_app LOGIN PASSWORD '${password}'; CREATE DATABASE ${LOCAL_DATABASE} OWNER bnyad_local_app;`);
  else {
    const count = sql(LOCAL_DATABASE, "SELECT COUNT(*) AS tables FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';").toString();
    if (!/\n\s*0\s*\n/.test(count)) throw new Error('Resume requires an empty local database.');
    sql(LOCAL_DATABASE, `ALTER ROLE bnyad_local_app PASSWORD '${password}';`);
  }
  // Full existing baseline already includes auth/AI safeguards; do not reapply
  // earlier additive migrations. This cluster was created immediately above.
  sql(LOCAL_DATABASE, fs.readFileSync('db/20261014_staging_empty_bootstrap.sql', 'utf8'));
  sql(LOCAL_DATABASE, fs.readFileSync('prisma/notification_translations.sql', 'utf8'));
  sql(LOCAL_DATABASE, 'GRANT ALL ON ALL TABLES IN SCHEMA public TO bnyad_local_app; GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO bnyad_local_app;');
  const env = {
    APP_ENV: 'local-iphone', NODE_ENV: 'development', BNYAD_LOCAL_TEST: 'true',
    BNYAD_LOCAL_ENVIRONMENT_ID: 'bnyad-local-iphone-v1', BNYAD_LOCAL_AI_MODE: 'mock',
    DATABASE_URL: `postgresql://bnyad_local_app:${password}@127.0.0.1:${LOCAL_PORT}/${LOCAL_DATABASE}`,
    AI_ENABLED: 'true', GEMINI_MODEL: 'gemini-3.5-flash-lite', GEMINI_API_KEY: 'mock-local-no-google-key',
    AI_INPUT_USD_PER_MILLION: '.30', AI_OUTPUT_USD_PER_MILLION: '2.50', AI_MONTHLY_BUDGET_USD: '1',
    AI_DAILY_REQUEST_LIMIT: '100', AI_REQUESTS_PER_MINUTE: '20', AI_MAX_OUTPUT_TOKENS: '8192',
    BNYAD_LOCAL_LAN_ADDRESS: host,
  };
  write('backend.env', Object.entries(env).map(([k, v]) => `${k}=${v}`).join('\n') + '\n');
  write('qa-account.txt', `Fictional local-only account. Never use a real account.\nPhone: +9647000000000\nPassword: ${qaPassword}\n`);
  Object.assign(process.env, parseEnv(fs.readFileSync(path.join(directory, 'backend.env'), 'utf8')));
  const { prisma } = await import('../lib/db');
  const { hashPassword } = await import('../lib/auth');
  try {
    await prisma.user.create({ data: {
      name: 'BNYAD Local QA', email: 'bnyad-local@example.test', phone: '+9647000000000',
      passwordHash: await hashPassword(qaPassword), phoneVerifiedAt: new Date(),
      profile: { create: { displayName: 'BNYAD Local QA', onboarded: true, language: 'ku', weight: 70, height: 175, age: 25,
        dailyCalories: 2000, dailyProtein: 100, dailyCarbs: 260, dailyFat: 60,
        allergies: [], dislikedFoods: [], sicknesses: [], disabilities: [] } },
      subscriptions: { create: { plan: 'custom', amount: 0, note: 'Fictional local QA grant only; no store entitlement.', expiresAt: new Date(Date.now() + 30 * 86400000) } },
    } });
    console.log('Created new loopback PostgreSQL cluster, isolated schema, and fictional Premium QA account. Credentials saved privately; not printed.');
  } finally { await prisma.$disconnect(); }
}
main().catch(() => { console.error('Local-only initialization stopped. Inspect private local logs; preserve any partially created cluster. No remote database was used.'); process.exitCode = 1; });
