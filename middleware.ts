import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  // This is a UI gate only. API handlers independently verify the signed HMAC session.
  if (!request.cookies.get('cltx_admin')?.value) return NextResponse.redirect(new URL('/login', request.url));
  return NextResponse.next();
}

export const config = { matcher: ['/dashboard/:path*'] };
