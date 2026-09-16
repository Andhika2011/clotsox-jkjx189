import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody, webHandler } from '../_lib/http';
import { hashSecret } from '../_lib/crypto';
import { isTier, tierProfiles, type License } from '../_lib/license';
import { requireAdmin, rateLimit } from '../_lib/security';
import { getStore, setStore } from '../_lib/store';
import { randomToken } from '../_lib/crypto';

type CreateBody = { tier?: unknown; prefix?: unknown; note?: unknown };

/** Prefix: huruf besar, angka, dan underscore. 3–24 karakter. */
const PREFIX_RE = /^[A-Z0-9_]{3,24}$/;

/** Generate 3 angka random 000–999, zero-padded. */
function randomSuffix(): string {
  return String(Math.floor(Math.random() * 1000)).padStart(3, '0');
}

async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res) || !await rateLimit(req, res, 'key-create', 30, 3600)) return;
  const admin = requireAdmin(req, res);
  if (!admin) return;

  const body = parseBody<CreateBody>(req);
  const note = typeof body?.note === 'string' ? body.note.trim().slice(0, 140) : undefined;
  const rawPrefix = typeof body?.prefix === 'string' ? body.prefix.trim().toUpperCase() : '';

  if (!body || !isTier(body.tier)) {
    return json(res, 400, { error: 'invalid_tier' });
  }
  if (!PREFIX_RE.test(rawPrefix)) {
    return json(res, 400, { error: 'invalid_prefix', detail: 'Prefix harus 3–24 karakter huruf besar, angka, atau underscore.' });
  }

  const pepper = process.env.LICENSE_PEPPER;
  if (!pepper || pepper.length < 48) return json(res, 503, { error: 'server_misconfigured' });

  // Generate suffix unik — coba sampai 10x hindari tabrakan
  let suffix = '';
  let rawKey = '';
  for (let attempt = 0; attempt < 10; attempt++) {
    suffix = randomSuffix();
    rawKey = `${rawPrefix}-CLTSX-${suffix}`;
    const existing = await getStore(`license:${rawPrefix}-${suffix}`);
    if (!existing) break;
  }

  const id = `${rawPrefix}-${suffix}`;
  const now = new Date();
  const license: License = {
    id,
    secretHash: await hashSecret(rawKey, pepper),
    tier: body.tier,
    prefix: rawPrefix,
    createdAt: now.toISOString(),
    note,
  };

  // Lisensi permanen — disimpan tanpa TTL
  await setStore(`license:${id}`, JSON.stringify(license));
  await setStore(
    `audit:${randomToken(12)}`,
    JSON.stringify({ at: now.toISOString(), actor: admin.sub, action: 'license.created', licenseId: id, tier: body.tier }),
    90 * 86_400,
  );

  return json(res, 201, {
    key: rawKey,
    id,
    tier: body.tier,
    tierLabel: tierProfiles[body.tier].label,
    createdAt: now.toISOString(),
    warning: 'Display this key once only; it cannot be recovered.',
  });
}
export default { fetch: (request: Request) => webHandler(request, handler) };
