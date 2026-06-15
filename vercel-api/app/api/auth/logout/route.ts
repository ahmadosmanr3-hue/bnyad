import { prisma } from '@/lib/db';
import { userFromAuthHeader } from '@/lib/auth';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function POST(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const auth = req.headers.get('authorization');
  const token = auth?.slice(7).trim();
  if (token) {
    await prisma.apiToken.deleteMany({ where: { token } });
  }

  return json({ message: 'Logged out.' });
}
