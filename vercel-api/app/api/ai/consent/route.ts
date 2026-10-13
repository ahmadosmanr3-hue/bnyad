import { userFromAuthHeader } from '@/lib/auth';
import { consent, setConsent } from '@/lib/ai/store';
import { CONSENT_VERSION } from '@/lib/ai/contract';
import { error, json, options, readJson, safeRoute } from '@/lib/http';
export const runtime = 'nodejs';
export const OPTIONS = options;
export const GET = safeRoute(async (req: Request) => {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.',401);
  return json(await consent(user.id));
});
export const PUT = safeRoute(async (req: Request) => {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.',401);
  const body = await readJson<{ enabled: boolean; version: string }>(req);
  if (typeof body.enabled !== 'boolean' || body.version !== CONSENT_VERSION) return error('Review the current AI consent notice.',422);
  await setConsent(user.id, body.enabled);
  return json({ enabled: body.enabled, version: CONSENT_VERSION });
});
