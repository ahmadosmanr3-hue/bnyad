const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept, Accept-Language, X-Admin-Secret, X-Setup-Secret',
};

export function withCors(init?: ResponseInit) {
  return {
    ...init,
    headers: { ...cors, ...(init?.headers ?? {}) },
  };
}

export function json(data: unknown, status = 200) {
  return Response.json(data, withCors({ status, headers: { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' } }));
}

export function error(message: string, status = 400) {
  return json({ message }, status);
}

export function options() {
  return new Response(null, withCors({ status: 204 }));
}

export async function readJson<T = Record<string, unknown>>(req: Request): Promise<T> {
  const raw = await req.text();
  if (raw.length > 256_000) throw new RequestError('Request body is too large.', 413);
  try {
    const value = JSON.parse(raw);
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error();
    return value as T;
  } catch {
    throw new RequestError('Invalid JSON body.', 400);
  }
}

export class RequestError extends Error {
  constructor(message: string, public status = 422) { super(message); }
}

export function safeRoute<T extends unknown[]>(handler: (...args: T) => Promise<Response>) {
  return async (...args: T): Promise<Response> => {
    try { return await handler(...args); }
    catch (e) {
      if (e instanceof RequestError) return error(e.message, e.status);
      // Never expose Prisma queries, database URLs, credentials or stack traces.
      console.error('API request failed', e instanceof Error ? e.name : 'UnknownError');
      return error('Service temporarily unavailable. Please try again.', 503);
    }
  };
}
