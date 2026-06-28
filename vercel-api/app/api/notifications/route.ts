import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/**
 * Notifications for the current user: their own + broadcasts.
 * Optional ?since=<ISO date> to fetch only newer ones (for polling).
 */
export async function GET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const url = new URL(req.url);
  const since = url.searchParams.get('since');
  const sinceDate = since ? new Date(since) : null;

  const notes = await prisma.notification.findMany({
    where: {
      OR: [{ userId: user.id }, { userId: null }],
      ...(sinceDate && !isNaN(sinceDate.getTime()) ? { createdAt: { gt: sinceDate } } : {}),
    },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });

  return json({
    data: notes.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      createdAt: n.createdAt,
    })),
  });
}
