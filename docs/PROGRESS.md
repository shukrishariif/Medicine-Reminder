# Daryeel implementation and verification

## Device launch recovery — 31 October
- Fixed the invalid `/schedule` route (`GoRoute(path: '/schedule', 0)`) in the current workspace. Static analysis passes.
- Existing emulator has only 357 MB free; Android cache trimming recovered no meaningful space. No application was uninstalled and no user data was cleared during this recovery.
- Started the installed debug app with Impeller disabled and software rendering enabled, attached Flutter, and hot-restarted successfully with current Dart sources. Visually confirmed the onboarding screen; emulator remained connected and the crash log was empty during the check.
- Added workspace Flutter run arguments and an **Attach running app (no reinstall)** VS Code profile. Use that profile for this already-running app while storage remains low. Attach avoids APK installation; changes to native Android code or plugins still require a new build/install after freeing storage.

Updated: 29 October 2026.

## Premium UI refinement — 29 October
- Upgraded the existing screens with lavender/mint backgrounds, teal branding, botanical vector artwork, gradient primary actions, a circular add button, more legible medication cards and icon-backed profile controls.
- Added native Android splash branding and an immediate Flutter startup screen with skeleton placeholders while actual initialization completes; no artificial startup delay.
- Added real staggered entrances, Material-preserving press animations, animated editor/history progress, a selectable week strip, completion artwork and success feedback. Custom animations honor reduced motion and do not loop continuously.
- Kept the repository, data schema, Supabase integration, notification service and real adherence calculations intact. User-entered reminder instructions now explicitly use plain Text to avoid accidental translation of medical content.
- Fixed dropdown and section-heading overflow. Verified primary screens at 320px width with 1.6x text in English, Somali and Arabic, including dark RTL layout.
- `flutter analyze`: no issues. All 23 unit/widget tests pass, including UI creation, editing, snoozing, completion and deletion. Native delivery and live cloud limitations listed below still apply; 60 FPS has not been profiled on physical phones.
- Rendered and inspected previews for dashboard, onboarding, schedule, history, medicine editor, reminder and profile. Preview data is test-only, never inserted into user storage.
- Updated release APK built successfully (54.5 MB). Emulator installation returned `INSTALL_FAILED_INSUFFICIENT_STORAGE` with about 358 MB free, so this build was not launched on-device. Existing app/data were not removed. APK still uses the project's debug signing configuration and is not a store-ready release.

## Premium UI and localization update — 27 October
- Added layered purple wellness artwork, softer card surfaces, a rounded floating navigation bar, illustrated onboarding and refined controls in light/dark themes.
- Added finite staggered card entrances, tab fades, onboarding icon/indicator transitions, dose-status transitions and animated adherence bars. Entrance and custom transition motion honors reduced-motion settings.
- Connected app-owned text to locale-aware widgets, including onboarding, settings/help/privacy, forms, validation, confirmations, backup messages, account messages and notifications. User-entered names, dosages and instructions remain unchanged.
- Added Somali weekday/month formatting and Material date/time picker, editing and accessibility labels. Arabic uses Flutter's localized controls and RTL layout.
- Added translation catalog coverage, multilingual form/calendar flows and reduced-motion tests. All 20 automated tests pass; static analysis reports no issues.
- Visually inspected the populated dashboard preview after the refresh. Native-speaker review is still recommended; this is no longer an English-fallback UI for the covered app screens.


## Delivered in this phase
- Replaced Flutter counter starter with Material 3 purple/lavender UI, responsive dashboard, animated progress, four-tab navigation, three onboarding pages and guest profile setup.
- Added medicine creation/review, editing, search, details, pause/resume, archive/restore and confirmed deletion.
- Added multiple reminder times, weekday/date-range validation, deterministic dose IDs, completion timestamps, skip/snooze, history and adherence summaries.
- Added transactional offline Sembast persistence on native platforms and IndexedDB storage on web. Android production data uses application-support storage, not cache.
- Added real Android local notifications, exact/inexact permission handling, full-screen opt-in, test alert, 5/10/15-minute snooze, bounded repeat reminders, differential cancellation and reboot receivers.
- Added optional Supabase email authentication, reset deep links, secure session storage, account partitions, explicit guest migration, sync retry, timestamp conflicts, tombstones, account deletion and SQL RLS migration.
- Added dark mode, English/Somali/Arabic navigation and key actions, Arabic RTL, notification translations, privacy controls and JSON backup export/restore.
- Added setup documentation, environment example, tests and Android build configuration.

## Verification
- `flutter analyze`: clean in the final validation run.
- Unit/widget suite: 14 tests covering schedules, duplicate IDs, validation, date/year boundaries, completion, snooze, edits, cancellation through the controller, account isolation, merge conflicts, backup restore, disk reopen, onboarding, populated dashboard, narrow layout, large text and Arabic/Somali locale switching.
- Android release APK built successfully. It uses debug signing for local installation; this is not a store-ready signed release.
- Initial APK installed successfully on the Android 16 / API 36 emulator.
- Android integration run successfully reached assertions for the four-step medicine form, dose completion, pending native reminder registration and actual notification delivery after 15 seconds.
- That integration run FAILED its final persistence assertion when its test database was located in Android cache. The test now uses application-support storage to match production. Cache eviction is a suspected cause, not a confirmed diagnosis.
- Retesting on the emulator was blocked by `INSTALL_FAILED_INSUFFICIENT_STORAGE` (448 MB free); no other installed apps or their saved data were removed. The corrected full Android integration test is therefore NOT verified.
- Independent host filesystem close/reopen test passes for medicine, completion and settings persistence.
- No Supabase project was supplied, so SQL/RLS/auth/network synchronization have not been executed against a live backend.
- Background, app-swiped-away, reboot, vendor battery restrictions and physical-phone delivery have NOT been verified.

## Remaining before the full requested scope is complete
1. Configure a Supabase project and execute the staging authentication/RLS/multi-device checklist. Add production backend integration coverage.
2. Have the completed Somali/Arabic translations reviewed by native speakers. Validate platform-owned permission dialogs on phones; Android renders those using the device language.
3. Add unattended background replenishment beyond the rolling 30-day / 450-alert window and immediate timezone-change rescheduling. Current schedules refresh on app open/resume.
4. Rerun the corrected Android integration test on a device with adequate storage, then test closed/background/reboot delivery and full-screen eligibility on physical phones.
5. Sync profile/preferences across devices if desired; they currently remain device-local. Export contains medication/dose records only.
6. Add explicit notification delivery/audit records if needed; current notification center reflects scheduled unresolved doses, not a delivery log.
7. Choose production application ID, configure release signing, privacy policy and store declarations. Create and test an iOS runner before claiming iOS support.

## Continuation commands
```powershell
flutter pub get
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d emulator-5554
flutter build apk --release
# After completing env.json:
flutter run --dart-define-from-file=env.json
```
The Android integration test needs notification permission and precise alarm permission enabled. It uses an isolated QA database and synthetic medication data.

The source of requirements was the supplied pasted document plus two images; no additional detailed requirements document was available. No sample medicine records are inserted into real user storage.

Final result: all 14 unit/widget/disk tests passed, static analysis clean, final 54.2 MB APK rebuilt successfully and installed/launched on the Android 16 emulator. The full corrected integration suite remains unverified for the storage reason above.


UI update verification (27 October): 20 tests passed after the final localized-error and reduced-motion refinements; `flutter analyze` returned no issues. The dashboard was rendered and visually inspected at phone width. Platform-owned Android permission dialogs remain in the device language. Medication text entered by users is never translated automatically.

Updated UI APK: built successfully (54.4 MB), installed over the existing app and launched on emulator-5554 on 27 October 2026. Saved app data was preserved.

Launch recovery (28 October): reproduced the entire Windows emulator process exiting with `0xc0000005`, disconnecting Flutter. Host graphics alone did not resolve it. Added a VS Code Android debug profile with Flutter software rendering/Impeller disabled and a cold-boot helper using SwiftShader, Vulkan disabled, and audio disabled. Verified debug build/install, dashboard display, successful hot restart, a second pre-launch readiness check, and an empty Android crash log. This is a local emulator workaround, not proof of long-term emulator stability. No application data was wiped. Emulator SDK update could not download remote manifests; installed version remains 36.1.9.

## Reference UI update (1 November 2026)
- Main tabs now use the shared centered, circular purple-gradient add button with a white plus, accessible label, spring press feedback, and the existing medicine form route.
- Reference styling includes pastel real-data progress/next-medicine cards, interactive weekly schedules, illustrated three-page onboarding, and the dark-purple reminder with completion, snooze selection and skip confirmation.
- Final onboarding action uses a green gradient. Fixed Arabic language-label encoding and reminder date separators; verified the onboarding artwork after image decoding.
- Existing repositories, saved data, backend configuration and native reminder scheduling are preserved.
- Verification: `flutter analyze` reports no issues; all 25 tests pass, including medicine actions, primary navigation, narrow/large-text RTL layouts and reduced motion. Updated rendered previews are in this directory.
- Android release APK rebuilt at `build/app/outputs/flutter-apk/app-release.apk` (about 58.2 MiB). It retains the existing local/debug signing configuration. This update was not installed on the storage-constrained emulator; physical-device alarm/background verification and the other release requirements above remain outstanding.

## Four-step medicine setup (1 November 2026)
- Upgraded the existing editor into Medicine Information, Dosage & Timing, Additional Details, and Review & Save. The existing routes, repository, IDs, account boundaries and sync mechanism are retained.
- Added optional label strength, personal category, a bounded gallery photo, identifying color, food instructions, notes, treatment duration and a dated refill reminder. Photos are stored as bounded base64 data in the existing JSON record, not temporary file paths. Existing records default safely when optional fields are absent.
- Dosage remains user-entered text with type-specific unit prompts. No dosage or clinical instructions are generated. Tablet, capsule, syrup/liquid, injection, drops, inhaler, cream and other types are supported.
- Schedules support multiple editable times (up to 12), selected weekdays and every-N-calendar-day intervals anchored to the start date. Treatment duration calculates an inclusive end date. Validation blocks empty/duplicate schedules and invalid dates/intervals.
- Refill reminders use a user-selected date/time (not an inferred stock estimate), use the existing notification privacy/permission settings, open medicine details, and are reconciled/cancelled when removed, paused, archived or deleted.
- Values survive backward navigation and review edits. Next/Save stays visible in a persistent footer; saves are guarded against repeated taps. Motion respects reduced-motion settings. Added Somali and Arabic UI strings.
- Verification: 30 host tests pass, covering create/edit/delete, backwards edits, duplicate-save prevention, legacy compatibility, disk persistence of new metadata, calendar interval boundaries, three-language large-text layouts, and mocked Android refill scheduling/cancellation/privacy. Four screen captures are `medicine-step-1.png` through `medicine-step-4.png`.
- Native gallery interaction and actual on-device/background refill delivery have not been exercised in this update. Prior live-backend and production-release limitations above still apply.

## Medicine setup refinements (2 November 2026)
- Refined the existing four-step editor with white outlined cards, lavender icon backgrounds, gradient progress markers and responsive review summary rows.
- Preserved weekday selections while changing frequency; daily and interval schedules still save all weekdays. Clearing a duration now removes the calculated end date, while changing the start date preserves a manually selected end date.
- Validation: full 30-test suite passed; the expanded five-test medicine setup suite also passed (31 distinct tests total). Flutter analysis was clean. All four rendered setup screens were visually reviewed.
- Existing model, repository, photo storage, refill notification scheduling and cloud sync integration remain in place. Native gallery, physical-device delivery and live Supabase verification remain outstanding as noted above.
- Android APK rebuilt successfully (58.6 MB). An initial generated test-plugin registration conflict was resolved by rebuilding in isolation after analysis completed. APK remains locally signed; device installation was not performed.

## Authentication implementation (3 November 2026)
- Connected the premium Welcome, Sign Up, Login and recovery screens to the existing Supabase Auth client, with matching password validation, password visibility controls, loading guards, localized errors and reduced-motion entrance effects.
- Restored the main router wiring after the resumed verification found the older route configuration. Startup now leads to first-time onboarding, Welcome, authentication and Home. Protected routes require the loaded account session; recovery links remain in the reset flow until resolved. Logout returns to Login.
- Account switching immediately hides old records while loading the correct owner. Medication partitions remain intact. Notification reconciliation removes logged-out account reminders. Full names are account-scoped and stored in Auth metadata, with migration `002_profiles.sql` providing an owner-readable profile table.
- Existing secure session storage remains in use. No local password database, demo credentials or fake production authentication was added. Optional Google OAuth is enabled only with `GOOGLE_AUTH_ENABLED=true` after provider setup.
- Setup and staging verification instructions are in `docs/AUTH_SETUP.md`. Only `env.example.json` is present: a live Supabase URL/public key, deployed migrations and configured email delivery are still required. Live account creation, RLS, SMTP delivery, Google OAuth and physical-device secure session restoration have not been verified.
- Authentication previews are `docs/auth-welcome.png`, `auth-signup.png`, `auth-login.png` and `auth-reset.png`. Host contract tests use the real SDK with controlled HTTP responses; they do not prove live backend operation.
- Final verification on 3 November: all 40 host tests passed, Flutter analysis reported no issues, and the Android release APK built successfully (58.6 MB). This build contains no Supabase configuration and cannot sign in until rebuilt with the project settings. It retains local/debug signing and was not installed on a device.

## Supabase project connection preparation (3 November 2026)
- Created an ignored env.json with empty SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY fields. Main accepts the modern publishable-key setting and retains legacy SUPABASE_ANON_KEY compatibility. No credentials were hardcoded.
- Prepared supabase/setup.sql as a transaction containing the existing schema, RPCs and idempotently replaced named RLS policies; medicine data is preserved. supabase/verify_setup.sql provides read-only deployment checks.
- Added tool/check_supabase.py to reject missing/public-key placeholders, secret/service-role keys and incorrect hosted-project URLs; optional online checks read Auth settings and check anonymous RPC rejection without creating users or medicines. VS Code's authenticated launch validates configuration before starting the emulator.
- Medicine, dose and restore changes now queue prompt cloud sync. Each RPC pins its originating session token to prevent account changes during local reads from changing the upload owner. Existing UI and animations were not edited.
- Validation: 42 Flutter tests passed, including new prompt-sync and account-switch race tests; four Python configuration tests passed; Flutter analysis reported no issues.
- Hosted deployment is NOT complete: env.json remains empty, and the computer-use tool timed out waiting for Chrome access. No migration was executed on the user's project. Live signup/login, SMTP, real two-account RLS and physical-device alarms still require the configured project and device verification. Exact setup steps are in docs/AUTH_SETUP.md.

## Live setup verification (4 November 2026)
- The configured Supabase Auth endpoint is reachable and email authentication is enabled. The deployed sync RPC denies anonymous calls. Both health_records and profiles REST endpoints return HTTP 401 / PostgreSQL permission code 42501 to anonymous reads.
- A real signup request using the user's authorized email was accepted (HTTP 200), with email confirmation required. Delivery and confirmation are pending user verification. The temporary process exited while waiting because its stdin was closed; the test helper now requires an interactive terminal before it makes any signup request. Its generated password was held only in process memory and is unavailable; password recovery is required to establish the user's password.
- Updated verify_setup.sql to return one JSON result containing table RLS flags, owner policies, function privileges and the auth.users profile trigger. The deployed metadata result is still pending.
- Regression suite: 42 tests passed. Flutter analysis: no issues. Built the APK with env.json and successfully installed it over the existing emulator app using adb install -r. Launched with the established software-rendering flags; the Daryeel process was present and the Android crash buffer was empty.
- Computer Use timed out waiting for emulator access, so visual flow interaction was unavailable. Real authenticated medicine writes, cross-account RLS, recovery completion, native notification delivery and full account sync still await authenticated testing. The installation/launch check alone does not verify those flows.

## Supabase configuration repair (5 November 2026)

- Fixed startup reading only SUPABASE_ANON_KEY while env.json supplies SUPABASE_PUBLISHABLE_KEY. The publishable name now takes precedence, with the legacy name retained as fallback.
- All VS Code launch configurations now load env.json. README run/build commands include the compile-time configuration flag. Stop and rebuild after configuration changes.
- Flutter analysis passed and all 42 Flutter tests passed. All four Python configuration tests passed.
- Live public configuration check succeeded. Email authentication is enabled. Anonymous sync is denied; health_records and profiles anonymous reads both return HTTP 401 / 42501.
- Initialized a local Git repository. Verified env.json, build logs, Python cache and signing configuration are ignored. No remote/upload was performed.
- Deployed policy/function/trigger verification awaits the JSON result from supabase/verify_setup.sql. The public key cannot inspect the database catalogs.
- Email-link completion, live authenticated CRUD/sync, two-account isolation and actual notification delivery remain unverified. Automated contract tests are not live account tests.
- Computer-use could bind the emulator window but could not capture/activate its content. Visual UI verification remains incomplete.
- Configured universal release APK built successfully (59.8 MB). Updating the emulator failed with Android's `Requested internal only, but not enough space`; /data has 304 MB free. Android cache trimming did not reclaim space. No uninstall or app-data reset was performed.
- Smaller x86_64-only release APK also built successfully (24.6 MB) but Android rejected installation with the same insufficient internal space error. The corrected build is ready; it has not been installed or launched in this verification run. Free emulator storage before retrying. Keep existing data; do not use Wipe Data or uninstall Daryeel as a space workaround.

## Follow-up verification (5 November 2026)

- Re-ran Flutter analysis (clean), all 42 Flutter host tests (pass), and four Python configuration tests (pass).
- Rechecked live Auth settings and anonymous synchronization denial (pass).
- Emulator remains at about 304 MB free. Shared storage and temporary downloads are negligible; three Daryeel package IDs are installed and were preserved. Storage problem is not resolved.
- Added and exercised check-android-storage.ps1. It correctly blocks an installation below 700 MB free. Android launch and connected-device scripts call this guard before Flutter can attempt an uninstall fallback.
- No SQL verification JSON is visible in the conversation. Deployed table/RLS/function/trigger catalog review remains pending; successful SQL execution alone is not a verification result.
- Live email confirmation/recovery, login/logout, authenticated CRUD/sync, two-account isolation, and Android alarm delivery remain pending. Integration tests were not run on the full emulator. UI code was not changed.

## Android alarm verification (7 November 2026)

- Created a separate 12 GB AVD, Daryeel_Alarm_Test on emulator-5556, using the installed Android 36 image. It has about 11 GB free. The original emulator-5554 and its medicine data were preserved. The test emulator starts with audio disabled, so this run verifies delivery rather than audible playback.
- Fixed release-resource retention for ic_notification, which the plugin resolves by name. Test reminder now refreshes notification permission and fails when permission has been revoked instead of reporting success. Added regression coverage for permission revocation.
- Flutter analysis passed and all 42 host tests passed.
- The actual Android integration test passed in 46 seconds on emulator-5556. It exercised medicine form saving, taken-dose history, local database reopen/persistence, native scheduling and presence of the delivered notification after a 20-second wait. The test uses isolated local fixture data; it does not verify live Supabase authentication or cloud synchronization.
- The isolated test app was reinstalled by Flutter after a version-code mismatch, and its permissions were restored. This occurred on the newly created test emulator only.
- The startup script now accepts -Port, allowing the new AVD to be started using: powershell -NoProfile -ExecutionPolicy Bypass -File tool/start-android.ps1 -Avd Daryeel_Alarm_Test -Port 5556.
- Live SQL catalog review still requires the verify_setup.sql JSON result. Real account email verification/recovery, two-account isolation and authenticated cloud CRUD remain pending confirmed accounts. Physical-phone audible sound, locked-screen delivery, reboot restoration and battery-restricted delivery still require acceptance testing.
