export const tiers = [30, 45, 60, 76, 92] as const;
export type Tier = typeof tiers[number];

export type License = {
  id: string;
  secretHash: string;
  tier: Tier;
  durationDays: number;
  createdAt: string;
  expiresAt: string;
  deviceHash?: string;
  revokedAt?: string;
  note?: string;
};

export const tierProfiles: Record<Tier, { label: string; modules: string[]; description: string }> = {
  30: { label: 'Core', modules: ['graphics', 'power', 'display'], description: 'Profil ringan untuk kestabilan dasar.' },
  45: { label: 'Balance', modules: ['graphics', 'power', 'display', 'network'], description: 'Keseimbangan responsivitas dan konsumsi daya.' },
  60: { label: 'Performance', modules: ['graphics', 'power', 'display', 'network', 'memory'], description: 'Prioritas konsistensi sesi bermain.' },
  76: { label: 'Turbo', modules: ['graphics', 'power', 'display', 'network', 'memory', 'bloat'], description: 'Profil intensif dengan daftar perubahan yang dapat ditinjau.' },
  92: { label: 'Apex', modules: ['graphics', 'power', 'display', 'network', 'memory', 'bloat', 'game'], description: 'Seluruh modul perangkat yang didukung.' },
};

export function isTier(value: unknown): value is Tier { return typeof value === 'number' && tiers.includes(value as Tier); }
