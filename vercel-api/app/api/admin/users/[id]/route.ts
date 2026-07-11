import { prisma } from '@/lib/db';
import { daysLeft, isAdminAuthed } from '@/lib/admin';
import { mapProfileUpdate, profileToJson, hashPassword } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

type Params = { params: Promise<{ id: string }> };

async function getUserId(params: Params['params']) {
  const { id } = await params;
  const userId = Number(id);
  return Number.isInteger(userId) ? userId : null;
}

/** Full detail for one user (login info + profile + subscriptions). */
export async function GET(req: Request, { params }: Params) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const userId = await getUserId(params);
  if (userId === null) return error('Invalid id.', 422);

  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      profile: true,
      subscriptions: { orderBy: { expiresAt: 'desc' } },
    },
  });
  if (!user) return error('User not found.', 404);

  const now = new Date();
  const active = user.subscriptions.find(
    (s) => s.active && s.expiresAt.getTime() > now.getTime(),
  );

  return json({
    data: {
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      phoneVerified: !!user.phoneVerifiedAt,
      createdAt: user.createdAt,
      isPremium: !!active,
      plan: active?.plan ?? null,
      daysLeft: active ? daysLeft(active.expiresAt, now) : 0,
      expiresAt: active?.expiresAt ?? null,
      profile: user.profile ? profileToJson(user.profile) : null,
    },
  });
}

/**
 * Edits a user. Body may include top-level user fields (name, phone, email)
 * and/or any profile fields (display_name, daily_calories, daily_protein,
 * daily_carbs, daily_fat, goal, weight, height, age, gender, ...).
 */
export async function PATCH(req: Request, { params }: Params) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const userId = await getUserId(params);
  if (userId === null) return error('Invalid id.', 422);

  const exists = await prisma.user.findUnique({ where: { id: userId } });
  if (!exists) return error('User not found.', 404);

  const body = await readJson<Record<string, unknown>>(req);

  // Separate user-table fields from profile fields.
  const userData: Record<string, unknown> = {};
  const profileBody: Record<string, unknown> = {};
  let newPassword = '';

  for (const [key, value] of Object.entries(body)) {
    if (key === 'name' || key === 'phone' || key === 'email') {
      userData[key] = typeof value === 'string' ? value.trim() : value;
    } else if (key === 'password') {
      if (typeof value === 'string') {
        newPassword = value.trim();
      }
    } else {
      profileBody[key] = value;
    }
  }

  if (newPassword) {
    if (newPassword.length < 6) {
      return error('Password must be at least 6 characters.', 422);
    }
    userData.passwordHash = await hashPassword(newPassword);
  }

  // Validate phone/email uniqueness if changed.
  if (typeof userData.phone === 'string' && userData.phone) {
    const clash = await prisma.user.findFirst({
      where: { phone: userData.phone as string, id: { not: userId } },
    });
    if (clash) return error('Another user already uses that phone.', 409);
  }
  if (typeof userData.email === 'string' && userData.email) {
    const clash = await prisma.user.findFirst({
      where: { email: userData.email as string, id: { not: userId } },
    });
    if (clash) return error('Another user already uses that email.', 409);
  }

  if (Object.keys(userData).length > 0) {
    await prisma.user.update({ where: { id: userId }, data: userData });
  }

  if (Object.keys(profileBody).length > 0) {
    const profileData = mapProfileUpdate(profileBody);
    await prisma.userProfile.upsert({
      where: { userId },
      create: { userId, ...profileData },
      update: profileData,
    });
  }

  const updated = await prisma.user.findUnique({
    where: { id: userId },
    include: { profile: true },
  });

  return json({
    ok: true,
    data: {
      id: updated!.id,
      name: updated!.name,
      phone: updated!.phone,
      email: updated!.email,
      profile: updated!.profile ? profileToJson(updated!.profile) : null,
    },
  });
}

/** Permanently deletes a user and all their data. */
export async function DELETE(req: Request, { params }: Params) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const userId = await getUserId(params);
  if (userId === null) return error('Invalid id.', 422);

  const exists = await prisma.user.findUnique({ where: { id: userId } });
  if (!exists) return error('User not found.', 404);

  // Cascades remove profile, logs, water, weights, meal plan, subs, tokens.
  await prisma.user.delete({ where: { id: userId } });

  return json({ ok: true });
}
