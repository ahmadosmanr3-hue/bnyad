import type { Subscription } from '@prisma/client';

/**
 * Stock/revenue split between the two owners of the app.
 * Change the shares here if ownership ever changes. They must sum to 1.0.
 */
export const STOCKHOLDERS: { name: string; share: number }[] = [
  { name: 'Nasr', share: 0.6 },
  { name: 'Ahmad', share: 0.4 },
];

/** True when the request carries the correct admin secret. */
export function isAdminAuthed(req: Request): boolean {
  const secret = process.env.ADMIN_SECRET;
  if (!secret) return false;
  const header =
    req.headers.get('x-admin-secret') ??
    req.headers.get('authorization')?.replace(/^Bearer\s+/i, '') ??
    null;
  return !!header && header === secret;
}

/** A subscription counts as active if not flagged off and not expired. */
export function isSubActive(sub: Subscription, now = new Date()): boolean {
  return sub.active && sub.expiresAt.getTime() > now.getTime();
}

/** Whole days remaining (0 when expired). */
export function daysLeft(expiresAt: Date, now = new Date()): number {
  const ms = expiresAt.getTime() - now.getTime();
  if (ms <= 0) return 0;
  return Math.ceil(ms / (1000 * 60 * 60 * 24));
}

/** Splits a revenue amount across the stockholders. */
export function splitRevenue(total: number) {
  return STOCKHOLDERS.map((s) => ({
    name: s.name,
    share: s.share,
    amount: Math.round(total * s.share * 100) / 100,
  }));
}
