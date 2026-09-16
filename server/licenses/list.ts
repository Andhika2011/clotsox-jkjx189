import type { RequestLike, ResponseLike } from '../_lib/http';
import { json, webHandler } from '../_lib/http';
import { requireAdmin } from '../_lib/security';

function supabaseUrl() { return process.env.SUPABASE_URL; }
function supabaseKey() { return process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY; }

async function handler(req: RequestLike, res: ResponseLike) {
  if (req.method !== 'GET') return json(res, 405, { error: 'method_not_allowed' });
  const admin = requireAdmin(req, res);
  if (!admin) return;

  const url = supabaseUrl();
  const key = supabaseKey();
  if (!url || !key) return json(res, 503, { error: 'storage_not_configured' });

  // Ambil semua lisensi dari Supabase KV store (key prefix "license:")
  const response = await fetch(
    `${url}/rest/v1/cltx_kv_store?select=key,value,expires_at&key=like.license%3A*&order=key.asc&limit=200`,
    { headers: { apikey: key, Authorization: `Bearer ${key}` } },
  );
  if (!response.ok) return json(res, 502, { error: 'storage_unavailable' });

  const rows = await response.json() as Array<{ key: string; value: string; expires_at: string | null }>;
  const licenses = rows.map(row => {
    try {
      const data = JSON.parse(row.value) as {
        id: string; tier: string; createdAt: string; expiresAt: string;
        revokedAt?: string; deviceHash?: string; note?: string; durationDays: number;
      };
      return {
        id: data.id,
        tier: data.tier,
        durationDays: data.durationDays,
        createdAt: data.createdAt,
        expiresAt: data.expiresAt,
        revokedAt: data.revokedAt ?? null,
        bound: Boolean(data.deviceHash),
        note: data.note ?? null,
        status: data.revokedAt ? 'revoked' : Date.parse(data.expiresAt) < Date.now() ? 'expired' : 'active',
      };
    } catch { return null; }
  }).filter(Boolean);

  return json(res, 200, { licenses });
}

export default { fetch: (request: Request) => webHandler(request, handler) };
