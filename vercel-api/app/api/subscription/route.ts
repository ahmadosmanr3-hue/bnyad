import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { daysLeft } from '@/lib/admin';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Current user's premium status, used by the app to unlock premium features. */
export async function GET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const now = new Date();
  const sub = await prisma.subscription.findFirst({
    where: { userId: user.id, active: true, expiresAt: { gt: now } },
    orderBy: { expiresAt: 'desc' },
  });

  return json({
    isPremium: !!sub,
    expiresAt: sub?.expiresAt ?? null,
    daysLeft: sub ? daysLeft(sub.expiresAt, now) : 0,
    plan: sub?.plan ?? null,
  });
}
