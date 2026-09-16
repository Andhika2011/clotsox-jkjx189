'use client';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/dashboard',          label: 'Overview',      icon: 'fa-solid fa-gauge-high' },
  { href: '/dashboard/licenses', label: 'Licenses',      icon: 'fa-solid fa-key' },
  { href: '/dashboard/audit',    label: 'Audit log',     icon: 'fa-solid fa-clock-rotate-left' },
  { href: '/dashboard/policy',   label: 'System policy', icon: 'fa-solid fa-shield-halved' },
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
            style={{ display: 'flex', alignItems: 'center', gap: '10px' }}
          >
            <i
              className={item.icon}
              style={{
                width: '16px',
                textAlign: 'center',
                fontSize: '13px',
                opacity: pathname === item.href ? 1 : 0.5,
              }}
            />
            {item.label}
          </a>
        ))}
      </nav>
    </aside>
  );
}
