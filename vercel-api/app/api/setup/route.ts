import { seedFoods } from '@/lib/seedFoods';
import { error, json, options } from '@/lib/http';

export const runtime = 'nodejs';
export const maxDuration = 300;

export function OPTIONS() {
  return options();
}

/** One-time food seed. Header: X-Setup-Secret: YOUR_SETUP_SECRET */
export async function POST(req: Request) {
  const secret = process.env.SETUP_SECRET;
  if (!secret) {
    return error('SETUP_SECRET env var is not configured.', 503);
  }
  if (req.headers.get('x-setup-secret') !== secret) {
    return error('Forbidden.', 403);
  }

  try {
    const result = await seedFoods();
    return json({ ok: true, ...result });
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Seed failed';
    return error(msg, 500);
  }
}
