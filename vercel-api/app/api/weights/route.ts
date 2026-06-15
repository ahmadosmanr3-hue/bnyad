import { prisma } from '@/lib/db';
import { parseDate, todayDate, userFromAuthHeader } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function POST(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<{ weight?: number; log_date?: string }>(req);
  const weight = Number(body.weight);
  if (!weight || weight <= 0) return error('Weight is required.', 422);

  const logDate = parseDate(body.log_date ?? todayDate());
  const entry = await prisma.weightEntry.upsert({
    where: { userId_logDate: { userId: user.id, logDate } },
    create: { userId: user.id, logDate, weight },
    update: { weight },
  });

  return json({
    data: {
      id: entry.id,
      log_date: entry.logDate.toISOString().slice(0, 10),
      weight: entry.weight,
    },
  });
}
