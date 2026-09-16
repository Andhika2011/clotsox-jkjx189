'use client';
import { Brand } from './brand';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/dashboard', label: 'Overview' },
  { href: '/dashboard/licenses', label: 'Licenses' },
  { href: '/dashboard/audit', label: 'Audit log' },
  { href: '/dashboard/policy', label: 'System policy' },
];

export function Sidebar() {
  const pathname = usePathname();
  return (
    <aside>
      <Brand />
      <nav>
        {navItems.map(item => (
          <a
            key={item.href}
            href={item.href}
            className={pathname === item.href ? 'active' : undefined}
          >
            {item.label}
          </a>
        ))}
      </nav>
      <div className="session-note">
        <span className="dot" />Secure session<br />
        <small>Auto-expire in 15 minutes</small>
      </div>
    </aside>
  );
}
