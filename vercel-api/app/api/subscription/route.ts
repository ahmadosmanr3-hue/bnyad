import { safeRoute } from '@/lib/http';
import { verifiedStoreEntitlement } from '@/lib/subscription';
import { RequestError } from '@/lib/http';
import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { daysLeft } from '@/lib/admin';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Current user's premium status, used by the app to unlock premium features. */
async function handleGET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const store = user.subscriptions.find((s) => s.plan === 'store_verified' && s.active);
  if (store && process.env.REVENUECAT_SECRET_API_KEY) {
    try {
      const verified = await verifiedStoreEntitlement(user.id);
      await prisma.subscription.updateMany({
        where: { userId: user.id, plan: 'store_verified' },
        data: { expiresAt: verified.expiresAt, active: true },
      });
    } catch (e) {
      if (e instanceof RequestError && e.status === 403) {
        await prisma.subscription.updateMany({
          where: { userId: user.id, plan: 'store_verified', active: true },
          data: { active: false },
        });
      }
      // Upstream outages preserve previous verified status until its known
      // expiry. An actual revoked/expired entitlement affects store rows only.
    }
  }

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
async function handlePOST(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);
  const verified = await verifiedStoreEntitlement(user.id);
  const sub = await prisma.$transaction(async (tx) => {
    await tx.$queryRaw`SELECT id FROM users WHERE id = ${user.id} FOR UPDATE`;
    const current = await tx.subscription.findFirst({
      where: { userId: user.id, plan: 'store_verified' }, orderBy: { id: 'desc' },
    });
    const data = { expiresAt: verified.expiresAt, active: true, note: verified.product };
    return current
      ? tx.subscription.update({ where: { id: current.id }, data })
      : tx.subscription.create({ data: { userId: user.id, plan: 'store_verified', amount: 0, ...data } });
  });
  return json({ ok: true, subscription: sub }, 201);
}

export const GET = safeRoute(handleGET);
export const POST = safeRoute(handlePOST);
