# Authentication setup and verification

## Configure your new project here

Open **`C:\Users\REAL\Documents\Daryeel1\daryeel\env.json`**. Replace only the two empty strings:

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_YOUR_PUBLIC_KEY",
  "GOOGLE_AUTH_ENABLED": false
}
```

Get the Project URL from the project's **Connect** dialog. Get the public publishable key from **Settings > API Keys > Publishable and secret API keys**. Do not copy a secret or service-role key. Legacy `SUPABASE_ANON_KEY` remains supported for existing builds.

`env.json` is ignored by Git. A publishable key is intentionally public and is included in a compiled mobile app; account security comes from authenticated JWTs and RLS, not hiding this key. Passwords remain in Supabase Auth; mobile sessions use the existing secure storage.

In that same project's **SQL Editor**, paste the contents of **`supabase/setup.sql`** and Run. It creates the existing tables, RPCs and owner policies inside a transaction, without deleting medicine rows. Then run **`supabase/verify_setup.sql`**: both RLS flags must be true, owner policies must exist, and anonymous RPC execution must be false. These read-only checks do not replace testing two real accounts.

`health_records` stores medicine records (including schedule, reminder settings and refill dates) and dose records (taken/skipped/snoozed history), partitioned by user ID. `profiles` stores each account's name; `auth.users` is managed by Supabase Auth. No duplicate medicine tables are required.

Enable Email/Password authentication and confirmation. Add **`io.daryeel.app://login-callback/`** under **Authentication > URL Configuration > Redirect URLs**. Configure SMTP **inside Supabase**, not Flutter; the default mail service restricts recipients and is unsuitable for general signup. No email-service password belongs in env.json.

Validate without printing keys:

```powershell
python tool/check_supabase.py
python tool/check_supabase.py --online
```

In VS Code select **Daryeel - authenticated Android (env.json)** and press F5. This first validates the public configuration and then uses the existing emulator stability settings. For a physical device use `flutter run -d DEVICE_ID --dart-define-from-file=env.json`. Rebuild after changing configuration; hot reload cannot change compile-time settings.

Official references: [public API keys](https://supabase.com/docs/guides/getting-started/api-keys), [email delivery configuration](https://supabase.com/docs/guides/auth/auth-smtp).

## Required deployment configuration

1. Supply a Supabase project URL and its **public publishable/anon key** through `env.json` and `--dart-define-from-file=env.json`. Never ship a service-role key, SMTP password or database password in Flutter. The local ignored `env.json` is configured. New checkouts must copy `env.example.json` to `env.json` and fill it in.
2. Apply `supabase/migrations/001_initial.sql` and `002_profiles.sql`. The first protects health records and sync/account-deletion RPCs using auth.uid(); the second mirrors full names from Auth metadata into a profile readable only by that user. Existing auth users are backfilled.
3. Enable Email/Password Auth, email confirmation, and configure the server password policy (minimum eight characters or stronger). Supabase Auth handles password hashing, uniqueness, session rotation and expiring recovery tokens; Flutter never writes passwords into local or application database records.
4. Configure a verified SMTP sender and email templates in Supabase. Default/test sender restrictions are not a production email service. The UI only reports an accepted recovery request after the Auth API returns successfully; this is not proof of delivery. Recovery response wording never confirms that an address exists.
5. Add `io.daryeel.app://login-callback/` to the Auth redirect allowlist. Android already declares this scheme. Test confirmation and recovery links on the installed Android app. iOS has no runner yet. Web needs an HTTPS callback and browser security review before deployment.
6. Optional Google: configure the Google provider and OAuth client in Supabase, then add `"GOOGLE_AUTH_ENABLED": true` to the build configuration. Only then is the real browser-based Google action shown. No placeholder Google success is implemented.
7. Run `flutter run --dart-define-from-file=env.json`. Build with the same argument; an APK built without it cannot authenticate users.

## Navigation and saved data

Startup -> first-time onboarding -> Welcome -> Sign Up / Login -> Home. Returning users with a restored session go to Home; logged-out users see Welcome/Login. Reset links enter a guarded recovery form. Login/signup cannot bypass session verification. On logout, protected UI is removed and account-specific reminders are reconciled away; records remain partitioned on disk. Login restores that account and reschedules eligible reminders. Legacy guest records are retained and may be explicitly imported from Profile; they are never automatically assigned to a new account.

Mobile access/refresh sessions use FlutterSecureStorage. Guest access is enabled explicitly with **Continue as guest** and persists on the device. Guests can use medicine screens and local reminders, then sign in through Profile for cloud backup. Signing into an account disables automatic guest access on subsequent logout. Guest records remain available through the guest button or explicit import. Preferences such as language remain device-wide.

## Verification boundaries

Automated host tests exercise real Supabase Dart client request/response handling with isolated HTTP fixtures, form validation, confirmation-required registration, rejected credentials, session refresh, logout/account isolation, guarded recovery, language layouts and existing medicine flows. Test-only medicine UI controllers explicitly bypass authentication so domain tests remain independent; this override is not included in production code.

Live profile trigger execution, duplicate-email enforcement, RLS under two real JWTs, SMTP delivery, single-use/expired recovery links, Google provider configuration, and secure Android session restoration after process termination **must still be verified on the configured project/device**. Host HTTP fixtures do not prove those services work. The configured project accepts the public key and denies anonymous synchronization. Earlier signup and recovery requests were accepted, but email delivery and completion still require user verification. Run `supabase/verify_setup.sql` in the dashboard and provide its JSON result to verify deployed policies and the trigger.

## Configuration troubleshooting

Startup reads `SUPABASE_PUBLISHABLE_KEY`, with `SUPABASE_ANON_KEY` retained as a legacy fallback. All VS Code launch profiles now include `--dart-define-from-file=env.json`. Flutter includes these values at build time; merely editing the file or hot reloading does not update an installed app. Stop the old run and rebuild with the command in README.

## GitHub preparation

Commit source, migrations, tests and `env.example.json`. Local `env.json`, environment variants, build output, logs, Python caches and signing files are ignored. Never force-add those files. No remote repository or upload is configured automatically. Before your first push inspect `git status --short` and the staged diff; keep personal health exports and authentication links out of commits.

## Staging acceptance checklist

- Register A with confirmation enabled; verify auth.users and profiles, delivered email, confirmation deep link and successful login.
- Repeat registration for A; verify no second auth user/profile exists and confirmation/obfuscated responses are handled without a fabricated authenticated session.
- Verify incorrect passwords fail. Request recovery for existing and unknown emails: public responses must not disclose membership. Follow the real link, set a matching new password, verify the old password fails and reused/expired links fail.
- Add medicines as A, restart the app, verify secure session and schedules. Log out and confirm Login appears and A's scheduled notifications are cancelled.
- Register/log in as B; verify A's medicines/history are absent. Attempt direct health_records and sync_records requests for A with B's JWT; RLS must deny access. Sign back in as A and verify records return.
- Test offline access with a previously restored session, reconnect/sync, revoked sessions, confirmation/recovery cold starts and notification deep links while logged out.
- Review Somali and Arabic wording with native speakers; verify large text, keyboard visibility, reduced motion and screen reader labels.

## Safe Android launch

Use `powershell -NoProfile -ExecutionPolicy Bypass -File tool/run-connected.ps1` for a connected emulator. The Android VS Code profiles also check storage before installing. The check requires 700 MB free for installation staging and Android's low-storage reserve. It does not erase files. If it fails, preserve all Daryeel packages and their data; free unrelated disposable content using Android Settings or use a separate larger test device. Direct `flutter run` bypasses this storage guard and may attempt an uninstall after installation failure.
