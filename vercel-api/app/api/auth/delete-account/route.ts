import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/**
 * Permanently deletes the authenticated user's account and all associated data.
 * Adheres to Apple App Store Review Guideline 5.1.1(v).
 */
export async function DELETE(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  // Prisma schema cascades will automatically delete:
  // - UserProfile
  // - ApiTokens
  // - DailyLogs
  // - WaterLogs
  // - WeightEntries
  // - MealPlans & MealPlanItems
  // - Subscriptions
  // - Notifications
  await prisma.user.delete({
    where: { id: user.id },
  });

  return json({
    ok: true,
    message: 'Your account and all associated personal data have been permanently deleted.',
  });
}
