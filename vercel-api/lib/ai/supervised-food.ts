import fs from 'node:fs';
import path from 'node:path';
import { RequestError } from '../http';
import { assertLocalDevelopment, localLedgerDirectory } from '../local-development';
import { DevelopmentBudget, privateConfiguration } from '../../scripts/lib/gemini-development';
import { callGemini, type Config } from './provider';
import type { Input } from './contract';

export const FOOD_TEST_MODEL = 'gemini-3.5-flash-lite';
export const FOOD_TEST_CAP = 21;
export const FOOD_TEST_FILE = '.local-development/supervised-food.json';
export type FoodTestApproval = { version: 1; id: string; userId: number; operation: 'food'; model: typeof FOOD_TEST_MODEL;
  requestCap: 21; startRequests: 19; enabled: boolean; state: 'armed' | 'claimed' | 'finished' | 'failed' | 'disarmed'; expiresAt: string };

function privateJson(file: string) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.mode & 0o077) throw new RequestError('Private local test configuration is required.', 503);
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}
export function foodApproval(): FoodTestApproval | undefined {
  assertLocalDevelopment();
  if (!fs.existsSync(FOOD_TEST_FILE)) return;
  const a = privateJson(FOOD_TEST_FILE);
  if (a.version !== 1 || !/^[a-f0-9-]{36}$/.test(a.id) || !Number.isInteger(a.userId) || a.userId < 1 ||
      a.operation !== 'food' || a.model !== FOOD_TEST_MODEL || a.requestCap !== 21 || a.startRequests !== 19 ||
      !['armed','claimed','finished','failed','disarmed'].includes(a.state) || typeof a.enabled !== 'boolean' ||
      !Number.isFinite(Date.parse(a.expiresAt))) throw new RequestError('One-use food approval needs owner review.', 503);
  return a;
}
function saveApproval(a: FoodTestApproval) {
  const fd = fs.openSync(FOOD_TEST_FILE, 'w', 0o600);
  try { fs.writeFileSync(fd, JSON.stringify(a)); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
}
export function foodTestArmed() {
  const a = foodApproval();
  return !!a && a.enabled && a.state === 'armed' && Date.parse(a.expiresAt) > Date.now();
}
export function requireFoodApproval(userId: number): FoodTestApproval {
  const a = foodApproval();
  if (!a || !a.enabled || a.state !== 'armed' || Date.parse(a.expiresAt) <= Date.now()) {
    throw new RequestError('The supervised food scan is not armed or has already been used. No retry is permitted.', 503);
  }
  if (a.userId !== userId) throw new RequestError('This account is not approved for the supervised food test.', 403);
  return a;
}
export function localFoodTestSelected(operation: string, userId: number, requested: boolean) {
  if (process.env.APP_ENV !== 'local-iphone' || !requested) return false;
  if (operation !== 'food') throw new RequestError('Only one food-photo scan is approved.', 422);
  requireFoodApproval(userId);
  return true;
}
export function recordFoodTest(report: Record<string, unknown>) {
  assertLocalDevelopment();
  const a = foodApproval();
  if (!a || a.state === 'armed') return;
  // Only the authorized fictional-food response/usage, never photos, prompts,
  // profile data, session tokens, headers or the provider key.
  fs.writeFileSync('.local-development/supervised-food-result.json', JSON.stringify({ approvalId: a.id, ...report }, null, 2), { mode: 0o600 });
}
export async function supervisedFood(prompt: string, input: Input, config: Config, userId: number, transport: typeof fetch = fetch) {
  assertLocalDevelopment();
  if (!input.image || config.model !== FOOD_TEST_MODEL) throw new RequestError('The approved food image/model is required.', 422);
  const directory = localLedgerDirectory();
  const credentials = privateConfiguration(path.resolve('.env.gemini-development.local'));
  if (credentials.model !== FOOD_TEST_MODEL) throw new RequestError('The private model configuration does not match approval.', 503);
  const budget = new DevelopmentBudget(directory, FOOD_TEST_MODEL, transport, false, FOOD_TEST_CAP);
  let a: FoodTestApproval | undefined;
  let generated = false;
  try {
    a = requireFoodApproval(userId);
    if (budget.requests !== 19) throw new RequestError('The two-call supervised test requires the existing 19-request ledger. Stop for owner review.', 429);
    // Consume approval BEFORE any IO. The shared budget lock prevents races;
    // a crash leaves a claimed (disabled) grant, never a reusable permission.
    a.enabled = false; a.state = 'claimed'; saveApproval(a);
    const result = await callGemini('food', prompt, input, { ...config, model: FOOD_TEST_MODEL, key: credentials.key }, budget.fetch);
    generated = true;
    return result;
  } catch (e) {
    if (a?.state === 'claimed') recordFoodTest({ status: 'provider-failed', httpRequests: budget.requests, error: e instanceof RequestError ? e.message : 'Provider request stopped without retry.' });
    throw e;
  } finally {
    if (a?.state === 'claimed') { a.enabled = false; a.state = generated ? 'finished' : 'failed'; saveApproval(a); }
    budget.close();
  }
}

/** Network gate installed by the local server. A separate one-use receipt per
 * method makes accidental duplicate fetches fail before network IO, even if a
 * caller somehow tries to bypass the provider's normal two-request sequence.
 */
export function localNetworkTransport(original: typeof fetch): typeof fetch {
  return (async (input: any, init: any) => {
    const url = new URL(typeof input === 'string' || input instanceof URL ? input : input.url);
    if (['127.0.0.1','localhost'].includes(url.hostname)) return original(input, init);
    assertLocalDevelopment();
    const a = foodApproval(), directory = localLedgerDirectory();
    const method = url.pathname.endsWith(':countTokens') ? 'countTokens' : url.pathname.endsWith(':generateContent') ? 'generateContent' : '';
    const expected = `https://generativelanguage.googleapis.com/v1beta/models/${FOOD_TEST_MODEL}:${method}`;
    if (!a || a.enabled || a.state !== 'claimed' || Date.parse(a.expiresAt) <= Date.now() ||
        !method || url.toString() !== expected || init?.method !== 'POST' || !fs.existsSync(path.join(directory, 'session.lock'))) {
      throw new RequestError('External request blocked by supervised local safeguards.', 503);
    }
    const ledger = privateJson(path.join(directory, 'requests.json'));
    if (ledger.requests !== (method === 'countTokens' ? 20 : 21) || ledger.blocked) throw new RequestError('Gemini HTTP allowance blocked.', 429);
    const credentials = privateConfiguration(path.resolve('.env.gemini-development.local'));
    if (new Headers(init.headers).get('x-goog-api-key') !== credentials.key) throw new RequestError('Provider credential mismatch.', 503);
    const receipt = `.local-development/supervised-${a.id}-${method}.json`;
    fs.writeFileSync(receipt, JSON.stringify({ method, attempt: ledger.requests, started: true }), { mode: 0o600, flag: 'wx' });
    try {
      const response = await original(input, { ...init, redirect: 'error' });
      fs.writeFileSync(receipt, JSON.stringify({ method, attempt: ledger.requests, httpStatus: response.status }), { mode: 0o600 });
      return response;
    } catch (e) {
      fs.writeFileSync(receipt, JSON.stringify({ method, attempt: ledger.requests, networkFailed: true }), { mode: 0o600 });
      throw e;
    }
  }) as typeof fetch;
}
