import { safeRoute } from '@/lib/http';
import { localizedNotification, parseNotificationTranslations } from '@/lib/notification-localization';
import { prisma } from '@/lib/db';
import { isAdminAuthed } from '@/lib/admin';
import { sendPush, type PushResult } from '@/lib/fcm';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Lists recently sent notifications. */
async function handleGET(req: Request) {
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
    translations: n.translations,
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
async function handlePOST(req: Request) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const body = await readJson<{
    title?: string;
    body?: string;
    translations?: unknown;
    userId?: number;
    phone?: string;
  }>(req);

  const translations = parseNotificationTranslations(body.translations);
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
    data: { title, body: message, userId, ...(translations ? { translations } : {}) },
  });

  let push: PushResult = { sent: false };

  if (userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, profile: { select: { language: true } } },
    });
    if (user?.fcmToken) {
      const localized = localizedNotification(note, user.profile?.language);
      push = await sendPush({ token: user.fcmToken }, localized.title, localized.body);
    } else {
      push = { sent: false, error: 'User has no FCM token yet (app not opened since update).' };
    }
  } else {
    // Find all unique FCM tokens in the database
    const users = await prisma.user.findMany({
      where: { fcmToken: { not: null } },
      select: { fcmToken: true, profile: { select: { language: true } } },
    });
    const tokens = Array.from(new Set(users.map((u) => u.fcmToken as string).filter(Boolean)));

    if (tokens.length > 0) {
      const results = await Promise.all(
        tokens.map((token) => {
          const text = localizedNotification(note, users.find(u => u.fcmToken === token)?.profile?.language);
          return sendPush({ token }, text.title, text.body);
        })
      );
      const failed = results.filter((r) => !r.sent);
      if (failed.length === 0) {
        push = { sent: true };
      } else {
        push = {
          sent: failed.length < tokens.length,
          error: `Failed to send to ${failed.length} of ${tokens.length} devices.`,
        };
      }
    } else {
      push = { sent: false, error: 'No registered devices with FCM tokens found.' };
    }
  }

  return json({ ok: true, notification: note, push }, 201);
}

export const GET = safeRoute(handleGET);
export const POST = safeRoute(handlePOST);
