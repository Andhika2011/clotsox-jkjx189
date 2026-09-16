import './styles.css';
import type { Metadata } from 'next';

export const metadata: Metadata = { title: 'Clotso-X Control', description: 'License control plane' };

export default function Layout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id">
      <head>
        <link
          rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css"
          crossOrigin="anonymous"
          referrerPolicy="no-referrer"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
