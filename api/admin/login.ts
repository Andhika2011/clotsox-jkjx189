import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody } from '../_lib/http';
import { signSession, verifySecret } from '../_lib/crypto';
import { rateLimit } from '../_lib/security';

type LoginBody = { email?: string; password?: string };

export default async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res) || !await rateLimit(req, res, 'admin-login', 5, 900)) return;
  const body = parseBody<LoginBody>(req);
  const email = body?.email?.trim().toLowerCase();
  const password = body?.password ?? '';
  const expectedEmail = process.env.ADMIN_BOOTSTRAP_EMAIL?.toLowerCase();
  const passwordHash = process.env.ADMIN_PASSWORD_HASH;
  if (!body || !email || !expectedEmail || !passwordHash || email !== expectedEmail || !await verifySecret(password, passwordHash)) {
    return json(res, 401, { error: 'invalid_credentials' });
  }
  const pending = signSession({ sub: email, scope: 'admin-pending' }, 300);
  res.setHeader('Set-Cookie', `cltx_pending=${pending}; HttpOnly; Secure; SameSite=Strict; Path=/api/admin; Max-Age=300`);
  return json(res, 200, { ok: true, next: 'pin_verification' });
}
