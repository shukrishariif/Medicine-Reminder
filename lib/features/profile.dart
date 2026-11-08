import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/premium.dart';
import '../services/app_controller.dart';
import 'widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageBody(
      children: [
        LocalizedText(
          tr(context, 'Profile'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: lavender,
                  child: Text(
                    app.name.isEmpty
                        ? 'D'
                        : app.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: careTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name.isEmpty ? tr(context, 'Friend') : app.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      LocalizedText(
                        app.cloud?.auth.currentUser?.email ??
                            tr(context, 'Saved on this device'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const CareIcon(Icons.person_outline),
          title: LocalizedText(tr(context, 'Personal information')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final value = await textDialog(context, 'Your name', app.name);
            if (value != null && value.trim().isNotEmpty) {
              await app.setSettings({'name': value.trim()});
            }
          },
        ),
        ListTile(
          leading: const CareIcon(Icons.medication_outlined),
          title: LocalizedText(tr(context, 'Medicines')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/medicines'),
        ),
        ListTile(
          leading: const CareIcon(Icons.language),
          title: LocalizedText(tr(context, 'Language')),
          trailing: DropdownButton<String>(
            value: app.language,
            items: const [
              DropdownMenuItem(value: 'en', child: LocalizedText('English')),
              DropdownMenuItem(value: 'so', child: LocalizedText('Soomaali')),
              DropdownMenuItem(value: 'ar', child: LocalizedText('العربية')),
            ],
            onChanged: (v) => app.setSettings({'language': v}),
          ),
        ),
        SwitchListTile(
          secondary: const CareIcon(Icons.dark_mode_outlined),
          title: LocalizedText(tr(context, 'Dark mode')),
          value: app.settings['dark'] == true,
          onChanged: (v) => app.setSettings({'dark': v}),
        ),
        ListTile(
          leading: const CareIcon(Icons.notifications_outlined),
          title: LocalizedText(tr(context, 'Alarm settings')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings'),
        ),
        ListTile(
          leading: const CareIcon(Icons.lock_outline),
          title: LocalizedText(tr(context, 'Privacy')),
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: LocalizedText(tr(ctx, 'Privacy')),
              content: const SingleChildScrollView(
                child: LocalizedText(
                  'Medicine data is stored in this app’s private device storage. Cloud synchronization is optional and limited to your signed-in account. Authentication tokens use secure platform storage. Local medicine data is not additionally encrypted by Daryeel; use a device lock and device encryption.\n\nExports include sensitive medication data. Only copy or share them with people you trust. No advertising or analytics SDK is included.',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const LocalizedText('OK'),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
        ListTile(
          leading: const CareIcon(Icons.cloud_sync_outlined),
          title: LocalizedText(tr(context, 'Backup and restore')),
          subtitle: LocalizedText(
            app.syncMessage ??
                (app.signedIn
                    ? 'Sync your account'
                    : 'Sign in for optional cloud backup'),
          ),
          trailing: app.syncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: () => app.signedIn ? app.run(app.sync) : context.push('/auth'),
        ),
        if (app.signedIn)
          ListTile(
            leading: const CareIcon(Icons.move_to_inbox_outlined),
            title: const LocalizedText('Import guest medicines'),
            subtitle: const LocalizedText(
              'Move guest records into this account',
            ),
            onTap: () async {
              if (await confirm(
                context,
                'Import guest medicines',
                'Move locally saved guest medicines and dose history into this signed-in account?',
              )) {
                await app.importGuest();
              }
            },
          ),
        ListTile(
          leading: const CareIcon(Icons.ios_share),
          title: LocalizedText(tr(context, 'Export data')),
          onTap: () async {
            final text = await app.exportBackup();
            if (!context.mounted) {
              return;
            }
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: LocalizedText(tr(ctx, 'Export data')),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(child: SelectableText(text)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const LocalizedText('Close'),
                  ),
                  CareButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const LocalizedText('Copy backup JSON'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const CareIcon(Icons.restore),
          title: const LocalizedText('Restore local backup'),
          onTap: () async {
            final text = await textDialog(
              context,
              'Paste backup JSON',
              '',
              multiline: true,
            );
            if (text != null &&
                text.trim().isNotEmpty &&
                context.mounted &&
                await confirm(
                  context,
                  'Restore backup',
                  'Merge this backup into this account? Matching record IDs will be replaced.',
                )) {
              await app.restoreBackup(text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: LocalizedText(app.error ?? 'Backup restored'),
                  ),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const CareIcon(Icons.help_outline),
          title: LocalizedText(tr(context, 'Help and about')),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Daryeel',
            applicationVersion: '2.0.0',
            applicationIcon: const Icon(
              Icons.spa_outlined,
              color: purple,
              size: 48,
            ),
            children: [
              const LocalizedText(
                'A little care, every day.\n\nAdd a medicine using the + button. Use the scheduled reminder to record, skip, or snooze a dose. History reflects your records; it is not a clinical assessment.\n\nReminder delivery can be affected by Android permissions, force-stop, battery restrictions, and Do Not Disturb. Open Daryeel at least monthly to refresh the next 30 days of notifications.\n\nFor medication questions, contact your healthcare professional.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!app.signedIn)
          CareButton(
            onPressed: () => context.push('/auth'),
            child: LocalizedText(tr(context, 'Sign in')),
          )
        else ...[
          OutlinedButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              await app.run(() async {
                await app.cloud!.auth.signOut();
              });
              if (!app.signedIn) router.go('/auth');
            },
            child: LocalizedText(tr(context, 'Sign out')),
          ),
          TextButton(
            onPressed: () async {
              if (await confirm(
                context,
                'Delete account',
                'Permanently delete your account and its cloud medication records? This cannot be undone.',
              )) {
                await app.deleteAccount();
              }
            },
            child: LocalizedText(
              'Delete account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        TextButton(
          onPressed: () async {
            if (await confirm(
              context,
              'Erase local data',
              'Erase this account’s data on this device? Cloud data will remain and can be restored by synchronization.',
            )) {
              await app.run(() async {
                await app.repository.clearOwner(app.owner);
                await app.reload();
                await app.refreshReminders();
              });
            }
          },
          child: const LocalizedText('Erase local data'),
        ),
      ],
    );
  }
}

Future<String?> textDialog(
  BuildContext context,
  String title,
  String initial, {
  bool multiline = false,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: LocalizedText(tr(ctx, title)),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: multiline ? 5 : 1,
        maxLines: multiline ? 10 : 1,
        maxLength: multiline ? null : 100,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: LocalizedText(tr(ctx, 'Cancel')),
        ),
        CareButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: LocalizedText(tr(ctx, 'Save')),
        ),
      ],
    ),
  );
  // Dialog reverse transition may still reference its controller.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return result;
}

class AlarmSettingsScreen extends ConsumerWidget {
  const AlarmSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(title: LocalizedText(tr(context, 'Alarm settings'))),
      body: PageBody(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: LocalizedText(tr(context, 'Enable reminders')),
            value: app.settings['notifications'] != false,
            onChanged: (v) => app.setSettings({'notifications': v}),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const LocalizedText('Hide medicine details on lock screen'),
            value: app.settings['privateNotifications'] != false,
            onChanged: (v) => app.setSettings({'privateNotifications': v}),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const LocalizedText('Full-screen reminders'),
            subtitle: const LocalizedText(
              'Only when allowed by Android and device policy',
            ),
            value: app.settings['fullScreen'] == true,
            onChanged: !app.reminders.supported
                ? null
                : (v) async {
                    await app.run(() async {
                      if (v) {
                        await app.reminders.requestPermissions(
                          fullScreen: true,
                        );
                      }
                    });
                    await app.setSettings({'fullScreen': v});
                  },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    app.reminders.supported
                        ? '${tr(context, 'Notification permission')}: ${tr(context, app.reminders.allowed ? 'allowed' : 'off')}\n${tr(context, 'Precise alarm permission')}: ${tr(context, app.reminders.exact ? 'allowed' : 'off')}'
                        : 'Scheduled device reminders require Android.',
                    style: const TextStyle(height: 1.8),
                  ),
                  const SizedBox(height: 12),
                  const LocalizedText(
                    'When precise alarms are unavailable, reminders use approximate delivery. Android may delay reminders in battery-saving modes. Force-stopping the app prevents reminders until you reopen it. Do Not Disturb can silence reminders.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          CareButton(
            onPressed: !app.reminders.supported
                ? null
                : () => app.run(() async {
                    await app.reminders.requestPermissions(precise: true);
                    await app.refreshReminders();
                  }),
            child: LocalizedText(tr(context, 'Open settings')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: !app.reminders.allowed
                ? null
                : () async {
                    await app.run(
                      () => app.reminders.test(language: app.language),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: LocalizedText(
                            app.error ??
                                'Test reminder scheduled for 15 seconds from now.',
                          ),
                        ),
                      );
                    }
                  },
            child: LocalizedText(tr(context, 'Test reminder')),
          ),
          const SizedBox(height: 24),
          const LocalizedText(
            'Upcoming reminders are prepared for the next 30 days, up to 450 notifications including repeats. Open Daryeel regularly to refresh this window. Device time-zone changes are applied when you reopen the app.',
          ),
          if (app.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: LocalizedText(app.error!),
            ),
        ],
      ),
    );
  }
}
