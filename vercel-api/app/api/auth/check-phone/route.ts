import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { limitAuth } from '@/lib/security';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

async function handlePOST(req: Request) {
  const body = await readJson<{ phone?: string }>(req);
  const phone = body.phone?.trim();
  const limited = await limitAuth(req, phone);
  if (limited) return limited;
  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }

  const user = await prisma.user.findUnique({ where: { phone } });
  return json({ registered: !!user });
}

export const POST = safeRoute(handlePOST);
