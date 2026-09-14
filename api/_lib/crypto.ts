import { createHash, createHmac, randomBytes, scrypt as scryptCallback, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCallback);
const b64url = (value: Buffer | string) => Buffer.from(value).toString('base64url');

export function sha256(value: string) { return createHash('sha256').update(value).digest('hex'); }
export function randomToken(bytes = 32) { return randomBytes(bytes).toString('base64url'); }

export async function hashSecret(value: string, pepper: string) {
  const salt = randomBytes(16).toString('hex');
  const derived = await scrypt(`${value}:${pepper}`, salt, 64) as Buffer;
  return `scrypt$${salt}$${derived.toString('hex')}`;
}

export async function verifySecret(value: string, encoded: string, pepper = '') {
  const [scheme, salt, expected] = encoded.split('$');
  if (scheme !== 'scrypt' || !salt || !expected) return false;
  const actual = await scrypt(`${value}:${pepper}`, salt, 64) as Buffer;
  const expectedBuffer = Buffer.from(expected, 'hex');
  return expectedBuffer.length === actual.length && timingSafeEqual(expectedBuffer, actual);
}

type Claims = { sub: string; scope: 'admin-pending' | 'admin'; exp: number; nonce: string };

export function signSession(claims: Omit<Claims, 'exp' | 'nonce'>, ttlSeconds: number) {
  const secret = process.env.SESSION_HMAC_SECRET;
  if (!secret || secret.length < 48) throw new Error('server_misconfigured');
  const payload: Claims = { ...claims, exp: Math.floor(Date.now() / 1000) + ttlSeconds, nonce: randomToken(12) };
  const encoded = b64url(JSON.stringify(payload));
  const signature = createHmac('sha256', secret).update(encoded).digest('base64url');
  return `${encoded}.${signature}`;
}

export function verifySession(token: string | undefined, scope: Claims['scope']) {
  if (!token) return null;
  const [encoded, signature] = token.split('.');
  const secret = process.env.SESSION_HMAC_SECRET;
  if (!encoded || !signature || !secret) return null;
  const actual = createHmac('sha256', secret).update(encoded).digest('base64url');
  if (actual.length !== signature.length || !timingSafeEqual(Buffer.from(actual), Buffer.from(signature))) return null;
  try {
    const claims = JSON.parse(Buffer.from(encoded, 'base64url').toString()) as Claims;
    return claims.scope === scope && claims.exp > Date.now() / 1000 ? claims : null;
  } catch { return null; }
}
