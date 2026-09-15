import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody, webHandler } from '../_lib/http';
import { hashSecret, randomToken } from '../_lib/crypto';
import { isTier, tierProfiles, type License } from '../_lib/license';
import { requireAdmin, rateLimit } from '../_lib/security';
import { setStore } from '../_lib/store';

type CreateBody = { tier?: unknown; durationDays?: unknown; note?: unknown };

async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res) || !await rateLimit(req, res, 'key-create', 30, 3600)) return;
  const admin = requireAdmin(req, res);
  if (!admin) return;
  const body = parseBody<CreateBody>(req);
  const durationDays = typeof body?.durationDays === 'number' ? body.durationDays : 0;
  const note = typeof body?.note === 'string' ? body.note.trim().slice(0, 140) : undefined;
  if (!body || !isTier(body.tier) || !Number.isInteger(durationDays) || durationDays < 1 || durationDays > 730) {
    return json(res, 400, { error: 'invalid_tier_or_duration' });
  }
  const pepper = process.env.LICENSE_PEPPER;
  if (!pepper || pepper.length < 48) return json(res, 503, { error: 'server_misconfigured' });
  const id = randomToken(6).toUpperCase();
  const secret = randomToken(18).toUpperCase();
  const rawKey = `CLTX-${id}-${secret}`;
  const now = new Date();
  const license: License = {
    id, secretHash: await hashSecret(rawKey, pepper), tier: body.tier, durationDays,
    createdAt: now.toISOString(), expiresAt: new Date(now.getTime() + durationDays * 86_400_000).toISOString(), note,
  };
  await setStore(`license:${id}`, JSON.stringify(license), durationDays * 86_400);
  await setStore(`audit:${randomToken(12)}`, JSON.stringify({ at: now.toISOString(), actor: admin.sub, action: 'license.created', licenseId: id, tier: body.tier }), 90 * 86_400);
  return json(res, 201, { key: rawKey, id, tier: body.tier, tierLabel: tierProfiles[body.tier].label, expiresAt: license.expiresAt, warning: 'Display this key once only; it cannot be recovered.' });
}
export default { fetch: (request: Request) => webHandler(request, handler) };
