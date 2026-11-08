-- Run this read-only query in Supabase SQL Editor and copy the single JSON result.
select jsonb_pretty(jsonb_build_object(
  'tables', (select jsonb_agg(jsonb_build_object('name', c.relname, 'rls_enabled', c.relrowsecurity))
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname in ('health_records', 'profiles')),
  'policies', (select jsonb_agg(jsonb_build_object('table', tablename, 'name', policyname, 'roles', roles, 'command', cmd, 'using', qual, 'check', with_check))
    from pg_policies where schemaname = 'public' and tablename in ('health_records', 'profiles')),
  'functions', (select jsonb_agg(jsonb_build_object('name', p.proname, 'security_definer', p.prosecdef,
      'anon_execute', has_function_privilege('anon', p.oid, 'execute'),
      'authenticated_execute', has_function_privilege('authenticated', p.oid, 'execute')))
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname in ('sync_records', 'delete_my_account', 'sync_auth_profile')),
  'profile_trigger', (select jsonb_agg(jsonb_build_object('name', t.tgname, 'enabled', t.tgenabled, 'definition', pg_get_triggerdef(t.oid)))
    from pg_trigger t where t.tgrelid = 'auth.users'::regclass and t.tgname = 'daryeel_auth_profile' and not t.tgisinternal)
)) as verification;
