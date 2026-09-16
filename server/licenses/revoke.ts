import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody, webHandler } from '../_lib/http';
import { requireAdmin } from '../_lib/security';
import { getStore, setStore } from '../_lib/store';
import { randomToken } from '../_lib/crypto';
import type { License } from '../_lib/license';

type RevokeBody = { id?: string };

async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res)) return;
  const admin = requireAdmin(req, res);
  if (!admin) return;

  const body = parseBody<RevokeBody>(req);
  const id = body?.id?.trim().toUpperCase();
  if (!id) return json(res, 400, { error: 'missing_id' });

  const raw = await getStore(`license:${id}`);
  if (!raw) return json(res, 404, { error: 'license_not_found' });

  const license = JSON.parse(raw) as License;
  if (license.revokedAt) return json(res, 409, { error: 'already_revoked' });

  license.revokedAt = new Date().toISOString();
  // Simpan tanpa TTL — lisensi yang direvoke tetap tersimpan sebagai catatan
  await setStore(`license:${id}`, JSON.stringify(license));

  await setStore(
    `audit:${randomToken(12)}`,
    JSON.stringify({ at: license.revokedAt, actor: admin.sub, action: 'license.revoked', licenseId: id }),
    90 * 86_400,
  );

  return json(res, 200, { ok: true, id, revokedAt: license.revokedAt });
}

export default { fetch: (request: Request) => webHandler(request, handler) };
