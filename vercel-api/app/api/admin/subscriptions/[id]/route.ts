import { prisma } from '@/lib/db';
import { isAdminAuthed } from '@/lib/admin';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

type Params = { params: Promise<{ id: string }> };

/** Cancels a subscription (sets active = false). */
export async function DELETE(req: Request, { params }: Params) {
  if (!isAdminAuthed(req)) return error('Unauthorized.', 401);

  const { id } = await params;
  const subId = Number(id);
  if (!Number.isInteger(subId)) return error('Invalid id.', 422);

  const sub = await prisma.subscription.findUnique({ where: { id: subId } });
  if (!sub) return error('Subscription not found.', 404);

  await prisma.subscription.update({ where: { id: subId }, data: { active: false } });
  return json({ ok: true });
}
