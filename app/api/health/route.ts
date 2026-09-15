export async function GET() {
  const configured = Boolean(process.env.SUPABASE_URL && (process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY));
  return Response.json(
    { ok: configured, service: 'clotso-x-api', storage: configured ? 'supabase-configured' : 'supabase-not-configured' },
    { status: configured ? 200 : 503, headers: { 'Cache-Control': 'no-store' } },
  );
}
