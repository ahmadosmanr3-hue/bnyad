import { RequestError } from './http';

type Subscriber = { subscriber?: { entitlements?: Record<string, { expires_date?: string | null; product_identifier?: string }> } };

/** Server-to-server verification, tied only to the authenticated API user id.
 * Mobile expiration/price/product claims are deliberately not read. */
export async function verifiedStoreEntitlement(userId: number, fetcher: typeof fetch = fetch) {
  const secret = process.env.REVENUECAT_SECRET_API_KEY;
  if (!secret) throw new RequestError('Store verification is not configured. Contact support.', 503);
  const response = await fetcher(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(String(userId))}`, {
    headers: { Authorization: `Bearer ${secret}`, Accept: 'application/json' },
    cache: 'no-store', signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new RequestError('Store verification is temporarily unavailable.', 503);
  const data = await response.json() as Subscriber;
  const entitlement = data.subscriber?.entitlements?.[process.env.REVENUECAT_ENTITLEMENT_ID || 'all_feature'];
  if (!entitlement?.expires_date) throw new RequestError('No active store subscription was verified.', 403);
  const expiresAt = new Date(entitlement.expires_date);
  if (!Number.isFinite(expiresAt.getTime()) || expiresAt <= new Date()) throw new RequestError('No active store subscription was verified.', 403);
  return { expiresAt, product: entitlement.product_identifier ?? 'store' };
}
