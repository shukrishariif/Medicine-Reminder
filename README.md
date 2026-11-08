# Daryeel 2.0

An offline-first Flutter medication organizer with a purple/lavender dashboard inspired by the supplied references. Fresh installations contain no sample medication records.

The 29 October UI refresh adds mint/lavender surfaces, reusable botanical artwork, gradient press-responsive buttons, a circular add action, an animated date/progress interface, responsive medicine cards and startup skeletons. Custom motion respects reduced-motion settings. Existing medication storage, cloud integration and Android reminders are retained.

Screen previews: [Home](docs/dashboard-preview.png), [Onboarding](docs/onboarding-preview.png), [Schedule](docs/schedule-preview.png), [History](docs/history-preview.png), [Add medicine](docs/medicine-preview.png), [Reminder](docs/reminder-preview.png), [Profile](docs/profile-preview.png). These images use isolated test data.

## Run

Flutter 3.35.5 / Dart 3.9.2 were used for this implementation.

```powershell
flutter pub get
flutter run -d emulator-5554 --dart-define-from-file=env.json --no-enable-impeller --enable-software-rendering
flutter test
flutter analyze
flutter build apk --release --dart-define-from-file=env.json
```

Android is the notification target. Windows and web support the local UI/data workflows but do not schedule device reminders. An iOS runner has not yet been created or validated.

### VS Code launch on this Windows machine

Select **Daryeel - Android** in Run and Debug, then press **F5**. The pre-launch task starts `my_avd` if needed and waits for Android to boot. It uses a cold boot with Vulkan/audio disabled; Flutter uses software rendering with Impeller disabled for this emulator debug profile. The installed emulator 36.1.9 repeatedly crashed with Windows exception `0xc0000005` during ordinary GPU-rendered launches. These development settings do not change release builds or erase app data.

If an emulator was started separately and still crashes, close it and use this launch profile again. For a physical phone, use **Daryeel - selected device**. The emulator startup script accepts `-Avd` for a different virtual-device name. Updating Android Emulator through Android Studio's SDK Manager remains advisable; the automated update on 28 October could not fetch the remote package manifests.

## Required account service setup

1. Create a Supabase project.
2. Run `supabase/migrations/001_initial.sql`, then `002_profiles.sql`, in its SQL editor.
3. Enable email/password authentication. Enable email confirmation and configure SMTP for production.
4. Add `io.daryeel.app://login-callback/` to Authentication → URL configuration → redirect URLs.
5. Fill the prepared, ignored `env.json` with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Never include a service-role key.
6. Start with `flutter run --dart-define-from-file=env.json` or build with `flutter build apk --release --dart-define-from-file=env.json`.

Supabase configuration enables account sign-in and cloud backup. Choose **Continue as guest** on Welcome or Log In to open Home without credentials. Guest medicines and history are saved on the device, and guest mode survives restart. Profile offers sign-in and, after signing in, an explicit **Import guest medicines** action. See [authentication setup and verification](docs/AUTH_SETUP.md).

## Architecture

- `lib/core`: Material 3 design system and localization dictionaries.
- `lib/data`: domain models, deterministic schedule generation, transactional Sembast database (device file or IndexedDB on web).
- `lib/services`: Riverpod controller, native reminders, secure authentication token persistence.
- `lib/features`: onboarding/auth, dashboard/schedule/history, medicine editor/details, profile/settings.
- `supabase/migrations`: RLS-protected record store and synchronization/account-deletion RPCs.
- `test`: domain, persistence, sync merge and responsive widget checks.

The medicine record contains its schedule; dose records preserve the original name, dosage, scheduled timestamp and actual completion timestamp. Dose IDs derive from medicine UUID + local calendar date + wall-clock minute. Updates use the same record, preventing duplicate completions. Historical elapsed occurrences are persisted before schedule edits. Pausing/archiving removes future reminders while keeping recorded history. Deletion creates a sync tombstone.

## Synchronization

Each account has a separate local record partition. Guest-to-account migration is explicit in Profile. Signing out returns to Login and cancels account reminders. Protected routes require a session; the previous account partition is retained for the next login. Local writes do not require a network connection. Sync is queued shortly after medicine/history changes and also runs on sign-in/resume, every minute while open, and on demand in Profile. Each request retains its originating account token. Failed sync retains dirty records for retry.

The PostgreSQL RPC checks `auth.uid()` and atomically accepts only a newer modification timestamp for each record. Matching timestamps keep the server version. The client merges the result only when it is at least as new as its local record. Tombstones propagate deletions. Conflict policy is per-record last-write-wins, including dose outcomes; simultaneous conflicting edits are not merged field-by-field. Device clocks over five minutes ahead are rejected. Keep clocks synchronized. RLS is enabled on every exposed data table. A privileged account-deletion RPC deletes only `auth.uid()`; no privileged key is shipped to the app.

Language, appearance and notification preferences are device-local. Full name is stored in Supabase Auth metadata and mirrored into the account-owned profiles table; local name overrides are partitioned by account. Backup export contains medicine and dose records, not sessions or passwords. Export/restore is via explicit JSON copy/paste; the clipboard may contain health information afterward. Local medicine files rely on OS app isolation/device encryption; only session tokens use secure storage. Android OS backup is disabled.

## Reminder behavior and limits

- Multiple times, selected weekdays, date ranges, per-medicine/global enablement.
- Exact alarms when permission is granted, inexact fallback otherwise.
- Notification opens the dose screen; completion/skip and 5/10/15-minute snooze work there.
- Up to three extra reminders at 10-minute intervals; resolving a dose cancels its repeats.
- Reboot receiver restores already scheduled alarms. Device timezone is refreshed on app resume.
- Full-screen presentation is opt-in and subject to Android permission, OS policy and store eligibility; it is not guaranteed.
- Reminders are scheduled for a rolling 30-day window, capped at 450 including repeats. Open the app regularly to replenish. No unattended periodic background replenishment or timezone-change worker is implemented yet.
- Force-stop, battery restrictions, Do Not Disturb, revoked permissions and vendor policies can prevent or delay delivery.
- A dose becomes “missed” for tracking two hours after its scheduled/snoozed time. This is an app status threshold, not advice about when medicine may safely be taken.

## Release preparation

The generated release variant currently uses the starter project's debug signing configuration, suitable for local installation only. Before publication choose a permanent application ID (currently `com.example.daryeel`), configure your own release signing key outside source control, prepare privacy/store disclosures and review full-screen-intent eligibility. Do not distribute a debug-signed build as a production release.

See `docs/PROGRESS.md` for actual verification results and remaining work, and `docs/DEVICE_TESTS.md` for the device QA checklist.

## UI and language support

The October 27 refresh adds layered wellness cards, rounded navigation, illustrated onboarding and restrained entrance/status animations. Reduced-motion preferences disable custom entrance motion.

English, Somali and Arabic apply to onboarding, forms, validation, settings, dialogs, help/privacy and notification copy. Somali has custom Material date/time picker labels and calendar formatting; Arabic uses Flutter's localized controls and right-to-left layout. User-entered medicine names, dosages and instructions are intentionally preserved. Android's own permission prompts follow the phone's system language. Translation coverage and form/calendar language flows are checked in `test/localization_test.dart`.
