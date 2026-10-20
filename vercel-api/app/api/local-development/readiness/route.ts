import { prisma } from '@/lib/db';
import { assertLocalDevelopment, localLedgerDirectory } from '@/lib/local-development';
import { json, safeRoute } from '@/lib/http';
import { foodTestArmed, foodApproval } from '@/lib/ai/supervised-food';
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const GET = safeRoute(async () => {
  if (process.env.APP_ENV !== 'local-iphone') return json({ message: 'Not found.' }, 404);
  assertLocalDevelopment(); localLedgerDirectory();
  await prisma.$queryRaw`SELECT 1 FROM users LIMIT 0`;
  const armed = foodTestArmed();
  return json({ environment: 'local-iphone', environmentId: 'bnyad-local-iphone-v1', databaseReady: true,
    aiMode: armed ? 'mock-with-one-use-food' : 'mock', liveGoogleAllowed: armed,
    supervisedFoodArmed: armed, supervisedFoodState: foodApproval()?.state ?? 'not-armed', contractVersion: 1 });
});
