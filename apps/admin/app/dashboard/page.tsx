'use client';
import { FormEvent, useState } from 'react';
import { Sidebar } from '../../components/sidebar';

const tiers = [
  { value: 30, pct: 30, label: 'Core', note: '3 modules' },
  { value: 45, pct: 45, label: 'Balance', note: '4 modules' },
  { value: 60, pct: 60, label: 'Performance', note: '5 modules' },
  { value: 76, pct: 76, label: 'Turbo', note: '6 modules' },
  { value: 92, pct: 92, label: 'Apex', note: '7 modules' },
];
type CreatedKey = { key: string; id: string; tierLabel: string; createdAt: string };

export default function Dashboard() {
  const [created, setCreated] = useState<CreatedKey | null>(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function createKey(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    const form = new FormData(event.currentTarget);
    try {
      const response = await fetch('/api/keys/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          tier: Number(form.get('tier')),
          prefix: form.get('prefix'),
          note: form.get('note'),
        }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error);
      setCreated(data);
    } catch {
      setError('Kunci gagal dibuat. Pastikan sesi dan storage produksi tersedia.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="dashboard">
      <Sidebar />
      <section className="content">
        <header>
          <div>
            <p className="eyebrow">LICENSE CONTROL</p>
            <h1>Selamat datang, Operator.</h1>
            <p className="subtle">Buat key sementara dengan akses modul yang terukur.</p>
          </div>
          <button className="outline" onClick={() => location.assign('/login')}>Keluar</button>
        </header>

        <section className="stats">
          <Stat label="Tier tersedia" value="05" help="30% — 92%" />
          <Stat label="Module policy" value="07" help="Semua dapat direview" />
          <Stat label="Security" value="2FA" help="Sesi singkat aktif" />
        </section>

        <section className="workspace">
          <div className="panel create-panel">
            <p className="eyebrow">ISSUE LICENSE</p>
            <h2>Generate access key</h2>
            <p className="subtle">Key hanya diperlihatkan sekali. Setelah itu server menyimpan hash, bukan key mentah.</p>
            <form onSubmit={createKey}>
              <label>PERFORMANCE TIER
                <select name="tier" defaultValue="60">
                  {tiers.map(t => (
                    <option key={t.value} value={t.value}>{t.pct}% — {t.label} · {t.note}</option>
                  ))}
                </select>
              </label>
              <label>PREFIX KEY <span>contoh: TAMA2026 → TAMA2026-CLTSX-NNN</span>
                <input
                  name="prefix"
                  maxLength={24}
                  required
                  placeholder="NAMA atau KODE (huruf besar & angka)"
                  style={{ textTransform: 'uppercase' }}
                  pattern="[A-Za-z0-9_]{3,24}"
                  title="3–24 karakter huruf, angka, atau underscore"
                  onChange={e => { e.target.value = e.target.value.toUpperCase().replace(/[^A-Z0-9_]/g, ''); }}
                />
              </label>
              <label>CATATAN INTERNAL <span>opsional</span>
                <input name="note" maxLength={140} placeholder="Contoh: pelanggan / invoice" />
              </label>
              {error && <p className="form-error">{error}</p>}
              <button className="primary" type="submit" disabled={busy}>
                {busy ? 'MEMBUAT…' : 'GENERATE KEY'}
              </button>
            </form>
          </div>

          <div className="panel tier-panel">
            <p className="eyebrow">ACCESS MATRIX</p>
            <h2>Tier & ruang lingkup</h2>
            <div className="tier-list">
              {tiers.map(t => (
                <div className="tier-row" key={t.value}>
                  <b>{t.pct}%</b>
                  <span>{t.label}</span>
                  <small>{t.note}</small>
                </div>
              ))}
            </div>
            <p className="policy">Tidak ada tier yang dapat mengubah file game, anti-cheat, atau mekanik permainan.</p>
          </div>
        </section>

        {created && (
          <section className="key-result">
            <div>
              <p className="eyebrow">KEY CREATED · {created.tierLabel.toUpperCase()}</p>
              <code>{created.key}</code>
              <p>Lisensi permanen — aktif hingga direvoke. Salin sekarang; key ini tidak dapat dipulihkan.</p>
            </div>
            <button className="copy" onClick={() => navigator.clipboard.writeText(created.key)}>SALIN KEY</button>
          </section>
        )}
      </section>
    </main>
  );
}

function Stat({ label, value, help }: { label: string; value: string; help: string }) {
  return (
    <article className="stat">
      <p>{label}</p>
      <strong>{value}</strong>
      <small>{help}</small>
    </article>
  );
}
