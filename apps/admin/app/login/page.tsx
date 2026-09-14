'use client';
import { FormEvent, useState } from 'react';
import { Brand } from '../../components/brand';

export default function LoginPage() {
  const [error, setError] = useState(''); const [busy, setBusy] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setBusy(true); setError(''); const fields = new FormData(event.currentTarget); try { const response = await fetch('/api/admin/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: fields.get('email'), password: fields.get('password') }) }); if (!response.ok) throw new Error(); location.assign('/verify'); } catch { setError('Email atau password tidak valid.'); } finally { setBusy(false); } }
  return <main className="auth-shell"><section className="auth-card"><Brand /><p className="eyebrow">ADMIN ACCESS</p><h1>Masuk ke control plane.</h1><p className="subtle">Akses operator dilindungi oleh sesi singkat dan verifikasi tahap kedua.</p><form onSubmit={submit}><label>Email<input name="email" type="email" autoComplete="username" required placeholder="admin@domain.com" /></label><label>Password<input name="password" type="password" autoComplete="current-password" required placeholder="••••••••••••" /></label>{error && <p className="form-error">{error}</p>}<button disabled={busy} className="primary" type="submit">{busy ? 'MEMERIKSA…' : 'LANJUTKAN'}</button></form><p className="security-line">◉ TLS-only · Rate limited · Audit logged</p></section></main>;
}
