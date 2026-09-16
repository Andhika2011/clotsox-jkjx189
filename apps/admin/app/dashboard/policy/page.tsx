import { Sidebar } from '../../../components/sidebar';

const policies = [
  {
    icon: 'fa-solid fa-shield-halved',
    title: 'Tidak ada modifikasi file game',
    desc: 'Clotso-X tidak mengubah, membaca, atau menyuntikkan kode ke file game, anti-cheat, rank, aim, recoil, atau mekanik permainan apapun.',
  },
  {
    icon: 'fa-solid fa-key',
    title: 'Lisensi disimpan sebagai hash',
    desc: 'Kunci lisensi disimpan sebagai hash bcrypt ber-pepper. Server tidak dapat memulihkan key mentah setelah penerbitan.',
  },
  {
    icon: 'fa-solid fa-mobile-screen',
    title: 'Binding satu perangkat',
    desc: 'Setelah aktivasi pertama, lisensi diikat ke device hash perangkat tersebut. Perpindahan perangkat memerlukan revoke dan penerbitan ulang.',
  },
  {
    icon: 'fa-solid fa-clock',
    title: 'Sesi admin singkat',
    desc: 'Sesi operator berlaku 15 menit. Setelah itu, login ulang beserta verifikasi PIN 6-digit wajib dilakukan.',
  },
  {
    icon: 'fa-solid fa-gauge',
    title: 'Rate limiting aktif',
    desc: 'Endpoint login dibatasi 5 percobaan per 15 menit per IP. Endpoint validasi lisensi dibatasi 10 per 15 menit.',
  },
  {
    icon: 'fa-solid fa-clipboard-list',
    title: 'Setiap aksi tercatat',
    desc: 'Semua penerbitan dan pencabutan lisensi dicatat di audit log dengan timestamp, actor, dan ID lisensi. Log disimpan 90 hari.',
  },
  {
    icon: 'fa-solid fa-rotate-left',
    title: 'Perubahan sistem dapat dipulihkan',
    desc: 'Semua perubahan yang diterapkan Clotso-X ke perangkat bersifat eksplisit, dapat ditinjau, dan memiliki restore point.',
  },
  {
    icon: 'fa-solid fa-lock',
    title: 'TLS-only & header keamanan',
    desc: 'Seluruh komunikasi API menggunakan HTTPS. Setiap response menyertakan Strict-Transport-Security, X-Frame-Options, dan Referrer-Policy.',
  },
];

const tiers = [
  { id: 't1', pct: 30, label: 'Core', modules: 3 },
  { id: 't2', pct: 45, label: 'Balance', modules: 4 },
  { id: 't3', pct: 60, label: 'Performance', modules: 5 },
  { id: 't4', pct: 76, label: 'Turbo', modules: 6 },
  { id: 't5', pct: 92, label: 'Apex', modules: 7 },
];

export default function PolicyPage() {
  return (
    <main className="dashboard">
      <Sidebar />
      <section className="content">
        <div className="page-header">
          <p className="eyebrow">SYSTEM POLICY</p>
          <h1>Kebijakan Sistem</h1>
          <p>Dokumen ini bersifat read-only dan mencerminkan kebijakan operasional Clotso-X yang berlaku.</p>
        </div>

        <div className="notice">
          <i className="fa-solid fa-circle-info" style={{ marginRight: '8px' }} />
          Kebijakan ini diterapkan secara teknis di level server dan tidak dapat diubah melalui dashboard.
          Untuk perubahan kebijakan, edit source code dan deploy ulang.
        </div>

        <div className="panel" style={{ marginTop: '20px' }}>
          <p className="eyebrow">KEAMANAN & PRIVASI</p>
          <h2>Prinsip Operasional</h2>
          <div className="policy-section">
            {policies.map((p, i) => (
              <div className="policy-item" key={i}>
                <span className="policy-icon">
                  <i className={p.icon} />
                </span>
                <div>
                  <b>{p.title}</b>
                  <span>{p.desc}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="panel" style={{ marginTop: '17px' }}>
          <p className="eyebrow">ACCESS MATRIX</p>
          <h2>Tier & Batas Modul</h2>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>TIER ID</th>
                  <th>PERSENTASE</th>
                  <th>LABEL</th>
                  <th>MODUL AKTIF</th>
                </tr>
              </thead>
              <tbody>
                {tiers.map(t => (
                  <tr key={t.id}>
                    <td><code>{t.id}</code></td>
                    <td style={{ color: 'var(--accent)', fontWeight: 800 }}>{t.pct}%</td>
                    <td>{t.label}</td>
                    <td>{t.modules} dari 7</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="policy" style={{ marginTop: '16px' }}>
            Tidak ada tier yang dapat mengaktifkan modifikasi file game, anti-cheat, atau mekanik permainan.
          </p>
        </div>
      </section>
    </main>
  );
}
