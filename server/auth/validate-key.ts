import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, onlyPost, parseBody, webHandler } from '../_lib/http';
import { sha256, verifySecret } from '../_lib/crypto';
import { tierProfiles, type License } from '../_lib/license';
import { rateLimit } from '../_lib/security';
import { getStore, setStore } from '../_lib/store';

type ValidateBody = { key?: string; deviceHash?: string; appVersion?: string };

// Format: PREFIX-CLTSX-NNN
// PREFIX: huruf besar, angka, underscore, 3–24 karakter
// NNN: tepat 3 digit angka
const KEY_RE = /^([A-Z0-9_]{3,24})-CLTSX-(\d{3})$/;

async function handler(req: RequestLike, res: ResponseLike) {
  if (!onlyPost(req, res) || !await rateLimit(req, res, 'license-validate', 10, 900)) return;
  const body = parseBody<ValidateBody>(req);
  const key = body?.key?.trim().toUpperCase() ?? '';
  const deviceHash = body?.deviceHash?.trim().toLowerCase() ?? '';

  const match = KEY_RE.exec(key);
  if (!match || !/^[a-f0-9]{64}$/.test(deviceHash)) return json(res, 400, { error: 'invalid_request' });

  // ID lisensi = PREFIX-NNN (tanpa -CLTSX-)
  const licenseId = `${match[1]}-${match[2]}`;
  const raw = await getStore(`license:${licenseId}`);
  if (!raw) return json(res, 401, { error: 'license_not_found' });

  const license = JSON.parse(raw) as License;
  const pepper = process.env.LICENSE_PEPPER;
  if (!pepper || !await verifySecret(key, license.secretHash, pepper)) return json(res, 401, { error: 'license_invalid' });

  // Lisensi permanen — hanya cek revokedAt
  if (license.revokedAt) return json(res, 403, { error: 'license_revoked' });
  if (license.deviceHash && license.deviceHash !== deviceHash) return json(res, 403, { error: 'device_not_authorized' });

  // Ikat ke perangkat saat pertama kali digunakan
  if (!license.deviceHash) {
    license.deviceHash = deviceHash;
    await setStore(`license:${licenseId}`, JSON.stringify(license));
  }

  const profile = tierProfiles[license.tier];
  return json(res, 200, {
    license: { id: license.id, tier: license.tier, label: profile.label },
    profile: { modules: profile.modules, description: profile.description, policy: 'device-only; no game modification' },
    receipt: sha256(`${license.id}:${deviceHash}:${license.createdAt}`).slice(0, 24),
  });
}
export default { fetch: (request: Request) => webHandler(request, handler) };
