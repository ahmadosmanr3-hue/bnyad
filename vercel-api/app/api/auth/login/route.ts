import { prisma } from '@/lib/db';
import { createSession, verifyPassword, userToJson } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Logs a user in with their phone number and password. */
export async function POST(req: Request) {
  let body;
  try {
    body = await readJson<{
      phone?: string;
      password?: string;
      fcmToken?: string;
      fcm_token?: string;
    }>(req);
  } catch {
    return error('Invalid JSON body.', 400);
  }

  const phone = body.phone?.trim();
  const password = body.password ?? '';
  const fcmToken = body.fcmToken?.trim() || body.fcm_token?.trim();

  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }
  if (!password) {
    return error('Password is required.', 422);
  }

  const user = await prisma.user.findUnique({
    where: { phone },
    include: { profile: true, subscriptions: true },
  });

  if (!user) {
    return error('Incorrect phone number or password.', 401);
  }

  const isMatch = await verifyPassword(password, user.passwordHash);
  if (!isMatch) {
    return error('Incorrect phone number or password.', 401);
  }

  if (fcmToken) {
    await prisma.user.update({
      where: { id: user.id },
      data: { fcmToken },
    });
    user.fcmToken = fcmToken;
  }

  const token = await createSession(user.id);
  return json({ token, user: userToJson(user) });
}
