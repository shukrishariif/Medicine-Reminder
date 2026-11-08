-- Public profile data is owned by the authenticated user. Passwords and sessions
-- remain managed exclusively by Supabase Auth, never in this table.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '' check (length(full_name) <= 200),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
revoke all on public.profiles from anon;
grant select on public.profiles to authenticated;
create policy "Read own profile" on public.profiles for select to authenticated
using ((select auth.uid()) = id);

create or replace function public.sync_auth_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, full_name, updated_at)
  values (new.id, left(coalesce(new.raw_user_meta_data->>'full_name', ''), 200), now())
  on conflict (id) do update set full_name = excluded.full_name, updated_at = excluded.updated_at;
  return new;
end;
$$;
revoke all on function public.sync_auth_profile() from public, anon, authenticated;
drop trigger if exists daryeel_auth_profile on auth.users;
create trigger daryeel_auth_profile after insert or update of raw_user_meta_data on auth.users
for each row execute function public.sync_auth_profile();
insert into public.profiles(id, full_name)
select id, left(coalesce(raw_user_meta_data->>'full_name', ''), 200) from auth.users
on conflict (id) do nothing;
