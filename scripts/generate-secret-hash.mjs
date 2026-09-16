import { randomBytes, scrypt } from 'node:crypto';
import { promisify } from 'node:util';

const value = process.env.ADMIN_VALUE;
if (!value || value.length < 6) {
  console.error('Set ADMIN_VALUE first; it is never written to disk.');
  process.exit(1);
}

// Konsisten dengan verifySecret di server/_lib/crypto.ts:
// scrypt(`${value}:${pepper}`, salt, 64) — pepper='' untuk password/pin admin
const pepper = '';
const salt = randomBytes(16).toString('hex');
const derived = await promisify(scrypt)(`${value}:${pepper}`, salt, 64);
console.log(`scrypt$${salt}$${derived.toString('hex')}`);
