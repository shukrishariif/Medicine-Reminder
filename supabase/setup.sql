-- Run in the SQL Editor of YOUR Daryeel project.
-- Existing medicine rows are preserved. Safe to rerun these named policies.
begin;

-- 001_initial.sql
-- Daryeel v1: per-record offline synchronization with atomic conflict resolution.
-- The envelope stores typed medicine, schedule, dose and tombstone data.
create table if not exists public.health_records (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('medicine', 'dose')),
  id text not null check (length(id) between 1 and 160),
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  deleted boolean not null default false,
  modified timestamptz not null,
  primary key (user_id, kind, id),
  check (data->>'id' = id)
);
alter table public.health_records enable row level security;
drop policy if exists "Read own records" on public.health_records;
create policy "Read own records" on public.health_records for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Insert own records" on public.health_records;
create policy "Insert own records" on public.health_records for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Update own records" on public.health_records;
create policy "Update own records" on public.health_records for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "Delete own records" on public.health_records;
create policy "Delete own records" on public.health_records for delete to authenticated using ((select auth.uid()) = user_id);
revoke all on public.health_records from anon;
grant select, insert, update, delete on public.health_records to authenticated;

create or replace function public.sync_records(changes jsonb)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare item jsonb; uid uuid := auth.uid();
begin
  if uid is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(changes) <> 'array' or jsonb_array_length(changes) > 20000 then raise exception 'Invalid changes'; end if;
  for item in select value from jsonb_array_elements(changes) loop
    if item->>'kind' = 'medicine' and (
      coalesce(length(item->'data'->>'name'), 0) not between 1 and 100
      or jsonb_typeof(item->'data'->'times') is distinct from 'array'
      or jsonb_typeof(item->'data'->'weekdays') is distinct from 'array'
    ) then raise exception 'Invalid medicine'; end if;
    if item->>'kind' = 'dose' and coalesce(item->'data'->>'status', '') not in ('pending','due','taken','skipped','missed','snoozed') then raise exception 'Invalid dose'; end if;
    if (item->>'modified')::timestamptz > now() + interval '5 minutes' then raise exception 'Device clock is ahead'; end if;
    insert into public.health_records(user_id, kind, id, data, deleted, modified)
      values(uid, item->>'kind', item->>'id', item->'data', coalesce((item->>'deleted')::boolean, false), (item->>'modified')::timestamptz)
      on conflict (user_id, kind, id) do update set data = excluded.data, deleted = excluded.deleted, modified = excluded.modified
      where excluded.modified > public.health_records.modified;
  end loop;
  return coalesce((select jsonb_agg(jsonb_build_object('kind', kind, 'id', id, 'data', data, 'deleted', deleted, 'modified', modified)) from public.health_records where user_id = uid), '[]'::jsonb);
end; $$;
revoke all on function public.sync_records(jsonb) from public, anon;
grant execute on function public.sync_records(jsonb) to authenticated;

create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  delete from auth.users where id = auth.uid();
end; $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;


-- 002_profiles.sql
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
drop policy if exists "Read own profile" on public.profiles;
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

commit;
