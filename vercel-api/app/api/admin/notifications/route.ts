import { prisma } from '@/lib/db';
import { isAdminAuthed } from '@/lib/admin';
import { ALL_USERS_TOPIC, sendPush, type PushResult } from '@/lib/fcm';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Lists recently sent notifications. */
export async function GET(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const notes = await prisma.notification.findMany({
    orderBy: { createdAt: 'desc' },
    take: 200,
    include: { user: { select: { name: true, phone: true, profile: { select: { displayName: true } } } } },
  });

  const data = notes.map((n) => ({
    id: n.id,
    title: n.title,
    body: n.body,
    target: n.userId ? (n.user?.profile?.displayName || n.user?.name || n.user?.phone || `#${n.userId}`) : 'All users',
    userId: n.userId,
    createdAt: n.createdAt,
  }));

  return json({ data, count: data.length });
}

/**
 * Sends a notification. Body:
 * { title, body, userId? | phone? }  — omit target to broadcast to everyone.
 */
export async function POST(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const body = await readJson<{
    title?: string;
    body?: string;
    userId?: number;
    phone?: string;
  }>(req);

  const title = body.title?.trim();
  const message = body.body?.trim();
  if (!title) return error('Title is required.', 422);
  if (!message) return error('Message is required.', 422);

  let userId: number | null = body.userId ?? null;
  if (!userId && body.phone) {
    const user = await prisma.user.findUnique({ where: { phone: body.phone.trim() } });
    if (!user) return error('No user found with that phone number.', 404);
    userId = user.id;
  }

  const note = await prisma.notification.create({
    data: { title, body: message, userId },
  });

  let push: PushResult = { sent: false };

  if (userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    if (user?.fcmToken) {
      push = await sendPush({ token: user.fcmToken }, title, message);
    } else {
      push = { sent: false, error: 'User has no FCM token yet (app not opened since update).' };
    }
  } else {
    push = await sendPush({ topic: ALL_USERS_TOPIC }, title, message);
  }

  return json({ ok: true, notification: note, push }, 201);
}
