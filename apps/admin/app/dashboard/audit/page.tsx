'use client';
import { useEffect, useState } from 'react';
import { Sidebar } from '../../../components/sidebar';

type AuditEntry = {
  at: string;
  actor: string;
  action: string;
  licenseId?: string;
  tier?: string;
};

const actionLabel: Record<string, string> = {
  'license.created': '🔑 Lisensi dibuat',
  'license.revoked': '🚫 Lisensi direvoke',
};

function fmt(iso: string) {
  return new Date(iso).toLocaleString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
  });
}

export default function AuditPage() {
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetch('/api/audit', { credentials: 'include' })
      .then(r => r.ok ? r.json() : Promise.reject())
      .then(data => setEntries(data.entries))
      .catch(() => setError('Gagal memuat audit log. Pastikan sesi masih aktif.'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <main className="dashboard">
      <Sidebar />
      <section className="content">
        <div className="page-header">
          <p className="eyebrow">AUDIT LOG</p>
          <h1>Riwayat Aktivitas</h1>
          <p>Semua aksi admin yang tercatat oleh sistem. Disimpan selama 90 hari.</p>
        </div>

        {error && <p className="form-error">{error}</p>}

        {loading ? (
          <p className="empty-state">Memuat data…</p>
        ) : entries.length === 0 ? (
          <div className="empty-state">Belum ada aktivitas yang tercatat.</div>
        ) : (
          <div className="panel">
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>WAKTU</th>
                    <th>AKSI</th>
                    <th>ACTOR</th>
                    <th>LICENSE ID</th>
                    <th>TIER</th>
                  </tr>
                </thead>
                <tbody>
                  {entries.map((entry, i) => (
                    <tr key={i}>
                      <td style={{ whiteSpace: 'nowrap', color: 'var(--muted)', fontSize: '12px' }}>
                        {fmt(entry.at)}
                      </td>
                      <td>{actionLabel[entry.action] ?? entry.action}</td>
                      <td style={{ color: 'var(--muted)' }}>{entry.actor}</td>
                      <td>{entry.licenseId ? <code>{entry.licenseId}</code> : '—'}</td>
                      <td>{entry.tier ?? '—'}</td>
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
