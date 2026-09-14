export type RequestLike = { method?: string; headers: Record<string, string | string[] | undefined>; body?: unknown };
export type ResponseLike = {
  status: (code: number) => ResponseLike;
  json: (body: unknown) => void;
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
