# Device and backend QA

Do not mark an item tested without recording device/OS and outcome.

## Android
- Fresh install: complete onboarding, add a real test entry, grant notification permission.
- Schedule a reminder a few minutes ahead; verify foreground, background and app-swiped-away behavior separately.
- Open the notification and record Taken. Check Home, Schedule, History and pending reminders.
- Snooze for each supported interval. Confirm original/repeat alerts are canceled and only the snoozed reminder arrives.
- Edit times, pause, archive, delete; old reminders must not arrive.
- Deny notifications/exact alarms/full-screen access; verify truthful permission UI and inexact fallback.
- Test notification visibility with private details enabled and disabled.
- Reboot and verify pending alarms; force-stop and verify the app explains restrictions.
- Change timezone/DST, reopen, inspect rescheduled wall-clock times. Without reopening, timezone recalculation is not implemented.
- Test battery saver, Do Not Disturb and vendor battery policies on a physical phone.
- Verify date limits, multiple weekday times, repeats and 450-notification horizon.
- Test large text, TalkBack, dark mode and Arabic RTL across the form and navigation.

## Supabase staging project
- Apply migration; authenticate users A and B.
- Verify anon access is rejected and B cannot select/insert/update/delete A's records.
- Verify RPCs without auth fail and account deletion affects only the caller.
- Sign up, confirm email, sign in, reset password through app deep link.
- Create records offline, reconnect, sync; compare second-device results.
- Concurrent edits: newer timestamp wins, equal timestamps retain server, tombstones do not resurrect.
- Guest migration is explicit; sign-out must not display the previous user's medication partition.
- Delete account; verify cascade removal and local records/session cleanup.
- Invalid JSON, invalid IDs, future device clocks and oversized requests must fail without partial writes.

## Before public release
- Replace starter package identifier and debug release signing.
- Have the translated Somali/Arabic interface reviewed by native speakers and verify system permission prompts in each device language.
- Add background reminder replenishment and immediate timezone-change rescheduling for unattended long-term use.
- Evaluate encryption at rest, privacy policy, backup access and platform/store notification eligibility.
- Add production integration tests against Supabase and physical devices.
