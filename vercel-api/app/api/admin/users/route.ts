import { prisma } from '@/lib/db';
import { daysLeft, isAdminAuthed } from '@/lib/admin';
import { error, json, options, readJson } from '@/lib/http';
import { hashPassword, userToJson } from '@/lib/auth';

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
      plan: active?.plan ?? null,
      daysLeft: active ? daysLeft(active.expiresAt, now) : 0,
      expiresAt: active?.expiresAt ?? null,
      subscriptionCount: u.subscriptions.length,
      totalPaid: Math.round(totalPaid * 100) / 100,
    };
  });

  return json({ data, count: data.length });
}

/** Creates a new user. */
export async function POST(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  let body;
  try {
    body = await readJson<{
      name?: string;
      phone?: string;
      email?: string;
      password?: string;
      phoneVerified?: boolean;
    }>(req);
  } catch {
    return error('Invalid JSON body.', 400);
  }

  const name = body.name?.trim() || 'BNYAD user';
  const phone = body.phone?.trim() || null;
  const email = body.email?.trim() || (phone ? `${phone.replace(/\D/g, '')}@phone.bnyad.app` : undefined);
  const password = body.password ?? '';
  const phoneVerified = !!body.phoneVerified;

  if (!email) {
    return error('Email is required.', 422);
  }

  // Check email uniqueness
  const emailExists = await prisma.user.findUnique({ where: { email } });
  if (emailExists) return error('Another user already uses that email.', 409);

  // Check phone uniqueness if provided
  if (phone) {
    if (!/^\+?[0-9]{7,15}$/.test(phone)) {
      return error('Enter a valid phone number.', 422);
    }
    const phoneExists = await prisma.user.findUnique({ where: { phone } });
    if (phoneExists) return error('Another user already uses that phone.', 409);
  }

  if (password.length < 6) {
    return error('Password must be at least 6 characters.', 422);
  }

  const passwordHash = await hashPassword(password);
  const phoneVerifiedAt = phoneVerified ? new Date() : null;

  const newUser = await prisma.user.create({
    data: {
      name,
      phone,
      email,
      passwordHash,
      phoneVerifiedAt,
      profile: {
        create: { displayName: name },
      },
    },
    include: { profile: true, subscriptions: true },
  });

  return json({ ok: true, data: userToJson(newUser) });
}
