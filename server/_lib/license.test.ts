import { describe, expect, it } from 'vitest';
import { hashSecret, verifySecret } from './crypto';
import { isTier, tierProfiles } from './license';

describe('license policy', () => {
  it('only permits the specified five tiers', () => {
    expect([30, 45, 60, 76, 92].every(isTier)).toBe(true);
    expect(isTier(75)).toBe(false);
  });
  it('unlocks no more than the permitted modules', () => {
    expect(tierProfiles[30].modules).toHaveLength(3);
    expect(tierProfiles[92].modules).toHaveLength(7);
  });
  it('does not verify an altered key', async () => {
    const hash = await hashSecret('CLTX-ABCDEF-SECRETKEY', 'test-pepper');
    await expect(verifySecret('CLTX-ABCDEF-SECRETKEY', hash, 'test-pepper')).resolves.toBe(true);
    await expect(verifySecret('CLTX-ABCDEF-OTHERKEY', hash, 'test-pepper')).resolves.toBe(false);
  });
});
