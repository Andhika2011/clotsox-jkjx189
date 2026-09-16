'use client';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/dashboard',          label: 'Overview',      icon: '⊞' },
  { href: '/dashboard/licenses', label: 'Licenses',      icon: '🔑' },
  { href: '/dashboard/audit',    label: 'Audit log',     icon: '📋' },
  { href: '/dashboard/policy',   label: 'System policy', icon: '🛡' },
];

export function Sidebar() {
  const pathname = usePathname();
  return (
    <aside>
      {/* Brand */}
      <div style={{ padding: '4px 12px 0', marginBottom: '4px' }}>
        <span style={{ fontSize: '16px', fontWeight: 800, letterSpacing: '-0.3px', color: 'var(--text)' }}>
          Clotso<span style={{ color: 'var(--accent)' }}>X</span>
        </span>
        <div style={{ fontSize: '11px', color: 'var(--muted)', marginTop: '2px', fontWeight: 500 }}>
          Control Plane
        </div>
      </div>

      {/* Nav */}
      <nav>
        {navItems.map(item => (
          <a
            key={item.href}
            href={item.href}
            className={pathname === item.href ? 'active' : undefined}
            style={{ display: 'flex', alignItems: 'center', gap: '9px' }}
          >
            <span style={{ fontSize: '14px', lineHeight: 1, opacity: pathname === item.href ? 1 : 0.6 }}>
              {item.icon}
            </span>
            {item.label}
          </a>
        ))}
      </nav>

      {/* Session note */}
      <div className="session-note">
        <span className="dot" />
        <span style={{ fontWeight: 600, color: 'var(--text)', fontSize: '12px' }}>Secure session</span>
        <br />
        <small>Auto-expire in 15 minutes</small>
      </div>
    </aside>
  );
}
