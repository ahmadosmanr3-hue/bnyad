import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { daysLeft } from '@/lib/admin';
import { error, json, options, readJson } from '@/lib/http';

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

/** Saves/synchronizes a user subscription on the server. */
export async function POST(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  let body;
  try {
    body = await readJson<{
      plan?: string;
      expiresAt?: string;
      amount?: number;
      currency?: string;
    }>(req);
  } catch {
    return error('Invalid JSON body.', 400);
  }

  const plan = body.plan?.trim() || 'custom';
  const amount = Number(body.amount ?? 0);
  const currency = body.currency?.trim() || 'USD';

  if (!body.expiresAt) {
    return error('expiresAt is required.', 422);
  }
  const expiresAt = new Date(body.expiresAt);
  if (isNaN(expiresAt.getTime())) {
    return error('Invalid expiresAt date format.', 422);
  }

  const sub = await prisma.subscription.create({
    data: {
      userId: user.id,
      plan,
      amount,
      currency,
      expiresAt,
      active: true,
    },
  });

  console.log(
    `[Subscription purchased] User ID: ${user.id}, Name: "${user.name}", Plan: "${plan}", Amount: ${amount} ${currency}, Expires: ${expiresAt.toISOString()}`
  );

  return json({ ok: true, subscription: sub }, 201);
}
