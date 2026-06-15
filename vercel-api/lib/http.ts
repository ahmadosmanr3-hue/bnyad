const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Accept',
};

export function withCors(init?: ResponseInit) {
  return {
    ...init,
    headers: { ...cors, ...(init?.headers ?? {}) },
  };
}

export function json(data: unknown, status = 200) {
  return Response.json(data, withCors({ status }));
}

export function error(message: string, status = 400) {
  return json({ message }, status);
}

export function options() {
  return new Response(null, withCors({ status: 204 }));
}

export async function readJson<T = Record<string, unknown>>(req: Request): Promise<T> {
  return (await req.json()) as T;
}
