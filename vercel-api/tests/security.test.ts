import { test, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';
import { prisma } from '../lib/db';
import { createSession, userFromAuthHeader, mapProfileUpdate, parseDate, isProduction } from '../lib/auth';
import { tokenDigest, limitAuth } from '../lib/security';
import { verifiedStoreEntitlement } from '../lib/subscription';
import { safeRoute, RequestError, readJson } from '../lib/http';
import { POST as subscription, GET as getSubscription } from '../app/api/subscription/route';
import { POST as logout } from '../app/api/auth/logout/route';
import { POST as requestOtp } from '../app/api/auth/request-otp/route';
import { DELETE as deleteLog } from '../app/api/logs/[id]/route';
import { PUT as profile } from '../app/api/profile/route';
import { PUT as mealPlan } from '../app/api/meal-plan/route';
import { GET as me } from '../app/api/auth/me/route';

const restorers: (() => void)[] = [];
function stub(target: any, name: string, implementation: (...args: any[]) => any) {
  const original = target[name];
  const fn = mock.fn(implementation);
  target[name] = fn;
  restorers.push(() => { target[name] = original; });
  return fn;
}
const originalEnv = { ...process.env };
const token = 'a'.repeat(80);
const user = { id: 1, name: 'Test', profile: null, subscriptions: [] };
const req = (path: string, method = 'POST', body?: unknown) => new Request(`http://localhost/api/${path}`, {
  method, headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
});
const signedIn = () => stub(prisma.apiToken, 'findUnique', async () => ({ id: 1, user }));

beforeEach(() => { delete process.env.REVENUECAT_SECRET_API_KEY; });
afterEach(() => {
  while (restorers.length) restorers.pop()!();
  mock.restoreAll();
  for (const name of Object.keys(process.env)) if (!(name in originalEnv)) delete process.env[name];
  Object.assign(process.env, originalEnv);
});

test('new sessions store a digest, not the issued bearer credential', async () => {
  let stored = '';
  stub(prisma.apiToken, 'create', async (args: any) => { stored = args.data.token; return {}; });
  const issued = await createSession(1);
  assert.match(issued, /^[a-f0-9]{80}$/);
  assert.equal(stored, tokenDigest(issued));
  assert.notEqual(stored, issued);
});

test('legacy bearer sessions remain valid and migrate transparently', async () => {
  stub(prisma.apiToken, 'findUnique', async (args: any) => args.where.token === token ? { id: 4, user } : null);
  let migrated: any;
  stub(prisma.apiToken, 'updateMany', async (args: any) => { migrated = args; return { count: 1 }; });
  assert.equal((await userFromAuthHeader(`Bearer ${token}`))?.id, 1);
  assert.equal(migrated.data.token, tokenDigest(token));
});

test('database digests cannot be used as bearer credentials', async () => {
  const lookup = stub(prisma.apiToken, 'findUnique', async () => { throw Error('should not run'); });
  assert.equal(await userFromAuthHeader(`Bearer ${tokenDigest(token)}`), null);
  assert.equal(lookup.mock.callCount(), 0);
});

test('logout revokes both new and legacy representations', async () => {
  signedIn(); let revoked: any;
  stub(prisma.apiToken, 'deleteMany', async (args: any) => { revoked = args; return { count: 1 }; });
  assert.equal((await logout(req('auth/logout'))).status, 200);
  assert.deepEqual(revoked.where.token.in, [token, tokenDigest(token)]);
});

test('database outage returns 503, never a false invalid-session 401', async () => {
  stub(prisma.apiToken, 'findUnique', async () => { throw Error('private database connection'); });
  const response = await me(req('auth/me', 'GET'));
  assert.equal(response.status, 503);
  assert.ok(!(await response.text()).includes('private database'));
});

test('invalid/revoked sessions return 401', async () => {
  stub(prisma.apiToken, 'findUnique', async () => null);
  assert.equal((await me(req('auth/me', 'GET'))).status, 401);
});

test('profile writes cannot reassign owners, ids or nested relations', () => {
  for (const field of ['user_id', 'userId', 'id', 'user', 'subscriptions']) {
    assert.throws(() => mapProfileUpdate({ [field]: { connect: { id: 2 } } }), RequestError);
  }
  assert.deepEqual(mapProfileUpdate({ daily_calories: 1800, language: 'ckb', onboarded: true }),
    { dailyCalories: 1800, language: 'ku', onboarded: true });
  assert.throws(() => mapProfileUpdate({ daily_calories: -5 }), RequestError);
  assert.throws(() => mapProfileUpdate({ allergies: ['a'.repeat(121)] }), RequestError);
});

test('profile endpoint returns validation errors without database writes', async () => {
  signedIn();
  const write = stub(prisma.userProfile, 'upsert', async () => { throw Error('should not write'); });
  assert.equal((await profile(req('profile', 'PUT', { user_id: 2 }))).status, 422);
  assert.equal(write.mock.callCount(), 0);
});

test('strict dates reject impossible dates and malformed input', () => {
  assert.equal(parseDate('2026-10-13').toISOString().slice(0, 10), '2026-10-13');
  for (const date of ['2026-02-30', '2026-13-01', 'nonsense']) assert.throws(() => parseDate(date), RequestError);
});

test('untrusted clients cannot grant premium without configured verification', async () => {
  signedIn();
  const write = stub(prisma.subscription, 'create', async () => { throw Error('must not grant'); });
  const response = await subscription(req('subscription', 'POST', { expiresAt: '2099-01-01', amount: 999999 }));
  assert.equal(response.status, 503);
  assert.equal(write.mock.callCount(), 0);
});

test('RevenueCat verification uses the authenticated identity and trusted expiry only', async () => {
  process.env.REVENUECAT_SECRET_API_KEY = 'test-only-placeholder';
  const expires = new Date(Date.now() + 86400000).toISOString();
  const result = await verifiedStoreEntitlement(42, async (url, init) => {
    assert.equal(url, 'https://api.revenuecat.com/v1/subscribers/42');
    assert.equal((init?.headers as any).Authorization, 'Bearer test-only-placeholder');
    return Response.json({ subscriber: { entitlements: { all_feature: { expires_date: expires, product_identifier: 'monthly' } } } });
  });
  assert.equal(result.expiresAt.toISOString(), expires);
});

test('expired, missing, malformed and upstream-failed entitlements fail closed', async () => {
  process.env.REVENUECAT_SECRET_API_KEY = 'test-only-placeholder';
  for (const data of [{}, { subscriber: { entitlements: { all_feature: { expires_date: '2000-01-01' } } } },
    { subscriber: { entitlements: { all_feature: { expires_date: 'invalid' } } } }]) {
    await assert.rejects(verifiedStoreEntitlement(1, async () => Response.json(data)), RequestError);
  }
  await assert.rejects(verifiedStoreEntitlement(1, async () => new Response(null, { status: 500 })), RequestError);
});

test('store revocation affects verified store rows and preserves manual subscriptions', async () => {
  process.env.REVENUECAT_SECRET_API_KEY = 'test-only-placeholder';
  stub(prisma.apiToken, 'findUnique', async () => ({ id: 1, user: {
    ...user, subscriptions: [{ id: 5, plan: 'store_verified', active: true }],
  } }));
  let update: any;
  stub(prisma.subscription, 'updateMany', async (args: any) => { update = args; return { count: 1 }; });
  stub(prisma.subscription, 'findFirst', async () => ({ plan: 'custom', expiresAt: new Date(Date.now() + 86400000) }));
  stub(globalThis, 'fetch', async () => Response.json({ subscriber: { entitlements: {} } }));
  const response = await getSubscription(req('subscription', 'GET'));
  assert.equal(response.status, 200);
  assert.equal((await response.json()).isPremium, true);
  assert.equal(update.where.plan, 'store_verified');
  assert.equal(update.data.active, false);
});

test('rate limits count across parallel requests and emit Retry-After', async () => {
  const counts = new Map<string, number>();
  stub(prisma, '$queryRaw', async (_parts: any, key: string) => {
    const count = (counts.get(key) ?? 0) + 1; counts.set(key, count); return [{ count }];
  });
  const results = await Promise.all(Array.from({ length: 20 }, () => limitAuth(req('auth/login'), '+9647000000000')));
  assert.equal(results.filter((r) => r?.status === 429).length, 5);
  assert.ok(results.find(Boolean)?.headers.has('Retry-After'));
  assert.ok([...counts.keys()].every((key) => /^[a-f0-9]{64}$/.test(key)));
});

test('missing rate-limit migration fails closed', async () => {
  stub(prisma, '$queryRaw', async () => { throw Error('missing table'); });
  assert.equal((await limitAuth(req('auth/login'), 'phone'))?.status, 503);
});

test('production disables demo OTP even if APP_ENV is misconfigured', () => {
  Object.assign(process.env, { NODE_ENV: 'production' }); process.env.APP_ENV = 'development';
  assert.equal(isProduction(), true);
});

test('OTP delivery failure does not report success or leave usable OTP', async () => {
  Object.assign(process.env, { NODE_ENV: 'production' }); process.env.OTPIQ_API_KEY = 'test-only-placeholder';
  stub(prisma, '$queryRaw', async () => [{ count: 1 }]);
  stub(prisma.user, 'findUnique', async () => null);
  stub(prisma.phoneOtp, 'deleteMany', async () => ({ count: 1 }));
  stub(prisma.phoneOtp, 'create', async () => ({ id: 7 }));
  stub(globalThis, 'fetch', async () => new Response(null, { status: 502 }));
  const response = await requestOtp(req('auth/request-otp', 'POST', { phone: '+9647000000000' }));
  assert.equal(response.status, 503);
  assert.equal((await response.json()).demo_code, undefined);
});

test('users cannot delete another user food log', async () => {
  signedIn();
  stub(prisma.dailyLog, 'findUnique', async () => ({ id: 5, userId: 2 }));
  const remove = stub(prisma.dailyLog, 'delete', async () => { throw Error('must not delete'); });
  const response = await deleteLog(req('logs/5', 'DELETE'), { params: Promise.resolve({ id: '5' }) });
  assert.equal(response.status, 404); assert.equal(remove.mock.callCount(), 0);
});

test('invalid meal plan leaves the previous plan untouched', async () => {
  signedIn();
  const write = stub(prisma.mealPlan, 'upsert', async () => { throw Error('must not write'); });
  assert.equal((await mealPlan(req('meal-plan', 'PUT', { plan: { lunch: { calories: -1 } } }))).status, 422);
  assert.equal(write.mock.callCount(), 0);
});

test('malformed/array JSON is a 400 and internal failures are masked', async () => {
  const route = safeRoute(async (request: Request) => { await readJson(request); return Response.json({ ok: true }); });
  const malformed = new Request('http://localhost', { method: 'POST', body: '{' });
  assert.equal((await route(malformed)).status, 400);
  assert.equal((await route(req('profile', 'POST', []))).status, 400);
});
