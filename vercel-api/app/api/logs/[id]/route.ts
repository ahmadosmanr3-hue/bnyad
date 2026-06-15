import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const { id } = await params;
  const logId = Number(id);
  const log = await prisma.dailyLog.findUnique({ where: { id: logId } });
  if (!log || log.userId !== user.id) return error('Not found.', 404);

  await prisma.dailyLog.delete({ where: { id: logId } });
  return json({ message: 'Deleted.' });
}
