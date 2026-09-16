'use client';
import { FormEvent, useState } from 'react';

export default function VerifyPage() {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    const pin = new FormData(event.currentTarget).get('pin');
    try {
      const response = await fetch('/api/admin/verify-pin', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin }),
      });
      if (!response.ok) throw new Error();
      location.assign('/dashboard');
    } catch {
      setError('Verifikasi gagal atau sesi telah berakhir.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="auth-split">
      {/* Kiri */}
      <div className="auth-left">
        <div className="auth-left-brand">
          Clotso<span>X</span>
        </div>

        <div className="auth-headline">
          <h1>Two-factor<br />verification.</h1>
          <p>Konfirmasi identitas dengan PIN yang dikonfigurasi di server untuk melanjutkan ke dashboard.</p>
        </div>

        <div className="auth-illustration">
          <div className="auth-card-mock">
            <div className="mock-label">Security · Step 2/2</div>
            <div className="mock-key" style={{ letterSpacing: '8px', fontSize: '22px' }}>
              • • • • • •
            </div>
            <span className="mock-badge">Verification required</span>
          </div>
        </div>

        <div className="auth-left-footer">
          Sesi berakhir otomatis · Audit logged
        </div>
      </div>

      {/* Kanan */}
      <div className="auth-right">
        <div className="auth-form-wrap">
          <p className="eyebrow">Second Factor</p>
          <h2>Konfirmasi identitas.</h2>
          <p>Masukkan PIN enam digit yang dikonfigurasi di server.</p>

          <form onSubmit={submit}>
            <label>
              PIN Verifikasi
              <input
                name="pin"
                inputMode="numeric"
                pattern="[0-9]{6}"
                maxLength={6}
                autoComplete="one-time-code"
                required
                placeholder="••••••"
                style={{ fontSize: '24px', letterSpacing: '8px', textAlign: 'center' }}
              />
            </label>

            {error && <p className="form-error">{error}</p>}

            <button disabled={busy} className="primary" type="submit">
              {busy ? 'Memverifikasi…' : 'Verifikasi'}
            </button>
          </form>

          <p className="security-line">PIN wajib diganti dengan TOTP sebelum produksi</p>
        </div>
      </div>
    </main>
  );
}
