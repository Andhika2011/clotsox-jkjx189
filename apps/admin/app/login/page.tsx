'use client';
import { FormEvent, useState } from 'react';

export default function LoginPage() {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [showPass, setShowPass] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    const fields = new FormData(event.currentTarget);
    try {
      const response = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: fields.get('email'), password: fields.get('password') }),
      });
      if (!response.ok) throw new Error();
      location.assign('/verify');
    } catch {
      setError('Email atau password tidak valid.');
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
          <h1>Every key.<br />One workspace.</h1>
          <p>Panel operator terpusat untuk mengelola lisensi, akses modul, dan audit log platform Clotso-X.</p>
        </div>

        <div className="auth-illustration">
          <div className="auth-card-mock">
            <div className="mock-label">Clotso-X · License</div>
            <div className="mock-key">TAMA2026-CLTSX-071</div>
            <span className="mock-badge">Active · Performance</span>
          </div>
        </div>

        <div className="auth-left-footer">
          TLS-only · Rate limited · Audit logged
        </div>
      </div>

      {/* Kanan */}
      <div className="auth-right">
        <div className="auth-form-wrap">
          <p className="eyebrow">Admin Access</p>
          <h2>Welcome back.</h2>
          <p>Masuk ke control plane. Sesi dilindungi verifikasi dua tahap.</p>

          <form onSubmit={submit}>
            <label>
              Email
              <input
                name="email"
                type="email"
                autoComplete="username"
                required
                placeholder="admin@domain.com"
              />
            </label>
            <label>
              Password
              <div style={{ position: 'relative' }}>
                <input
                  name="password"
                  type={showPass ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  placeholder="••••••••••••"
                  style={{ paddingRight: '64px' }}
                />
                <button
                  type="button"
                  onClick={() => setShowPass(p => !p)}
                  style={{
                    position: 'absolute', right: '12px', top: '50%',
                    transform: 'translateY(-50%)', border: 0, background: 'none',
                    cursor: 'pointer', fontSize: '12px', fontWeight: 700,
                    color: 'var(--muted)', letterSpacing: '0.5px', padding: '4px',
                  }}
                >
                  {showPass ? 'HIDE' : 'SHOW'}
                </button>
              </div>
            </label>

            {error && <p className="form-error">{error}</p>}

            <button disabled={busy} className="primary" type="submit">
              {busy ? 'Memeriksa…' : 'Sign in'}
            </button>
          </form>

          <p className="security-line">◉ Sesi otomatis berakhir dalam 15 menit</p>
        </div>
      </div>
    </main>
  );
}
