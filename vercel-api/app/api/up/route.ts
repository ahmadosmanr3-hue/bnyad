import { safeRoute } from '@/lib/http';
import { json } from '@/lib/http';

export const runtime = 'nodejs';

async function handleGET() {
  return json({ status: 'ok' });
}

export const GET = safeRoute(handleGET);
