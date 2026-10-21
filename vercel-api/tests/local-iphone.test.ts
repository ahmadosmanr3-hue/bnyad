import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { assertLocalDevelopment, LOCAL_DATABASE, privateLanAddress } from '../lib/local-development';
import { generateWithLocalGuard, withDevelopmentBudget } from '../lib/ai/local-provider';
import { buildPrompt, validateOutput } from '../lib/ai/contract';
import type { Config } from '../lib/ai/provider';

const env = { APP_ENV: 'local-iphone', NODE_ENV: 'development', BNYAD_LOCAL_TEST: 'true',
  BNYAD_LOCAL_ENVIRONMENT_ID: 'bnyad-local-iphone-v1', BNYAD_LOCAL_AI_MODE: 'mock',
  DATABASE_URL: `postgresql://fictional:fictional@127.0.0.1:55439/${LOCAL_DATABASE}` };
const original = { ...process.env }, originalCwd = process.cwd(), temporary: string[] = [];
afterEach(() => { process.chdir(originalCwd); for (const key of Object.keys(process.env)) if (!(key in original)) delete process.env[key]; Object.assign(process.env, original); for (const dir of temporary.splice(0)) fs.rmSync(dir, { recursive: true }); });
function local() {
  Object.assign(process.env, env); delete process.env.VERCEL;
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'bnyad-local-guard-')); temporary.push(dir); process.chdir(dir);
  fs.mkdirSync('.gemini-development', { mode: 0o700 });
  fs.writeFileSync('.gemini-development/requests.json', JSON.stringify({ version: 1, requests: 19, model: 'gemini-3.5-flash-lite' }), { mode: 0o600 });
}
const config: Config = { key: 'mock-only', model: 'gemini-3.5-flash-lite', enabled: true, inputRate: .3, outputRate: 2.5,
  budgetMicros: 1000000, dailyLimit: 100, minuteLimit: 20, inputLimit: 12000, outputLimit: 8192, timeoutMs: 25000, cacheSeconds: 21600 };
const profile = { dailyCalories: 2000, dailyProtein: 100, dailyCarbs: 260, dailyFat: 60 };
test('local backend guard refuses production, hosted, wrong DB, role-less and ambiguous configuration', () => {
  assert.doesNotThrow(() => assertLocalDevelopment(env));
  for (const changed of [{ NODE_ENV: 'production' }, { VERCEL: '1' }, { BNYAD_LOCAL_TEST: 'false' }, { BNYAD_LOCAL_AI_MODE: 'unknown' },
    { DATABASE_URL: env.DATABASE_URL.replace('127.0.0.1', 'production.example') }, { DATABASE_URL: env.DATABASE_URL.replace(':55439', ':5432') },
    { DATABASE_URL: env.DATABASE_URL + '?host=production.example' }, { DATABASE_URL: env.DATABASE_URL.replace(LOCAL_DATABASE, 'postgres') }]) {
    assert.throws(() => assertLocalDevelopment({ ...env, ...changed }));
  }
});
test('LAN binding accepts only RFC1918 IPv4, never wildcard, public or loopback', () => {
  for (const host of ['192.168.1.117','10.1.2.3','172.16.1.2','172.31.1.2']) assert.equal(privateLanAddress(host), true);
  for (const host of ['0.0.0.0','127.0.0.1','8.8.8.8','172.32.1.2','192.168.1.999','192.168.01.1','localhost','::']) assert.equal(privateLanAddress(host), false);
});
test('mock daily/recipe/photo/fridge responses pass full validators and never consume the Google ledger', async () => {
  local(); const before = fs.readFileSync('.gemini-development/requests.json', 'utf8');
  const previous = globalThis.fetch; let calls = 0;
  globalThis.fetch = (async () => { calls++; throw new Error('Unexpected Google IO'); }) as typeof fetch;
  try {
    for (const operation of ['meal-plan','recipe','food','fridge'] as const) {
      const input = operation === 'recipe' ? { ingredients: ['rice','chicken','tomato'] } : {};
      const result = await generateWithLocalGuard(operation, buildPrompt(operation, input, profile), input, config);
      const valid = validateOutput(operation, result.result, input, profile);
      assert.ok(valid);
    }
    assert.equal(calls, 0); assert.equal(fs.readFileSync('.gemini-development/requests.json', 'utf8'), before);
  } finally { globalThis.fetch = previous; }
});
test('mock failure/malformed/rate-limit use real provider error paths without retries', async () => {
  local();
  for (const scenario of ['unavailable','malformed','rate-limit']) await assert.rejects(generateWithLocalGuard('recipe', buildPrompt('recipe', { ingredients: ['rice'] }, profile), { ingredients: ['rice'] }, config, scenario));
  assert.equal(JSON.parse(fs.readFileSync('.gemini-development/requests.json', 'utf8')).requests, 19);
});
test('actual local endpoint provider blocks live configuration and insufficient remaining allowance', async () => {
  local(); process.env.BNYAD_LOCAL_AI_MODE = 'live'; let calls = 0;
  await assert.rejects(generateWithLocalGuard('recipe', buildPrompt('recipe', { ingredients: ['rice'] }, profile), { ingredients: ['rice'] }, config));
  await assert.rejects(withDevelopmentBudget(config.model, async transport => { calls++; await transport('never'); }, (async () => { calls++; return Response.json({}); }) as typeof fetch), /Insufficient authorized/);
  assert.equal(calls, 0); assert.equal(JSON.parse(fs.readFileSync('.gemini-development/requests.json', 'utf8')).requests, 19);
  assert.equal(fs.existsSync('.gemini-development/session.lock'), false);
});
test('missing, reset, public-readable or corrupt shared ledger fails closed', async () => {
  local(); const file = '.gemini-development/requests.json';
  for (const value of ['{}','bad',JSON.stringify({ version:1, requests:0 }),JSON.stringify({ version:1, requests:21 })]) {
    fs.writeFileSync(file, value); await assert.rejects(generateWithLocalGuard('food', buildPrompt('food', {}, profile), {}, config));
  }
  fs.writeFileSync(file, JSON.stringify({ version:1, requests:19 })); fs.chmodSync(file, 0o644);
  await assert.rejects(generateWithLocalGuard('food', buildPrompt('food', {}, profile), {}, config));
  fs.unlinkSync(file); await assert.rejects(generateWithLocalGuard('food', buildPrompt('food', {}, profile), {}, config));
});
test('existing empty bootstrap contains SQL, not an accidentally captured CLI upgrade notice', () => {
  const sql = fs.readFileSync(path.join(originalCwd, 'db/20261014_staging_empty_bootstrap.sql'), 'utf8');
  assert.ok(sql.trimEnd().endsWith('COMMIT;')); assert.ok(!/[┌│└]/u.test(sql)); assert.ok(sql.includes('public schema is not empty'));
});
