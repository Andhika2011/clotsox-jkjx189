type Stored = { value: string; expiresAt?: number };
const memory = new Map<string, Stored>();

function supabaseUrl() { return process.env.SUPABASE_URL; }
function supabaseKey() { return process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY; }
function canUseSupabase() { return Boolean(supabaseUrl() && supabaseKey()); }
function ensureStorage() { if (process.env.VERCEL_ENV === 'production' && !canUseSupabase()) throw new Error('persistent_storage_required'); }
function headers(extra: Record<string, string> = {}) { return { apikey: supabaseKey()!, Authorization: `Bearer ${supabaseKey()}`, 'Content-Type': 'application/json', ...extra }; }
async function request(path: string, init: RequestInit = {}) {
  const response = await fetch(`${supabaseUrl()}/rest/v1/${path}`, { ...init, headers: headers(init.headers as Record<string, string> | undefined) });
  if (!response.ok) throw new Error('supabase_unavailable');
  return response;
}
export async function getStore(key: string) {
  ensureStorage();
  if (canUseSupabase()) {
    const response = await request(`cltx_kv_store?select=value,expires_at&key=eq.${encodeURIComponent(key)}&limit=1`);
    const rows = await response.json() as Array<{ value: string; expires_at: string | null }>;
    const row = rows[0];
    if (!row || (row.expires_at && Date.parse(row.expires_at) < Date.now())) return null;
    return row.value;
  }
  const record = memory.get(key);
  if (!record || (record.expiresAt && record.expiresAt < Date.now())) { memory.delete(key); return null; }
  return record.value;
}
export async function setStore(key: string, value: string, ttlSeconds?: number) {
  ensureStorage();
  if (canUseSupabase()) {
    await request('cltx_kv_store', { method: 'POST', headers: { Prefer: 'resolution=merge-duplicates,return=minimal' }, body: JSON.stringify({ key, value, expires_at: ttlSeconds ? new Date(Date.now() + ttlSeconds * 1000).toISOString() : null }) });
    return;
  }
  memory.set(key, { value, expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined });
}
export async function incrementStore(key: string, ttlSeconds: number) {
  ensureStorage();
  if (canUseSupabase()) {
    const response = await request('rpc/cltx_increment_rate_limit', { method: 'POST', body: JSON.stringify({ p_key: key, p_window_seconds: ttlSeconds }) });
    return Number(await response.json());
  }
  const count = Number(await getStore(key) ?? '0') + 1;
  await setStore(key, String(count), ttlSeconds);
  return count;
}
