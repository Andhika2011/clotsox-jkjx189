'use client';
import { useEffect, useState } from 'react';
import { Sidebar } from '../../../components/sidebar';

type License = {
  id: string;
  tier: string;
  durationDays: number;
  createdAt: string;
  expiresAt: string;
  revokedAt: string | null;
  bound: boolean;
  note: string | null;
  status: 'active' | 'expired' | 'revoked';
};

const tierLabel: Record<string, string> = {
  t1: 'Core', t2: 'Balance', t3: 'Performance', t4: 'Turbo', t5: 'Apex',
};

function fmt(iso: string) {
  return new Date(iso).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function LicensesPage() {
  const [licenses, setLicenses] = useState<License[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [revoking, setRevoking] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/licenses');
      if (!res.ok) throw new Error();
      const data = await res.json();
      setLicenses(data.licenses);
    } catch {
      setError('Gagal memuat data lisensi. Pastikan sesi masih aktif.');
    } finally {
      setLoading(false);
    }
  }

  async function revoke(id: string) {
    if (!confirm(`Revoke lisensi ${id}? Tindakan ini tidak dapat dibatalkan.`)) return;
    setRevoking(id);
    try {
      const res = await fetch('/api/licenses/revoke', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id }),
      });
      if (!res.ok) throw new Error();
      await load();
    } catch {
      alert('Gagal merevoke lisensi. Coba lagi.');
    } finally {
      setRevoking(null);
    }
  }

  useEffect(() => { load(); }, []);

  return (
    <main className="dashboard">
      <Sidebar />
      <section className="content">
        <div className="page-header">
          <p className="eyebrow">LICENSES</p>
          <h1>Daftar Lisensi</h1>
          <p>Semua lisensi yang pernah diterbitkan. Klik Revoke untuk menonaktifkan lisensi aktif.</p>
        </div>

        {error && <p className="form-error">{error}</p>}

        {loading ? (
          <p className="empty-state">Memuat data…</p>
        ) : licenses.length === 0 ? (
          <div className="empty-state">Belum ada lisensi yang diterbitkan.</div>
        ) : (
          <div className="panel">
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>TIER</th>
                    <th>DURASI</th>
                    <th>DIBUAT</th>
                    <th>KADALUARSA</th>
                    <th>DEVICE</th>
                    <th>CATATAN</th>
                    <th>STATUS</th>
                    <th>AKSI</th>
                  </tr>
                </thead>
                <tbody>
                  {licenses.map(lic => (
                    <tr key={lic.id}>
                      <td><code>{lic.id}</code></td>
                      <td>{tierLabel[lic.tier] ?? lic.tier}</td>
                      <td>{lic.durationDays}h</td>
                      <td>{fmt(lic.createdAt)}</td>
                      <td>{fmt(lic.expiresAt)}</td>
                      <td>{lic.bound ? '✓ Terikat' : '— Bebas'}</td>
                      <td style={{ color: 'var(--muted)' }}>{lic.note ?? '—'}</td>
                      <td>
                        <span className={`badge badge-${lic.status}`}>
                          {lic.status.toUpperCase()}
                        </span>
                      </td>
                      <td>
                        {lic.status === 'active' && (
                          <button
                            className="btn-sm btn-danger"
                            disabled={revoking === lic.id}
                            onClick={() => revoke(lic.id)}
                          >
                            {revoking === lic.id ? '…' : 'REVOKE'}
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </section>
    </main>
  );
}
