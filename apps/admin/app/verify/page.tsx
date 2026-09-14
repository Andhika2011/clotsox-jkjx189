'use client';
import { FormEvent, useState } from 'react';
import { Brand } from '../../components/brand';

export default function VerifyPage() {
  const [error, setError] = useState(''); const [busy, setBusy] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setBusy(true); setError(''); const pin = new FormData(event.currentTarget).get('pin'); try { const response = await fetch('/api/admin/verify-pin', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ pin }) }); if (!response.ok) throw new Error(); location.assign('/dashboard'); } catch { setError('Verifikasi gagal atau sesi telah berakhir.'); } finally { setBusy(false); } }
  return <main className="auth-shell"><section className="auth-card"><Brand /><p className="eyebrow">SECOND FACTOR</p><h1>Konfirmasi identitas.</h1><p className="subtle">Masukkan PIN enam digit yang dikonfigurasi di server. Sesi ini akan berakhir otomatis.</p><form onSubmit={submit}><label>PIN VERIFIKASI<input name="pin" inputMode="numeric" pattern="[0-9]{6}" maxLength={6} autoComplete="one-time-code" required placeholder="••••••" /></label>{error && <p className="form-error">{error}</p>}<button disabled={busy} className="primary" type="submit">{busy ? 'MEMVERIFIKASI…' : 'VERIFIKASI'}</button></form><p className="security-line">PIN contoh 010511 wajib diganti dengan TOTP/WebAuthn sebelum produksi.</p></section></main>;
}
