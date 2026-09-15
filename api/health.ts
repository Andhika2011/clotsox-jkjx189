import type { RequestLike, ResponseLike } from './_lib/http';
import { json, webHandler } from './_lib/http';
import { getStore } from './_lib/store';

/** Minimal public liveness/readiness probe. It exposes no license or admin data. */
async function handler(req: RequestLike, res: ResponseLike) {
  if (req.method !== 'GET') return json(res, 405, { error: 'method_not_allowed' });
  try {
    await getStore('health:probe');
    return json(res, 200, { ok: true, service: 'clotso-x-api' });
  } catch {
    return json(res, 503, { ok: false, service: 'clotso-x-api' });
  }
}
export default { fetch: (request: Request) => webHandler(request, handler) };
