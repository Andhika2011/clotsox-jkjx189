import './styles.css';
import type { Metadata } from 'next';

export const metadata: Metadata = { title: 'Clotso-X Control', description: 'License control plane' };
export default function Layout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="id"><body>{children}</body></html>; }
