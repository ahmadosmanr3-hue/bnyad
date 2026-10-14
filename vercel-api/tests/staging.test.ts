import { test, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { assertStagingDatabase } from '../lib/staging';
import { prisma } from '../lib/db';
import { GET } from '../app/api/staging/readiness/route';

const config = {
  APP_ENV: 'staging',
  DATABASE_URL: 'postgresql://fixture:fixture@ep-stage-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require',
  STAGING_DATABASE_HOST: 'ep-stage-pooler.us-east-2.aws.neon.tech',
  STAGING_DATABASE_NAME: 'neondb',
  STAGING_ENVIRONMENT_ID: 'bnyad-staging-fixture',
  AI_ENABLED: 'false',
};
const saved = { ...process.env };
const query = prisma.$queryRaw;
afterEach(() => {
  prisma.$queryRaw = query;
  for (const key of Object.keys(process.env)) if (!(key in saved)) delete process.env[key];
  Object.assign(process.env, saved);
});

test('staging validates an independently approved Neon target with TLS and AI off', () => {
  assert.doesNotThrow(() => assertStagingDatabase(config));
  assert.doesNotThrow(() => assertStagingDatabase({ APP_ENV: 'production' }));
});

test('wrong database, missing identity, non-Neon target, disabled TLS and AI are blocked', () => {
  for (const override of [
    { STAGING_DATABASE_HOST: 'ep-production.neon.tech' },
    { STAGING_DATABASE_NAME: 'production' },
    { STAGING_ENVIRONMENT_ID: '' },
    { STAGING_DATABASE_HOST: '' },
    { DATABASE_URL: 'postgresql://fixture:fixture@localhost/neondb?sslmode=require' },
    { DATABASE_URL: config.DATABASE_URL.replace('require', 'disable') },
    { DATABASE_URL: config.DATABASE_URL.replace('fixture:fixture@', '') },
    { AI_ENABLED: 'true' }, { AI_ENABLED: '' },
  ]) {
    assert.throws(() => assertStagingDatabase({ ...config, ...override }), (e: Error) =>
      !e.message.includes('postgresql:') && e.message.includes('Staging configuration rejected'));
  }
});

test('readiness is unavailable on production and performs no database query', async () => {
  process.env.APP_ENV = 'production';
  prisma.$queryRaw = (async () => { throw new Error('must not query'); }) as any;
  assert.equal((await GET()).status, 404);
});

test('staging readiness requires migrations and reports only a public identity', async () => {
  Object.assign(process.env, config);
  prisma.$queryRaw = (async () => [{ count: 16 }]) as any;
  assert.equal((await GET()).status, 503);
  prisma.$queryRaw = (async () => [{ count: 17 }]) as any;
  const result = await GET();
  assert.equal(result.status, 200);
  assert.deepEqual(await result.json(), {
    environment: 'staging', environmentId: config.STAGING_ENVIRONMENT_ID,
    databaseReady: true, aiEnabled: false, contractVersion: 1,
  });
  assert.equal(result.headers.get('Cache-Control'), 'no-store');
});
