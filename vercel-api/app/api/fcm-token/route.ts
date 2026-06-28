import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Saves the device FCM token so admin push notifications can reach this user. */
export async function POST(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<{ token?: string }>(req);
  const token = body.token?.trim();
  if (!token) return error('token is required.', 422);

  await prisma.user.update({
    where: { id: user.id },
    data: { fcmToken: token },
  });

  return json({ ok: true });
}
