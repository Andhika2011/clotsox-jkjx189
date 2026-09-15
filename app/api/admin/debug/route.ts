import { verifySecret } from '../../../../server/_lib/crypto';

// ENDPOINT DEBUG SEMENTARA — HAPUS SETELAH MASALAH TERSELESAIKAN
// Tidak menampilkan nilai env var, hanya status dan panjangnya.
export async function POST(request: Request) {
  const body = await request.json().catch(() => ({})) as Record<string, string>;
  const { password = '' } = body;

  const emailEnv = process.env.ADMIN_BOOTSTRAP_EMAIL;
  const hashEnv = process.env.ADMIN_PASSWORD_HASH;
  const sessionSecret = process.env.SESSION_HMAC_SECRET;

  const hashMatch = hashEnv ? await verifySecret(password, hashEnv) : false;
  const hashFormat = hashEnv
    ? { starts: hashEnv.slice(0, 7), length: hashEnv.length, segments: hashEnv.split('$').length }
    : null;

  return Response.json({
    env: {
      ADMIN_BOOTSTRAP_EMAIL: emailEnv ? `set (${emailEnv.length} chars, ends: ...${emailEnv.slice(-6)})` : 'MISSING',
      ADMIN_PASSWORD_HASH: hashEnv ? `set (${hashEnv.length} chars)` : 'MISSING',
      SESSION_HMAC_SECRET: sessionSecret ? `set (${sessionSecret.length} chars)` : 'MISSING',
    },
    hash: hashFormat,
    passwordMatch: hashMatch,
    passwordLength: password.length,
  }, { headers: { 'Cache-Control': 'no-store' } });
}
