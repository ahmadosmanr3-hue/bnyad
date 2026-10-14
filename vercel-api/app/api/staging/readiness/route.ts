import { prisma } from '@/lib/db';
import { assertStagingDatabase } from '@/lib/staging';
import { json, safeRoute } from '@/lib/http';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

async function handleGET() {
  if (process.env.APP_ENV !== 'staging') return json({ message: 'Not found.' }, 404);
  assertStagingDatabase();
  // Read schema metadata only, never accounts or health data. All current
  // application tables, including the auth/AI migrations, must be installed.
  const rows = await prisma.$queryRaw<{ count: number }[]>`
    SELECT COUNT(*)::integer AS count FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      AND table_name IN (
        'users', 'user_profiles', 'api_tokens', 'phone_otps', 'subscriptions',
        'notifications', 'daily_logs', 'water_logs', 'weight_entries',
        'meal_plans', 'meal_plan_items', 'food_items', 'food_item_translations',
        'auth_rate_limits', 'ai_consents', 'ai_usage', 'ai_cache'
      )`;
  if (rows[0]?.count !== 17) {
    return json({ message: 'Staging schema migrations are incomplete.' }, 503);
  }
  return json({
    environment: 'staging',
    environmentId: process.env.STAGING_ENVIRONMENT_ID,
    databaseReady: true,
    aiEnabled: false,
    contractVersion: 1,
  });
}

export const GET = safeRoute(handleGET);
