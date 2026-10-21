import { prisma } from '@/lib/db';
import { assertLocalDevelopment, localLedgerDirectory } from '@/lib/local-development';
import { json, safeRoute } from '@/lib/http';
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const GET = safeRoute(async () => {
  if (process.env.APP_ENV !== 'local-iphone') return json({ message: 'Not found.' }, 404);
  assertLocalDevelopment(); localLedgerDirectory();
  await prisma.$queryRaw`SELECT 1 FROM users LIMIT 0`;
  return json({ environment: 'local-iphone', environmentId: 'bnyad-local-iphone-v1', databaseReady: true,
    aiMode: 'mock', liveGoogleAllowed: false, contractVersion: 1 });
});
