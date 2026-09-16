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

  const response = await fetch(
    `${url}/rest/v1/cltx_kv_store?select=key,value&key=like.license%3A*&order=key.asc&limit=200`,
    { headers: { apikey: key, Authorization: `Bearer ${key}` } },
  );
  if (!response.ok) return json(res, 502, { error: 'storage_unavailable' });

  const rows = await response.json() as Array<{ key: string; value: string }>;
  const licenses = rows.map(row => {
    try {
      const data = JSON.parse(row.value) as {
        id: string; tier: string; createdAt: string;
        revokedAt?: string; deviceHash?: string; note?: string;
      };
      return {
        id: data.id,
        tier: data.tier,
        createdAt: data.createdAt,
        revokedAt: data.revokedAt ?? null,
        bound: Boolean(data.deviceHash),
        note: data.note ?? null,
        status: data.revokedAt ? 'revoked' : 'active',
      };
    } catch { return null; }
  }).filter(Boolean);

  return json(res, 200, { licenses });
}

export default { fetch: (request: Request) => webHandler(request, handler) };
