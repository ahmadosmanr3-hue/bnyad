import { prisma } from '@/lib/db';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function POST(req: Request) {
  const body = await readJson<{ phone?: string }>(req);
  const phone = body.phone?.trim();
  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }

  const user = await prisma.user.findUnique({ where: { phone } });
  return json({ registered: !!user });
}
