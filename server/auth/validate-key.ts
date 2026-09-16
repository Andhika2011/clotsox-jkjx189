import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody, webHandler } from '../_lib/http';
import { sha256, verifySecret } from '../_lib/crypto';
import { tierProfiles, type License } from '../_lib/license';
import { rateLimit } from '../_lib/security';
import { getStore, setStore } from '../_lib/store';

type ValidateBody = { key?: string; deviceHash?: string; appVersion?: string };

async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res) || !await rateLimit(req, res, 'license-validate', 10, 900)) return;
  const body = parseBody<ValidateBody>(req);
  const key = body?.key?.trim().toUpperCase() ?? '';
  const deviceHash = body?.deviceHash?.trim().toLowerCase() ?? '';
  const match = /^CLTX-([A-Z0-9_-]{6,16})-([A-Z0-9_-]{16,64})$/.exec(key);
  if (!match || !/^[a-f0-9]{64}$/.test(deviceHash)) return json(res, 400, { error: 'invalid_request' });
  const raw = await getStore(`license:${match[1]}`);
  if (!raw) return json(res, 401, { error: 'license_not_found' });
  const license = JSON.parse(raw) as License;
  const pepper = process.env.LICENSE_PEPPER;
  if (!pepper || !await verifySecret(key, license.secretHash, pepper)) return json(res, 401, { error: 'license_invalid' });
  // Lisensi permanen — hanya cek revokedAt, tidak ada expiry
  if (license.revokedAt) return json(res, 403, { error: 'license_revoked' });
  if (license.deviceHash && license.deviceHash !== deviceHash) return json(res, 403, { error: 'device_not_authorized' });
  // Ikat ke perangkat saat pertama kali digunakan
  if (!license.deviceHash) {
    license.deviceHash = deviceHash;
    await setStore(`license:${license.id}`, JSON.stringify(license));
  }
  const profile = tierProfiles[license.tier];
  return json(res, 200, {
    license: { id: license.id, tier: license.tier, label: profile.label },
    profile: { modules: profile.modules, description: profile.description, policy: 'device-only; no game modification' },
    receipt: sha256(`${license.id}:${deviceHash}:${license.createdAt}`).slice(0, 24),
  });
}
export default { fetch: (request: Request) => webHandler(request, handler) };
