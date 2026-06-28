import { prisma } from '@/lib/db';
import { isAdminAuthed, splitRevenue } from '@/lib/admin';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function GET(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const [totalUsers, allSubs] = await Promise.all([
    prisma.user.count(),
    prisma.subscription.findMany({ select: { amount: true, expiresAt: true, active: true, createdAt: true } }),
  ]);

  const activeSubs = allSubs.filter((s) => s.active && s.expiresAt.getTime() > now.getTime());
  const totalRevenue = allSubs.reduce((sum, s) => sum + s.amount, 0);
  const monthRevenue = allSubs
    .filter((s) => s.createdAt.getTime() >= startOfMonth.getTime())
    .reduce((sum, s) => sum + s.amount, 0);

  return json({
    totalUsers,
    totalSubscriptions: allSubs.length,
    activeSubscriptions: activeSubs.length,
    totalRevenue: Math.round(totalRevenue * 100) / 100,
    monthRevenue: Math.round(monthRevenue * 100) / 100,
    split: {
      total: splitRevenue(totalRevenue),
      month: splitRevenue(monthRevenue),
    },
  });
}
