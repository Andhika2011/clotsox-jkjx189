type Stored = { value: string; expiresAt?: number };
const memory = new Map<string, Stored>();

function redisUrl() { return process.env.UPSTASH_REDIS_REST_URL ?? process.env.KV_REST_API_URL; }
function redisToken() { return process.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.KV_REST_API_TOKEN; }
function canUseKv() { return Boolean(redisUrl() && redisToken()); }
function ensureStorage() {
  if (process.env.VERCEL_ENV === 'production' && !canUseKv()) throw new Error('persistent_storage_required');
}

async function kv(command: unknown[]) {
  const url = redisUrl()!;
  const response = await fetch(url, {
    method: 'POST', headers: { Authorization: `Bearer ${redisToken()}`, 'Content-Type': 'application/json' }, body: JSON.stringify(command),
  });
  if (!response.ok) throw new Error('kv_unavailable');
  return (await response.json()) as { result: string | null };
}

export async function getStore(key: string) {
  ensureStorage();
  if (canUseKv()) return (await kv(['GET', key])).result;
  const record = memory.get(key);
  if (!record || (record.expiresAt && record.expiresAt < Date.now())) { memory.delete(key); return null; }
  return record.value;
}

export async function setStore(key: string, value: string, ttlSeconds?: number) {
  ensureStorage();
  if (canUseKv()) { await kv(ttlSeconds ? ['SET', key, value, 'EX', ttlSeconds] : ['SET', key, value]); return; }
  memory.set(key, { value, expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined });
}

export async function incrementStore(key: string, ttlSeconds: number) {
  ensureStorage();
  if (canUseKv()) {
    const count = Number((await kv(['INCR', key])).result ?? 0);
    if (count === 1) await kv(['EXPIRE', key, ttlSeconds]);
    return count;
  }
  const count = Number(await getStore(key) ?? '0') + 1;
  await setStore(key, String(count), ttlSeconds);
  return count;
}
