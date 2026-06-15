import { prisma } from '@/lib/db';
import { parseDate, todayDate, userFromAuthHeader } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function GET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const { searchParams } = new URL(req.url);
  const date = searchParams.get('date') ?? todayDate();

  const log = await prisma.waterLog.upsert({
    where: {
      userId_logDate: { userId: user.id, logDate: parseDate(date) },
    },
    create: { userId: user.id, logDate: parseDate(date), glasses: 0 },
    update: {},
  });

  return json({
    data: {
      id: log.id,
      log_date: log.logDate.toISOString().slice(0, 10),
      glasses: log.glasses,
    },
  });
}

export async function PUT(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<{ log_date?: string; glasses?: number }>(req);
  const date = body.log_date ?? todayDate();
  const glasses = Number(body.glasses ?? 0);

  const log = await prisma.waterLog.upsert({
    where: {
      userId_logDate: { userId: user.id, logDate: parseDate(date) },
    },
    create: { userId: user.id, logDate: parseDate(date), glasses },
    update: { glasses },
  });

  return json({
    data: {
      id: log.id,
      log_date: log.logDate.toISOString().slice(0, 10),
      glasses: log.glasses,
    },
  });
}
