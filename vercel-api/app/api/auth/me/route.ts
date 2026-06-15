import { userFromAuthHeader, userToJson } from '@/lib/auth';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function GET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);
  return json({ data: userToJson(user) });
}
