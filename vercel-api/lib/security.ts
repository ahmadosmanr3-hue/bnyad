import crypto from 'node:crypto';
import { prisma } from './db';
import { json } from './http';

export function tokenDigest(token: string): string {
  return `sha256:${crypto.createHash('sha256').update(token).digest('hex')}`;
}

export function constantTimeEqual(a: string, b: string): boolean {
  const first = crypto.createHash('sha256').update(a).digest();
  const second = crypto.createHash('sha256').update(b).digest();
  return crypto.timingSafeEqual(first, second);
}

// Database-backed fixed windows work across serverless instances. No raw
// phone numbers/IP addresses are stored. Migration is explicitly manual.
export async function limitAuth(req: Request, subject = ''): Promise<Response | null> {
  const ip = process.env.VERCEL
    ? req.headers.get('x-vercel-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'
    : 'local';
  const path = new URL(req.url).pathname;
  const windowSeconds = 600;
  const bucket = Math.floor(Date.now() / (windowSeconds * 1000));
  for (const [kind, identity, max] of [
    ['ip', ip, 60], ['subject', subject || ip, path.endsWith('request-otp') ? 5 : 15],
  ] as const) {
    const key = crypto.createHash('sha256').update(`${path}:${kind}:${identity}`).digest('hex');
    try {
      const rows = await prisma.$queryRaw<{ count: number }[]>`
        INSERT INTO auth_rate_limits (key, bucket, count)
        VALUES (${key}, ${bucket}, 1)
        ON CONFLICT (key) DO UPDATE SET
          count = CASE WHEN auth_rate_limits.bucket = EXCLUDED.bucket
                       THEN LEAST(auth_rate_limits.count + 1, 10000) ELSE 1 END,
          bucket = EXCLUDED.bucket
        RETURNING count`;
      if (rows[0].count > max) {
        const retry = windowSeconds - Math.floor(Date.now() / 1000) % windowSeconds;
        const response = json({ message: 'Too many attempts. Please try again later.', code: 'rate_limited' }, 429);
        response.headers.set('Retry-After', String(retry));
        return response;
      }
    } catch {
      // Fail closed if the required security migration was not applied.
      return json({ message: 'Sign-in is temporarily unavailable.', code: 'auth_unavailable' }, 503);
    }
  }
  return null;
}
