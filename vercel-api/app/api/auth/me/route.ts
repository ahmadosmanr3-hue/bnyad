import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { userFromAuthHeader, userToJson } from '@/lib/auth';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

async function handleGET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);
  return json({ data: userToJson(user) });
}

async function handleDELETE(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  await prisma.user.delete({ where: { id: user.id } });

  return json({
    ok: true,
    message: 'Account and associated data deleted successfully.',
  });
}


export const GET = safeRoute(handleGET);
export const DELETE = safeRoute(handleDELETE);

