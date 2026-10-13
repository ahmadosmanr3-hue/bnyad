import { safeRoute } from '@/lib/http';
import { isAdminAuthed } from '@/lib/admin';
import { limitAuth } from '@/lib/security';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/** Verifies the admin secret. The panel stores it and sends it on every call. */
async function handlePOST(req: Request) {
  const limited = await limitAuth(req);
  if (limited) return limited;
  if (!process.env.ADMIN_SECRET) {
    return error('ADMIN_SECRET is not configured on the server.', 503);
  }
  if (!isAdminAuthed(req)) {
    return error('Wrong admin password.', 401);
  }
  return json({ ok: true });
}

export const POST = safeRoute(handlePOST);
