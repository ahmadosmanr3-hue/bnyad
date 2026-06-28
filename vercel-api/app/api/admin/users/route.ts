import { prisma } from '@/lib/db';
import { daysLeft, isAdminAuthed } from '@/lib/admin';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Lists users with login info + current subscription status. Supports ?q=search. */
export async function GET(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const url = new URL(req.url);
  const q = url.searchParams.get('q')?.trim() ?? '';

  const users = await prisma.user.findMany({
    where: q
      ? {
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { phone: { contains: q } },
            { email: { contains: q, mode: 'insensitive' } },
          ],
        }
      : undefined,
    orderBy: { id: 'desc' },
    take: 500,
    include: {
      profile: { select: { displayName: true, language: true, goal: true, onboarded: true } },
      subscriptions: { orderBy: { expiresAt: 'desc' } },
    },
  });

  const now = new Date();
  const data = users.map((u) => {
    const active = u.subscriptions.find((s) => s.active && s.expiresAt.getTime() > now.getTime());
    const totalPaid = u.subscriptions.reduce((sum, s) => sum + s.amount, 0);
    return {
      id: u.id,
      name: u.profile?.displayName || u.name,
      phone: u.phone,
      email: u.email,
      language: u.profile?.language ?? null,
      goal: u.profile?.goal ?? null,
      onboarded: u.profile?.onboarded ?? false,
      phoneVerified: !!u.phoneVerifiedAt,
      createdAt: u.createdAt,
      isPremium: !!active,
      daysLeft: active ? daysLeft(active.expiresAt, now) : 0,
      expiresAt: active?.expiresAt ?? null,
      subscriptionCount: u.subscriptions.length,
      totalPaid: Math.round(totalPaid * 100) / 100,
    };
  });

  return json({ data, count: data.length });
}
