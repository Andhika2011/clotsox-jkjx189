-- Run in Supabase SQL Editor. The API uses the server-only secret key.
create table if not exists public.cltx_kv_store (
  key text primary key check (char_length(key) between 1 and 240),
  value text not null,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists cltx_kv_store_expiry_idx on public.cltx_kv_store (expires_at);
alter table public.cltx_kv_store enable row level security;
revoke all on table public.cltx_kv_store from anon, authenticated;
grant all on table public.cltx_kv_store to service_role;
create or replace function public.cltx_increment_rate_limit(p_key text, p_window_seconds integer)
returns integer language plpgsql security definer set search_path = public as $$
declare current_count integer;
begin
  insert into public.cltx_kv_store(key, value, expires_at) values ('rate:' || p_key, '1', now() + make_interval(secs => p_window_seconds))
  on conflict (key) do update set
    value = case when cltx_kv_store.expires_at is null or cltx_kv_store.expires_at <= now() then '1' else (cltx_kv_store.value::integer + 1)::text end,
    expires_at = case when cltx_kv_store.expires_at is null or cltx_kv_store.expires_at <= now() then now() + make_interval(secs => p_window_seconds) else cltx_kv_store.expires_at end,
    updated_at = now()
  returning value::integer into current_count;
  return current_count;
end;
$$;
revoke all on function public.cltx_increment_rate_limit(text, integer) from public, anon, authenticated;
grant execute on function public.cltx_increment_rate_limit(text, integer) to service_role;
