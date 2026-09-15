import type { RequestLike, ResponseLike } from './http';
import { clientIp, json } from './http';
import { incrementStore } from './store';
import { verifySession } from './crypto';

export async function rateLimit(req: RequestLike, res: ResponseLike, bucket: string, maximum: number, windowSeconds = 300) {
  const count = await incrementStore(`rate:${bucket}:${clientIp(req)}`, windowSeconds);
  if (count <= maximum) return true;
  res.setHeader('Retry-After', String(windowSeconds));
  json(res, 429, { error: 'too_many_requests' });
  return false;
}

export function cookieValue(req: RequestLike, name: string) {
  const raw = req.headers.cookie ?? '';
  const cookie = Array.isArray(raw) ? raw.join(';') : raw;
  return cookie.split(';').map(item => item.trim()).find(item => item.startsWith(`${name}=`))?.slice(name.length + 1);
}

export function requireAdmin(req: RequestLike, res: ResponseLike) {
  const session = verifySession(cookieValue(req, 'cltx_admin'), 'admin');
  if (session) return session;
  json(res, 401, { error: 'admin_session_required' });
  return null;
}
