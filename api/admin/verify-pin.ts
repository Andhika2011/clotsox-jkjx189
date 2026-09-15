import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody, webHandler } from '../_lib/http';
import { signSession, verifySecret, verifySession } from '../_lib/crypto';
import { cookieValue, rateLimit } from '../_lib/security';

type PinBody = { pin?: string };

async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res) || !await rateLimit(req, res, 'admin-pin', 5, 900)) return;
  const pending = verifySession(cookieValue(req, 'cltx_pending'), 'admin-pending');
  const body = parseBody<PinBody>(req);
  const pinHash = process.env.ADMIN_2FA_PIN_HASH;
  if (!pending || !pinHash || !/^\d{6}$/.test(body?.pin ?? '') || !await verifySecret(body!.pin!, pinHash)) {
    return json(res, 401, { error: 'verification_failed' });
  }
  const session = signSession({ sub: pending.sub, scope: 'admin' }, 900);
  res.setHeader('Set-Cookie', [
    `cltx_pending=; HttpOnly; Secure; SameSite=Strict; Path=/api/admin; Max-Age=0`,
    `cltx_admin=${session}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=900`,
  ]);
  return json(res, 200, { ok: true, next: '/dashboard' });
}
export default { fetch: (request: Request) => webHandler(request, handler) };
