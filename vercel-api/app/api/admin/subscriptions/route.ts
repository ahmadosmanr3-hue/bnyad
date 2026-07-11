import { prisma } from '@/lib/db';
import { daysLeft, isAdminAuthed } from '@/lib/admin';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Lists all subscriptions, newest first. */
export async function GET(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const subs = await prisma.subscription.findMany({
    orderBy: { createdAt: 'desc' },
    take: 500,
    include: { user: { select: { id: true, name: true, phone: true, profile: { select: { displayName: true } } } } },
  });

  const now = new Date();
  const data = subs.map((s) => ({
    id: s.id,
    userId: s.userId,
    userName: s.user.profile?.displayName || s.user.name,
    phone: s.user.phone,
    plan: s.plan,
    amount: s.amount,
    currency: s.currency,
    startedAt: s.startedAt,
    expiresAt: s.expiresAt,
    note: s.note,
    active: s.active && s.expiresAt.getTime() > now.getTime(),
    daysLeft: s.active ? daysLeft(s.expiresAt, now) : 0,
    createdAt: s.createdAt,
  }));

  return json({ data, count: data.length });
}

/**
 * Records a new subscription (a sale). Body:
 * { userId | phone, days, amount, plan?, currency?, note? }
 */
export async function POST(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const body = await readJson<{
    userId?: number;
    phone?: string;
    days?: number;
    amount?: number;
    plan?: string;
    currency?: string;
    note?: string;
  }>(req);

  const days = Number(body.days);
  const amount = Number(body.amount ?? 0);
  if (!Number.isFinite(days) || days <= 0) {
    return error('Enter the number of days (greater than 0).', 422);
  }
  if (!Number.isFinite(amount) || amount < 0) {
    return error('Enter a valid amount.', 422);
  }

  let userId = body.userId;
  if (!userId && body.phone) {
    const user = await prisma.user.findUnique({ where: { phone: body.phone.trim() } });
    if (!user) return error('No user found with that phone number.', 404);
    userId = user.id;
  }
  if (!userId) return error('Provide a userId or phone.', 422);

  const exists = await prisma.user.findUnique({ where: { id: userId } });
  if (!exists) return error('User not found.', 404);

  // Extend from the later of (now) or (current active expiry) so renewals stack.
  const now = new Date();
  const current = await prisma.subscription.findFirst({
    where: { userId, active: true, expiresAt: { gt: now } },
    orderBy: { expiresAt: 'desc' },
  });
  const base = current ? current.expiresAt : now;
  const expiresAt = new Date(base.getTime() + days * 24 * 60 * 60 * 1000);

  const sub = await prisma.subscription.create({
    data: {
      userId,
      plan: body.plan?.trim() || 'custom',
      amount,
      currency: body.currency?.trim() || 'USD',
      startedAt: now,
      expiresAt,
      note: body.note?.trim() || null,
    },
  });

  console.log(
    `[Subscription Admin Recorded] User ID: ${userId}, Name: "${exists.name}", Phone: "${exists.phone ?? '—'}", Plan: "${sub.plan}", Amount: ${sub.amount} ${sub.currency}, Days: ${days}, Expires: ${expiresAt.toISOString()}`
  );

  return json({ ok: true, subscription: sub }, 201);
}
