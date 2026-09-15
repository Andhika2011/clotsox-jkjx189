export type RequestLike = { method?: string; headers: Record<string, string | string[] | undefined>; body?: unknown };
export type ResponseLike = {
  status: (code: number) => ResponseLike;
  json: (body: unknown) => Response;
  setHeader: (name: string, value: string | string[]) => void;
};

export function json(res: ResponseLike, status: number, body: unknown) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  return res.status(status).json(body);
}

export function onlyPost(req: RequestLike, res: ResponseLike): boolean {
  if (req.method === 'POST') return true;
  json(res, 405, { error: 'method_not_allowed' });
  return false;
}

export function parseBody<T>(req: RequestLike): T | null {
  if (typeof req.body === 'string') {
    try { return JSON.parse(req.body) as T; } catch { return null; }
  }
  return req.body && typeof req.body === 'object' ? req.body as T : null;
}

export function clientIp(req: RequestLike) {
  const forwarded = req.headers['x-forwarded-for'];
  return (Array.isArray(forwarded) ? forwarded[0] : forwarded)?.split(',')[0]?.trim() ?? 'unknown';
}

/** Adapt the legacy handler shape to Vercel's web Request/Response Function runtime. */
export async function webHandler(request: Request, handler: (req: RequestLike, res: ResponseLike) => unknown | Promise<unknown>) {
  let body: unknown;
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    try { body = await request.json(); } catch { body = undefined; }
  }
  const req: RequestLike = { method: request.method, headers: Object.fromEntries(request.headers.entries()), body };
  let statusCode = 200;
  const responseHeaders = new Headers();
  const res: ResponseLike = {
    status(code) { statusCode = code; return res; },
    setHeader(name, value) { if (Array.isArray(value)) value.forEach(item => responseHeaders.append(name, item)); else responseHeaders.set(name, value); },
    json(payload) { responseHeaders.set('Content-Type', 'application/json; charset=utf-8'); responseHeaders.set('Cache-Control', 'no-store'); return new Response(JSON.stringify(payload), { status: statusCode, headers: responseHeaders }); },
  };
  try {
    const result = await handler(req, res);
    if (result instanceof Response) return result;
    return new Response(null, { status: statusCode, headers: responseHeaders });
  } catch {
    return new Response(JSON.stringify({ error: 'internal_server_error' }), { status: 500, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' } });
  }
}
