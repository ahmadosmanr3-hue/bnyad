import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { DevelopmentBudget, DevelopmentStop, REQUEST_CAP, TEST_MODEL, checkModel, privateConfiguration } from '../scripts/lib/gemini-development';

function temporary(t: { after: (fn: () => void) => void }) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'bnyad-gemini-test-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  return directory;
}
const modelUrl = (model = TEST_MODEL) => `https://generativelanguage.googleapis.com/v1beta/models/${model}`;
const ok = (async () => new Response('{}')) as typeof fetch;
const stopped = (code: string) => (error: unknown) => error instanceof DevelopmentStop && error.code === code;

test('development cap persists across restarts and includes every HTTP attempt', async t => {
  const directory = temporary(t); let calls = 0;
  const transport = (async () => { calls++; return new Response('{}'); }) as typeof fetch;
  let budget = new DevelopmentBudget(directory, TEST_MODEL, transport);
  for (let n = 0; n < 7; n++) await budget.fetch(`${modelUrl()}:countTokens`, { method: 'POST' });
  budget.close();
  budget = new DevelopmentBudget(directory, TEST_MODEL, transport);
  try {
    for (let n = 7; n < REQUEST_CAP; n++) await budget.fetch(`${modelUrl()}:generateContent`, { method: 'POST' });
    await assert.rejects(budget.fetch(modelUrl(), { method: 'GET' }), stopped('twenty_request_cap_reached'));
    assert.equal(calls, 20); assert.equal(budget.requests, 20);
  } finally { budget.close(); }
});
test('exclusive process lock prevents concurrent quota races', t => {
  const directory = temporary(t), budget = new DevelopmentBudget(directory, TEST_MODEL, ok);
  try { assert.throws(() => new DevelopmentBudget(directory), stopped('development_session_locked_review_before_retry')); }
  finally { budget.close(); }
});
test('corrupt ledger fails closed rather than silently replenishing requests', t => {
  const directory = temporary(t);
  fs.writeFileSync(path.join(directory, 'requests.json'), 'incomplete');
  assert.throws(() => new DevelopmentBudget(directory), stopped('invalid_request_ledger_do_not_reset'));
});
test('quota/access/payment failures stop without retry or provider error disclosure', async t => {
  for (const [status, code] of [[400,'provider_request_or_project_ineligible'],[401,'provider_key_rejected'],[402,'provider_payment_required'],[403,'provider_access_denied'],[404,'requested_model_unavailable'],[429,'provider_quota_unavailable'],[500,'provider_failure_no_retry']] as const) {
    let calls = 0; const directory = temporary(t);
    const transport = (async () => { calls++; return new Response('sensitive-provider-body', { status }); }) as typeof fetch;
    let budget = new DevelopmentBudget(directory, TEST_MODEL, transport);
    await assert.rejects(budget.fetch(`${modelUrl()}:countTokens`, { method: 'POST' }), stopped(code));
    await assert.rejects(budget.fetch(`${modelUrl()}:generateContent`, { method: 'POST' }), stopped(code));
    budget.close();
    budget = new DevelopmentBudget(directory, TEST_MODEL, transport);
    try { await assert.rejects(budget.fetch(modelUrl(), { method: 'GET' }), stopped(code)); }
    finally { budget.close(); }
    assert.equal(calls, 1);
    const ledger = fs.readFileSync(path.join(directory, 'requests.json'), 'utf8');
    assert.ok(!ledger.includes('sensitive-provider-body'));
    assert.equal(JSON.parse(ledger).requests, 1);
  }
});
test('uncertain network failures consume their attempt and remain blocked', async t => {
  let calls = 0;
  const budget = new DevelopmentBudget(temporary(t), TEST_MODEL, (async () => { calls++; throw new Error('private-transport-detail'); }) as typeof fetch);
  try {
    await assert.rejects(budget.fetch(modelUrl(), { method: 'GET' }), stopped('provider_network_error_no_retry'));
    await assert.rejects(budget.fetch(modelUrl(), { method: 'GET' }), stopped('provider_network_error_no_retry'));
    assert.equal(calls, 1); assert.equal(budget.requests, 1);
  } finally { budget.close(); }
});
test('transport permits only the configured model, fixed methods and Google host', async t => {
  let calls = 0;
  const budget = new DevelopmentBudget(temporary(t), TEST_MODEL, (async () => { calls++; return new Response('{}'); }) as typeof fetch);
  try {
    for (const url of ['https://example.invalid', `${modelUrl()}?key=fixture`, modelUrl('gemini-3.5-flash-lite')]) {
      await assert.rejects(budget.fetch(url, { method: 'GET' }), stopped('unexpected_provider_request'));
    }
    await assert.rejects(budget.fetch(modelUrl(), { method: 'POST' }), stopped('unexpected_provider_request'));
    assert.equal(calls, 0); assert.equal(budget.requests, 0);
  } finally { budget.close(); }
});
test('owner-approved model change preserves original cap; no silent fallback or quota escape', async t => {
  const fresh = new DevelopmentBudget(temporary(t), 'gemini-3.5-flash-lite', ok);
  assert.equal(fresh.requests, 0); fresh.close();
  const directory = temporary(t);
  const budget = new DevelopmentBudget(directory, TEST_MODEL, (async () => new Response('{}', { status: 404 })) as typeof fetch);
  await assert.rejects(budget.fetch(modelUrl(), { method: 'GET' })); budget.close();
  assert.throws(() => new DevelopmentBudget(directory, 'gemini-3.5-flash-lite', ok), stopped('model_change_requires_owner_approval'));
  const changed = new DevelopmentBudget(directory, 'gemini-3.5-flash-lite', ok, true);
  try { assert.equal(changed.requests, 1); assert.equal(changed.modelAccessible, false); }
  finally { changed.close(); }
  const quotaDirectory = temporary(t);
  const limited = new DevelopmentBudget(quotaDirectory, TEST_MODEL, (async () => new Response('{}', { status: 429 })) as typeof fetch);
  await assert.rejects(limited.fetch(modelUrl(), { method: 'GET' })); limited.close();
  assert.throws(() => new DevelopmentBudget(quotaDirectory, 'gemini-3.5-flash-lite', ok, true), stopped('model_change_requires_owner_approval'));
});
test('key stays in header, model metadata consumes one attempt and is reused locally', async t => {
  let calls = 0;
  const budget = new DevelopmentBudget(temporary(t), TEST_MODEL, (async (url, init) => {
    calls++; assert.ok(!String(url).includes('private-fixture-key'));
    assert.equal(new Headers(init?.headers).get('x-goog-api-key'), 'private-fixture-key');
    assert.equal(init?.redirect, 'error');
    return Response.json({ name:`models/${TEST_MODEL}`, supportedGenerationMethods:['generateContent','countTokens'] });
  }) as typeof fetch);
  try { await checkModel('private-fixture-key', budget); await checkModel('private-fixture-key', budget); assert.equal(calls, 1); }
  finally { budget.close(); }
});
test('private config rejects unconfirmed tier, unreviewed models, missing keys and broad permissions', t => {
  const file = path.join(temporary(t), 'private.env');
  const write = (s: string) => fs.writeFileSync(file, s, { mode: 0o600 });
  write(`GEMINI_API_KEY=fixture\nGEMINI_MODEL=${TEST_MODEL}\n`);
  assert.throws(() => privateConfiguration(file), stopped('owner_free_tier_confirmation_required'));
  write('GEMINI_API_KEY=fixture\nGEMINI_MODEL=unknown\nBNYAD_GEMINI_FREE_TIER_CONFIRMED=true\n');
  assert.throws(() => privateConfiguration(file), stopped('requested_model_must_be_reviewed'));
  write(`GEMINI_API_KEY=\nGEMINI_MODEL=${TEST_MODEL}\nBNYAD_GEMINI_FREE_TIER_CONFIRMED=true\n`);
  assert.throws(() => privateConfiguration(file), stopped('private_key_missing_or_invalid'));
  write(`GEMINI_API_KEY=fixture\nGEMINI_MODEL=${TEST_MODEL}\nBNYAD_GEMINI_FREE_TIER_CONFIRMED=true\n`);
  assert.equal(privateConfiguration(file).model, TEST_MODEL);
  fs.chmodSync(file, 0o644);
  assert.throws(() => privateConfiguration(file), stopped('private_file_permissions_required'));
});
